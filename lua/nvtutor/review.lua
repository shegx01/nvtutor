local M = {}

---Select review challenges weighted by mastery
---@param chapters_range number[] list of chapter numbers to draw from
---@param count number how many challenges to select
---@param progress_state table progress data
---@return table[] list of challenge definitions
function M.select_review_challenges(chapters_range, count, progress_state)
  local chapters = require('nvtutor.chapters')
  local pool = {}

  for _, ch_n in ipairs(chapters_range) do
    local ok, chapter = pcall(chapters.get_chapter, ch_n)
    if ok and chapter.lessons then
      for _, lesson in ipairs(chapter.lessons) do
        for _, challenge in ipairs(lesson.challenges or {}) do
          local cmd = challenge.command
          local mastery = progress_state.mastery[cmd]
          -- Weight: unmastered=4, bronze=3, silver=2, gold=1
          local weight = 4
          if mastery == 'bronze' then weight = 3
          elseif mastery == 'silver' then weight = 2
          elseif mastery == 'gold' then weight = 1
          end
          for _ = 1, weight do
            table.insert(pool, challenge)
          end
        end
      end
    end
  end

  -- Shuffle and select unique commands
  local selected = {}
  local seen_commands = {}
  -- Fisher-Yates shuffle
  for i = #pool, 2, -1 do
    local j = math.random(1, i)
    pool[i], pool[j] = pool[j], pool[i]
  end

  for _, challenge in ipairs(pool) do
    if #selected >= count then break end
    if not seen_commands[challenge.command] then
      seen_commands[challenge.command] = true
      table.insert(selected, challenge)
    end
  end

  return selected
end

---Start a review round for a chapter
---@param chapter_n number
---@param buf number practice buffer
---@param on_done function callback when review is complete
function M.start_review(chapter_n, buf, on_done)
  local progress = require('nvtutor.progress')
  local state = progress.load()

  local challenges
  local start_idx

  -- Check for resume
  if state.review_state and state.review_state.active
     and state.review_state.type == 'review'
     and state.review_state.chapter == chapter_n then
    challenges = state.review_state.challenges
    start_idx = state.review_state.current_idx
  else
    -- Generate new review challenges
    local range = {}
    for i = 1, chapter_n do
      table.insert(range, i)
    end
    challenges = M.select_review_challenges(range, math.min(7, chapter_n * 2), state)

    if #challenges == 0 then
      on_done()
      return
    end

    -- Save review state
    state.review_state = {
      active = true,
      type = 'review',
      chapter = chapter_n,
      challenges = challenges,
      current_idx = 1,
    }
    progress.save(state)
    start_idx = 1
  end

  M._run_challenge_sequence(buf, challenges, start_idx, 'review', chapter_n, on_done)
end

---Start the final gauntlet
---@param buf number practice buffer
---@param on_done function callback when gauntlet is complete
function M.start_gauntlet(buf, on_done)
  local progress = require('nvtutor.progress')
  local state = progress.load()

  local challenges
  local start_idx

  -- Check for resume
  if state.review_state and state.review_state.active
     and state.review_state.type == 'gauntlet' then
    challenges = state.review_state.challenges
    start_idx = state.review_state.current_idx
  else
    -- Generate gauntlet challenges — at least one per chapter
    local all_range = { 1, 2, 3, 4, 5, 6, 7, 8 }
    challenges = M.select_review_challenges(all_range, 12, state)

    if #challenges == 0 then
      on_done()
      return
    end

    state.review_state = {
      active = true,
      type = 'gauntlet',
      challenges = challenges,
      current_idx = 1,
    }
    progress.save(state)
    start_idx = 1
  end

  M._run_challenge_sequence(buf, challenges, start_idx, 'gauntlet', nil, on_done)
end

---Run a sequence of challenges (used by both review and gauntlet)
---@param buf number
---@param challenges table[]
---@param start_idx number
---@param review_type string 'review' or 'gauntlet'
---@param chapter_n number|nil
---@param on_done function
function M._run_challenge_sequence(buf, challenges, start_idx, review_type, chapter_n, on_done)
  local engine = require('nvtutor.engine')
  local progress = require('nvtutor.progress')
  local ui = require('nvtutor.ui')

  local total = #challenges
  local label = review_type == 'gauntlet' and 'Gauntlet' or ('Ch' .. chapter_n .. ' Review')

  local function run_next(idx)
    if idx > total then
      -- Review complete — clear state
      local state = progress.load()
      state.review_state = nil
      progress.save(state)
      on_done()
      return
    end

    local challenge = challenges[idx]

    -- Update review state
    local state = progress.load()
    if state.review_state then
      state.review_state.current_idx = idx
      progress.save(state)
    end

    -- engine.start_challenge already shows the challenge prompt
    engine.start_challenge(buf, challenge, idx, total, function(result)
      if not result.skipped then
        progress.mark_challenge_complete(
          nil, nil, idx,
          challenge.command, result.keystrokes, result.time, result.tier
        )
      end
      vim.defer_fn(function()
        run_next(idx + 1)
      end, 1500)
    end)
  end

  run_next(start_idx)
end

return M
