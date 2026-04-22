local M = {}

--- Write to a debug log file (persists even if Neovim hangs)
local function dbg(msg)
  local f = io.open(vim.fn.stdpath('data') .. '/tutor/debug.log', 'a')
  if f then
    f:write(os.date('%H:%M:%S') .. ' ' .. msg .. '\n')
    f:close()
  end
end

--- Disable mini.nvim plugins on a practice buffer so users learn native Vim behavior.
local function disable_mini_plugins(buf)
  vim.api.nvim_buf_set_var(buf, 'miniai_disable', true)
  vim.api.nvim_buf_set_var(buf, 'minisurround_disable', true)
  vim.api.nvim_buf_set_var(buf, 'minicomment_disable', true)
  vim.api.nvim_buf_set_var(buf, 'minipairs_disable', true)
  vim.api.nvim_buf_set_var(buf, 'miniindentscope_disable', true)
end

--- Restore native Vim keymaps that distributions (LazyVim, etc.) override globally.
--- Buffer-local maps take precedence over global maps.
local function restore_native_keymaps(buf)
  local natives = {
    'H', 'L', 'M',           -- screen motions (LazyVim remaps H/L to buffer switching)
    'J',                      -- join lines (some configs remap to move line down)
    's', 'S',                 -- substitute (LazyVim maps s to flash.nvim/leap)
  }
  for _, key in ipairs(natives) do
    vim.keymap.set('n', key, key, { buffer = buf, desc = 'NVTutor: native ' .. key })
  end
end

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
    vim.cmd('noautocmd buffer ' .. M._state.buf)
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
      vim.cmd('noautocmd buffer ' .. M._state.buf)
    end
    vim.notify('NVTutor is already active', vim.log.levels.INFO)
    return
  end

  -- Open a dedicated tab with noautocmd so dashboard plugins can't intercept
  vim.cmd('noautocmd tabnew')

  require('nvtutor.highlights').setup()
  local progress = require('nvtutor.progress')
  local state = progress.load()

  -- Resume review/gauntlet if active
  if state.review_state and state.review_state.active then
    local review = require('nvtutor.review')
    -- Create buffer directly (not via create_scratch_buffer which sets bufhidden=wipe)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('buflisted', false, { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
    disable_mini_plugins(buf)
    restore_native_keymaps(buf)
    M._state.buf = buf
    M._state.active = true
    local old_ei = vim.o.eventignore
    vim.o.eventignore = 'all'
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), buf)
    vim.o.eventignore = old_ei
    M._state.win = vim.api.nvim_get_current_win()
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

  -- Pre-fill the buffer with the first challenge's content so the user
  -- sees real text immediately — not a blank screen.
  local first_challenge = lesson.challenges and lesson.challenges[1]
  local initial_lines = first_challenge and first_challenge.buffer_lines or { '' }

  -- Clean up old practice buffer if it exists (prevents buffer leaks across lessons)
  if M._state.buf and vim.api.nvim_buf_is_valid(M._state.buf) then
    pcall(vim.api.nvim_buf_delete, M._state.buf, { force = true })
  end

  -- Create the buffer with content already in it
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('buflisted', false, { buf = buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  disable_mini_plugins(buf)
  restore_native_keymaps(buf)

  M._state.buf = buf

  -- Force display — suppress all events to prevent dashboard plugins from intercepting
  local win = vim.api.nvim_get_current_win()
  local old_ei = vim.o.eventignore
  vim.o.eventignore = 'all'
  vim.api.nvim_win_set_buf(win, buf)
  vim.o.eventignore = old_ei
  M._state.win = win

  -- Clean window appearance for the tutor
  ui.configure_practice_window(win)

  -- Set up quit handler
  local augroup = vim.api.nvim_create_augroup('NVTutorSession', { clear = true })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = augroup,
    callback = function()
      M._on_quit()
    end,
  })

  -- Show lesson intro then start challenges
  local intro_lines = lesson.explanation
  if not intro_lines then
    intro_lines = type(lesson.description) == 'table' and lesson.description
      or { lesson.description or '' }
  end
  ui.show_lesson_intro(intro_lines, function()
    M.start_challenge_sequence(chapter_n, lesson_n, 1)
  end)
