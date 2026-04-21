local M = {}

M._state = {
  active = false,
  chapter = nil,
  lesson = nil,
  challenge_idx = nil,
  buf = nil,
  win = nil,
}

function M._open_tab_if_needed()
  -- Only open a new tab if the current buffer is not already a tutor scratch buffer
  if M._state.active and M._state.buf and vim.api.nvim_buf_is_valid(M._state.buf) then
    vim.api.nvim_set_current_buf(M._state.buf)
    return
  end
  -- Check if we're in a normal file or dashboard — open a tab for isolation
  local bufname = vim.api.nvim_buf_get_name(0)
  local buftype = vim.bo.buftype
  if bufname ~= '' or buftype ~= '' then
    vim.cmd('tabnew')
  end
end

function M.command(opts)
  local arg = opts.args and opts.args:match('^%s*(%S+)')

  if arg == 'menu' then
    M._open_tab_if_needed()
    M.show_menu()
  elseif arg == 'reset' then
    M.reset()
  elseif arg == 'stats' then
    M._open_tab_if_needed()
    M.show_stats()
  else
    M.launch()
  end
end

function M.launch()
  if M._state.active then
    if M._state.buf and vim.api.nvim_buf_is_valid(M._state.buf) then
      vim.api.nvim_set_current_buf(M._state.buf)
    end
    vim.notify('NVTutor is already active', vim.log.levels.INFO)
    return
  end

  -- Open a dedicated tab — avoids conflicts with dashboards and user workspace
  vim.cmd('tabnew')

  require('nvtutor.highlights').setup()
  local progress = require('nvtutor.progress')
  local state = progress.load()

  -- Resume review/gauntlet if active
  if state.review_state and state.review_state.active then
    local review = require('nvtutor.review')
    local ui_mod = require('nvtutor.ui')
    local buf = ui_mod.create_scratch_buffer({})
    M._state.buf = buf
    M._state.active = true
    vim.api.nvim_set_current_buf(buf)
    if state.review_state.type == 'gauntlet' then
      review.start_gauntlet(buf, function()
        local ps = progress.load()
        ps.gauntlet_completed = true
        progress.save(ps)
        M._state.active = false
        M.show_stats()
      end)
    else
      review.start_review(state.review_state.chapter, buf, function()
        M.complete_chapter(state.review_state.chapter)
      end)
    end
    return
  end

  if progress.is_new_user() then
    M.start_lesson(1, 1)
  else
    M.show_menu()
  end
end

function M.show_menu()
  local ui = require('nvtutor.ui')
  local chapters = require('nvtutor.chapters')
  local progress = require('nvtutor.progress')
  local state = progress.load()

  ui.show_menu(chapters.chapters, state, function(chapter_n)
    if chapter_n == 'continue' then
      M.start_lesson(state.current_chapter, state.current_lesson)
    else
      M.show_lesson_menu(chapter_n)
    end
  end)
end

function M.show_lesson_menu(chapter_n)
  local ui = require('nvtutor.ui')
  local chapters = require('nvtutor.chapters')
  local progress = require('nvtutor.progress')
  local state = progress.load()
  local chapter = chapters.get_chapter(chapter_n)

  ui.show_lesson_menu(chapter_n, chapter.lessons, state, function(lesson_n)
    M.start_lesson(chapter_n, lesson_n)
  end)
end

function M.start_lesson(chapter_n, lesson_n)
  local chapters = require('nvtutor.chapters')
  local ui = require('nvtutor.ui')
  local progress = require('nvtutor.progress')
  local lesson = chapters.get_lesson(chapter_n, lesson_n)

  if not lesson then
    vim.notify('Lesson not found: Ch' .. chapter_n .. ' L' .. lesson_n, vim.log.levels.ERROR)
    return
  end

  M._state.active = true
  M._state.chapter = chapter_n
  M._state.lesson = lesson_n
  M._state.challenge_idx = 1

  -- Save current position
  local state = progress.load()
  state.current_chapter = chapter_n
  state.current_lesson = lesson_n
  state.current_challenge = 1
  progress.save(state)

  local buf = ui.create_scratch_buffer({})
  M._state.buf = buf

  -- Use vim.schedule so our nvim_set_current_buf call runs after any
  -- dashboard/startup autocmds (e.g. LazyVim TabNewEntered) have fired and
  -- settled.  Without this, those autocmds run after us and replace the
  -- window's buffer back to the dashboard.
  vim.schedule(function()
    -- Verify the buf is still valid (could have been wiped if something else
    -- interfered before the scheduled callback ran)
    if not vim.api.nvim_buf_is_valid(buf) then return end

    vim.api.nvim_set_current_buf(buf)
    -- Store the window that is now showing the practice buffer so the engine
    -- can target it precisely.
    M._state.win = vim.api.nvim_get_current_win()

    -- Set up quit handler — use VimLeavePre only; BufWinLeave is too
    -- aggressive because LazyVim or other plugins may hide/show the buffer
    -- legitimately, and firing _on_quit() then wipes the whole session.
    local augroup = vim.api.nvim_create_augroup('NVTutorSession', { clear = true })
    vim.api.nvim_create_autocmd('VimLeavePre', {
      group = augroup,
      buffer = buf,
      callback = function()
        M._on_quit()
      end,
    })

    -- Show lesson intro then start challenges
    local intro_lines = lesson.explanation
    if not intro_lines then
      -- Chapters use 'description' as a single string; wrap it for display
      intro_lines = type(lesson.description) == 'table' and lesson.description
        or { lesson.description or '' }
    end
    ui.show_lesson_intro(intro_lines, function()
      M.start_challenge_sequence(chapter_n, lesson_n, 1)
    end)
  end)
