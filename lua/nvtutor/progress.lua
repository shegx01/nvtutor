local M = {}

local DATA_PATH = vim.fn.stdpath('data') .. '/tutor/progress.json'
local FILE_MODE = 420 -- 0644 octal

local function default_state()
  return {
    version = 1,
    current_chapter = 1,
    current_lesson = 1,
    current_challenge = 1,
    chapters_unlocked = 1,
    chapters_completed = {},
    lessons_completed = {},
    mastery = {},
    command_stats = {},
    total_time = 0,
    gauntlet_completed = false,
    gauntlet_stats = nil,
    review_state = nil,
    daily_practice = {},  -- { ["2026-04-22"] = 120.5, ... } seconds per day
  }
end

local function ensure_dir()
  local dir = vim.fn.fnamemodify(DATA_PATH, ':h')
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
end

function M.load()
  ensure_dir()

  local fd = vim.uv.fs_open(DATA_PATH, 'r', FILE_MODE)
  if not fd then
    return default_state()
  end

  local stat = vim.uv.fs_fstat(fd)
  if not stat then
    vim.uv.fs_close(fd)
    return default_state()
  end
  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)

  if not data or data == '' then
    return default_state()
  end

  local ok, decoded = pcall(vim.json.decode, data)
  if not ok or type(decoded) ~= 'table' then
    return default_state()
  end

  -- Merge decoded state over defaults so new keys are always present
  local state = default_state()
  for k, v in pairs(decoded) do
    state[k] = v
  end

  return state
end

function M.save(state)
  ensure_dir()

  local ok, encoded = pcall(vim.json.encode, state)
  if not ok then
    vim.notify('NVTutor: failed to encode progress: ' .. tostring(encoded), vim.log.levels.ERROR)
    return
  end

  local tmp_path = DATA_PATH .. '.tmp'

  local fd = vim.uv.fs_open(tmp_path, 'w', FILE_MODE)
  if not fd then
    vim.notify('NVTutor: failed to open tmp file for writing', vim.log.levels.ERROR)
    return
  end

  local bytes, write_err = vim.uv.fs_write(fd, encoded, 0)
  if not bytes then
    vim.uv.fs_close(fd)
    vim.notify('NVTutor: failed to write progress: ' .. tostring(write_err), vim.log.levels.ERROR)
    return
  end
  vim.uv.fs_close(fd)

  local rename_ok, rename_err = vim.uv.fs_rename(tmp_path, DATA_PATH)
  if not rename_ok then
    vim.notify('NVTutor: failed to save progress: ' .. tostring(rename_err), vim.log.levels.ERROR)
  end
end

function M.reset()
  local ok, err = vim.uv.fs_unlink(DATA_PATH)
  if not ok and err and not err:match('ENOENT') then
    vim.notify('NVTutor: failed to delete progress file: ' .. tostring(err), vim.log.levels.WARN)
  end
  return default_state()
end

function M.is_new_user()
  local state = M.load()
  return (state.current_chapter or 1) == 1
    and (state.current_lesson or 1) == 1
    and (state.current_challenge or 1) == 1
end

function M.get_mastery_tier(keystrokes, optimal_keystrokes, time, optimal_time)
  if keystrokes <= optimal_keystrokes and time <= optimal_time * 1.5 then
    return 'gold'
  elseif keystrokes <= optimal_keystrokes * 1.5 and time <= optimal_time * 2.5 then
    return 'silver'
  else
    return 'bronze'
  end
end

function M.mark_challenge_complete(command, keystrokes, time, tier)
  local state = M.load()

  -- Only upgrade mastery tier, never downgrade
  local current_tier = state.mastery[command]
  local tier_rank = { bronze = 1, silver = 2, gold = 3 }
  if not current_tier or (tier_rank[tier] or 0) > (tier_rank[current_tier] or 0) then
    state.mastery[command] = tier
  end

  -- Update command stats
  local stats = state.command_stats[command]
  if not stats then
    state.command_stats[command] = {
      best_keystrokes = keystrokes,
      best_time = time,
      attempts = 1,
    }
  else
    stats.attempts = stats.attempts + 1
    if keystrokes < stats.best_keystrokes then
      stats.best_keystrokes = keystrokes
    end
    if time < stats.best_time then
      stats.best_time = time
    end
    state.command_stats[command] = stats
  end

  state.total_time = (state.total_time or 0) + time

  -- Track daily practice time
  local today = os.date('%Y-%m-%d')
  if not state.daily_practice then state.daily_practice = {} end
  state.daily_practice[today] = (state.daily_practice[today] or 0) + time

  M.save(state)
end

function M.mark_lesson_complete(chapter, lesson)
  local state = M.load()

  local key = chapter .. ':' .. lesson
  state.lessons_completed[key] = true

  -- Advance current_lesson pointer
  if chapter == state.current_chapter and lesson >= state.current_lesson then
    state.current_lesson = lesson + 1
    state.current_challenge = 1
  end

  M.save(state)
end

function M.mark_chapter_complete(chapter)
  local state = M.load()

  state.chapters_completed[tostring(chapter)] = true

  -- Unlock next chapter
  if chapter >= state.chapters_unlocked then
    state.chapters_unlocked = chapter + 1
  end

  -- Reset lesson pointer for next chapter
  state.current_chapter = chapter + 1
  state.current_lesson = 1
  state.current_challenge = 1

  M.save(state)
end

--- Returns true when every non-advanced lesson in chapter_n is completed.
---@param chapter_n number
---@return boolean
function M.all_basic_complete(chapter_n)
  local state = M.load()
  local ok, chapter = pcall(require, 'nvtutor.chapters.ch' .. chapter_n)
  if not ok then
    vim.notify('NVTutor: failed to load chapter ' .. chapter_n .. ': ' .. tostring(chapter), vim.log.levels.WARN)
    return false
  end
  if not chapter.lessons then return false end
  for i, lesson in ipairs(chapter.lessons) do
    if not lesson.advanced then
      local key = chapter_n .. ':' .. i
      if not state.lessons_completed[key] then
        return false
      end
    end
  end
  return true
end

return M