end

function M.start_challenge_sequence(chapter_n, lesson_n, challenge_idx)
  dbg(string.format('start_challenge_sequence Ch%d L%d C%d', chapter_n, lesson_n, challenge_idx))
  local ok, err = pcall(function()
    local chapters = require('nvtutor.chapters')
    local engine = require('nvtutor.engine')
    local progress = require('nvtutor.progress')
    local lesson = chapters.get_lesson(chapter_n, lesson_n)
    if not lesson or not lesson.challenges then
      dbg('ERROR: lesson not found')
      vim.notify(string.format('NVTutor: lesson Ch%d L%d not found', chapter_n, lesson_n), vim.log.levels.ERROR)
      return
    end

    if challenge_idx > #lesson.challenges then
      dbg('all challenges done, completing lesson')
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
    dbg(string.format('starting engine challenge %d/%d: %s', challenge_idx, total, challenge_def.command or '?'))

    engine.start_challenge(M._state.buf, M._state.win, challenge_def, challenge_idx, total, function(result)
      dbg(string.format('challenge %d completed: skipped=%s', challenge_idx, tostring(result.skipped)))
      if result.skipped then
        M.start_challenge_sequence(chapter_n, lesson_n, challenge_idx + 1)
      else
        progress.mark_challenge_complete(
          challenge_def.command, result.keystrokes, result.time, result.tier
        )
        local delay = result.has_optimal and 2500 or 1500
        dbg(string.format('scheduling next challenge in %dms', delay))
        vim.defer_fn(function()
          dbg('defer_fn fired, advancing to next challenge')
          M.start_challenge_sequence(chapter_n, lesson_n, challenge_idx + 1)
        end, delay)
      end
    end)
  end) -- pcall
  if not ok then
    dbg('ERROR in start_challenge_sequence: ' .. tostring(err))
    vim.notify('NVTutor error: ' .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.complete_lesson(chapter_n, lesson_n)
  local chapters = require('nvtutor.chapters')
  local progress = require('nvtutor.progress')
  local ui = require('nvtutor.ui')

  progress.mark_lesson_complete(chapter_n, lesson_n)

  local ok, chapter = pcall(chapters.get_chapter, chapter_n)
  if not ok or not chapter or not chapter.lessons then
    vim.notify(string.format('NVTutor: failed to load chapter %d', chapter_n), vim.log.levels.ERROR)
    return
  end
  local lesson_count = #chapter.lessons

  if lesson_n >= lesson_count then
    -- Last lesson in chapter — auto-advance to review round
    ui.show_timed_message('Chapter ' .. chapter_n .. ' complete! Starting review...', 2000, function()
      local review = require('nvtutor.review')
      review.start_review(chapter_n, M._state.buf, function()
        M.complete_chapter(chapter_n)
      end)
    end)
  else
    -- Auto-advance to next lesson
    ui.show_timed_message('Lesson complete! Next lesson starting...', 2000, function()
      M.start_lesson(chapter_n, lesson_n + 1)
    end)
  end
end

function M.complete_chapter(chapter_n)
  local progress = require('nvtutor.progress')
  local ui = require('nvtutor.ui')

  progress.mark_chapter_complete(chapter_n)

  if chapter_n >= require('nvtutor.chapters').get_chapter_count() then
    -- Final chapter — offer gauntlet or replay
    ui.show_chapter_complete(chapter_n, true, function(choice)
      if choice == 'replay' then
        M.start_lesson(chapter_n, 1)
      else
        local review = require('nvtutor.review')
        review.start_gauntlet(M._state.buf, function()
          local state = progress.load()
          state.gauntlet_completed = true
          progress.save(state)
          M._state.active = false
          M.show_stats()
        end)
      end
    end)
  else
    -- Offer next chapter, replay, or menu
    ui.show_chapter_complete(chapter_n, false, function(choice)
      if choice == 'replay' then
        M.start_lesson(chapter_n, 1)
      elseif choice == 'menu' then
        M._state.active = false
        M.show_menu()
      else -- 'next'
        M.start_lesson(chapter_n + 1, 1)
      end
    end)
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