end

function M.start_challenge_sequence(chapter_n, lesson_n, challenge_idx)
  local chapters = require('nvtutor.chapters')
  local engine = require('nvtutor.engine')
  local progress = require('nvtutor.progress')
  local lesson = chapters.get_lesson(chapter_n, lesson_n)

  if challenge_idx > #lesson.challenges then
    M.complete_lesson(chapter_n, lesson_n)
    return
  end

  M._state.challenge_idx = challenge_idx

  -- Save position
  local state = progress.load()
  state.current_challenge = challenge_idx
  progress.save(state)

  local challenge_def = lesson.challenges[challenge_idx]
  local total = #lesson.challenges

  engine.start_challenge(M._state.buf, M._state.win, challenge_def, challenge_idx, total, function(result)
    if result.skipped then
      -- Move to next challenge
      M.start_challenge_sequence(chapter_n, lesson_n, challenge_idx + 1)
    else
      -- Record mastery
      progress.mark_challenge_complete(
        chapter_n, lesson_n, challenge_idx,
        challenge_def.command, result.keystrokes, result.time, result.tier
      )
      -- Brief pause then next challenge
      vim.defer_fn(function()
        M.start_challenge_sequence(chapter_n, lesson_n, challenge_idx + 1)
      end, 1500)
    end
  end)
end

function M.complete_lesson(chapter_n, lesson_n)
  local chapters = require('nvtutor.chapters')
  local progress = require('nvtutor.progress')
  local ui = require('nvtutor.ui')

  progress.mark_lesson_complete(chapter_n, lesson_n)

  local chapter = chapters.get_chapter(chapter_n)
  local lesson_count = #chapter.lessons

  if lesson_n >= lesson_count then
    -- Last lesson in chapter — trigger review round
    ui.show_feedback_message('Chapter ' .. chapter_n .. ' lessons complete! Starting review round...', function()
      local review = require('nvtutor.review')
      review.start_review(chapter_n, M._state.buf, function()
        M.complete_chapter(chapter_n)
      end)
    end)
  else
    ui.show_feedback_message('Lesson complete! Press any key for the next lesson.', function()
      M.start_lesson(chapter_n, lesson_n + 1)
    end)
  end
end

function M.complete_chapter(chapter_n)
  local progress = require('nvtutor.progress')
  local ui = require('nvtutor.ui')

  progress.mark_chapter_complete(chapter_n)

  if chapter_n >= 8 then
    -- Final chapter — start gauntlet
    ui.show_feedback_message('All chapters complete! Starting the final gauntlet...', function()
      local review = require('nvtutor.review')
      review.start_gauntlet(M._state.buf, function()
        local state = progress.load()
        state.gauntlet_completed = true
        progress.save(state)
        M.show_stats()
      end)
    end)
  else
    ui.show_feedback_message(
      'Chapter ' .. chapter_n .. ' complete! Chapter ' .. (chapter_n + 1) .. ' unlocked. Press any key.',
      function()
        M._state.active = false
        M.show_menu()
      end
    )
  end
end

function M.show_stats()
  local ui = require('nvtutor.ui')
  local progress = require('nvtutor.progress')
  local state = progress.load()
  ui.show_stats(state)
end

function M.reset()
  vim.ui.select({ 'Yes, reset all progress', 'Cancel' }, {
    prompt = 'Reset all NVTutor progress? This cannot be undone.',
  }, function(choice)
    if choice and choice:match('^Yes') then
      local progress = require('nvtutor.progress')
      progress.reset()
      vim.notify('NVTutor progress has been reset.', vim.log.levels.INFO)
    end
  end)
end

function M._on_quit()
  local engine = require('nvtutor.engine')
  engine.stop_counting()

  -- Clean up autocmds
  pcall(vim.api.nvim_del_augroup_by_name, 'NVTutorSession')
  pcall(vim.api.nvim_del_augroup_by_name, 'NVTutorChallenge')

  -- Clean up UI
  local ui = require('nvtutor.ui')
  ui.teardown()

  M._state.active = false
  M._state.buf = nil
  M._state.win = nil
end

return M
