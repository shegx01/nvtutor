local M = {}

-- Module-level namespace for extmarks
M._ns = vim.api.nvim_create_namespace('nvtutor')

-- Track all created floating windows for cleanup
M._floats = {}

-- Track all created scratch buffers for cleanup
M._scratch_bufs = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Compute a floating window config.
---@param lines string[] Content lines (used for auto-sizing)
---@param opts table User options
---@return table nvim_open_win config
---Soft-wrap a list of lines to fit within max_width.
---Returns wrapped lines (for buffer content) and the actual max line width.
---@param lines string[]
---@param max_width number
---@return string[] wrapped, number actual_width
local function wrap_lines(lines, max_width)
  local wrapped = {}
  local actual_max = 0
  for _, line in ipairs(lines) do
    if #line <= max_width then
      wrapped[#wrapped + 1] = line
      if #line > actual_max then actual_max = #line end
    else
      -- Wrap at word boundaries
      local remaining = line
      local safety = 200 -- prevent infinite loop
      while #remaining > max_width and safety > 0 do
        safety = safety - 1
        -- Find the last space within max_width
        local space = remaining:sub(1, max_width):find('%s[^%s]*$')
        local cut
        if space and space > 1 then
          cut = space
        else
          -- No space to break at — hard-cut at max_width
          cut = max_width
        end
        local chunk = remaining:sub(1, cut)
        wrapped[#wrapped + 1] = chunk
        if #chunk > actual_max then actual_max = #chunk end
        local rest = remaining:sub(cut + 1):gsub('^%s+', '')
        if #rest == 0 then break end
        remaining = rest  -- no prefix padding that would grow the string
      end
      if #remaining > 0 then
        wrapped[#wrapped + 1] = remaining
        if #remaining > actual_max then actual_max = #remaining end
      end
    end
  end
  return wrapped, actual_max
end

local function make_float_config(lines, opts)
  opts = opts or {}

  local ui_width  = vim.o.columns
  local ui_height = vim.o.lines

  -- Cap float width to 70% of screen or explicit width
  local max_float_width = opts.width or math.floor(ui_width * 0.7)
  max_float_width = math.min(max_float_width, ui_width - 4)

  -- Determine width from content (already wrapped by caller)
  local max_line = 0
  for _, l in ipairs(lines) do
    if #l > max_line then max_line = #l end
  end
  local width = math.max(math.min(max_line + 2, max_float_width), 30)

  -- Determine height
  local height = opts.height or #lines
  height = math.min(height, ui_height - 4)

  local border = opts.border or 'rounded'

  -- Determine row / col based on position
  local position = opts.position or 'center'
  local row, col

  if position == 'top' then
    row = 0
    col = math.floor((ui_width - width) / 2)
  elseif position == 'bottom' then
    -- Anchor to the bottom, leaving room for the status line and border
    row = ui_height - height - 3
    col = math.floor((ui_width - width) / 2)
  else -- center
    row = math.floor((ui_height - height) / 2)
    col = math.floor((ui_width - width) / 2)
  end

  return {
    relative = 'editor',
    row      = row,
    col      = col,
    width    = width,
    height   = height,
    border   = border,
    style    = 'minimal',
    zindex   = 50,
  }
end

---Set a buffer option using the appropriate API for the Neovim version.
---@param buf integer
---@param name string
---@param value any
local function buf_set_option(buf, name, value)
  -- nvim_set_option_value is the preferred API in 0.10+
  vim.api.nvim_set_option_value(name, value, { buf = buf })
end

---Register a float handle for teardown tracking.
---@param handle table {buf, win}
local function track_float(handle)
  M._floats[#M._floats + 1] = handle
end

-- ---------------------------------------------------------------------------
-- 1. create_scratch_buffer
-- ---------------------------------------------------------------------------

---Create an unlisted scratch buffer pre-filled with content lines.
---@param content_lines string[]
---@return integer buf handle
function M.create_scratch_buffer(content_lines)
  local buf = vim.api.nvim_create_buf(false, true)

  buf_set_option(buf, 'buftype',   'nofile')
  buf_set_option(buf, 'buflisted', false)
  buf_set_option(buf, 'bufhidden', 'wipe')
  buf_set_option(buf, 'swapfile',  false)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content_lines or {})

  M._scratch_bufs[#M._scratch_bufs + 1] = buf
  return buf
end

-- ---------------------------------------------------------------------------
-- 2. show_floating
-- ---------------------------------------------------------------------------

---Show a floating window with the given lines.
---@param lines string[]
---@param opts? table { position, width, height, border }
---@return table { buf: integer, win: integer }
function M.show_floating(lines, opts)
  opts = opts or {}

  -- Pre-wrap long lines so they fit the float and height is accurate
  local max_w = opts.width or math.floor(vim.o.columns * 0.7)
  local wrapped = wrap_lines(lines, max_w)

  local buf = M.create_scratch_buffer(wrapped)
  local config = make_float_config(wrapped, opts)
  local win = vim.api.nvim_open_win(buf, false, config)

  -- Basic window appearance — wrap enabled for safety
  vim.api.nvim_set_option_value('wrap',       true,  { win = win })
  vim.api.nvim_set_option_value('cursorline', false, { win = win })
  vim.api.nvim_set_option_value('number',     false, { win = win })
  vim.api.nvim_set_option_value('signcolumn', 'no',  { win = win })

  local handle = { buf = buf, win = win }
  track_float(handle)
  return handle
end

-- ---------------------------------------------------------------------------
-- Internal: close a float and remove from tracking list
-- ---------------------------------------------------------------------------

local function close_float(handle)
  if handle.win and vim.api.nvim_win_is_valid(handle.win) then
    pcall(vim.api.nvim_win_close, handle.win, true)
  end
  if handle.buf and vim.api.nvim_buf_is_valid(handle.buf) then
    pcall(vim.api.nvim_buf_delete, handle.buf, { force = true })
  end
end

local function remove_float(handle)
  close_float(handle)
  for i, h in ipairs(M._floats) do
    if h == handle then
      table.remove(M._floats, i)
      break
    end
  end
end

-- ---------------------------------------------------------------------------
-- Internal: set buffer-local keymaps (cleaned up when buf is wiped)
-- ---------------------------------------------------------------------------

local function map(buf, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    nowait  = true,
    silent  = true,
    desc    = desc,
  })
end

-- ---------------------------------------------------------------------------
-- 3. show_menu
-- ---------------------------------------------------------------------------

---Chapter selection menu rendered in the current window.
---@param chapters_data table[]  Array of chapter definitions
---@param progress_state table   Progress state from progress.load()
---@param on_select fun(chapter_n: integer|'continue')
function M.show_menu(chapters_data, progress_state, on_select)
  local lines = {}
  local function push(s) lines[#lines + 1] = s end

  push('  NVTutor — Chapter Select')
  push('  ' .. string.rep('─', 40))
  push('')

  local has_progress = progress_state
    and progress_state.current_chapter
    and progress_state.current_chapter > 0

  if has_progress then
    push('  [c] Continue — Ch' .. progress_state.current_chapter
      .. ' / L' .. (progress_state.current_lesson or 1))
    push('')
  end

  for i, chapter in ipairs(chapters_data) do
    local unlocked = i <= (progress_state and progress_state.chapters_unlocked or 1)

    local lock_icon = unlocked and '  ' or ' 󰌾 '
    local mastery   = ''
    if progress_state and progress_state.mastery then
      -- Mastery is a flat map: command -> "gold"/"silver"/"bronze"
      -- Count commands that belong to this chapter's lessons
      local ch_ok, ch_data = pcall(require, 'nvtutor.chapters.ch' .. i)
      if ch_ok and ch_data and ch_data.lessons then
        local gold_n, silver_n, bronze_n = 0, 0, 0
        for _, lesson in ipairs(ch_data.lessons) do
          for _, chal in ipairs(lesson.challenges or {}) do
            local tier = progress_state.mastery[chal.command]
            if tier == 'gold' then gold_n = gold_n + 1
            elseif tier == 'silver' then silver_n = silver_n + 1
            elseif tier == 'bronze' then bronze_n = bronze_n + 1
            end
          end
        end
        local total = gold_n + silver_n + bronze_n
        if total > 0 then
          mastery = string.format(' [%d gold, %d silver, %d bronze]', gold_n, silver_n, bronze_n)
        end
      end
    end

    local label
    if unlocked then
      label = string.format('  [%d]%s%s%s', i, lock_icon, chapter.title, mastery)
    else
      label = string.format('  [%d]%s%s', i, lock_icon, chapter.title)
    end
    push(label)
  end

  push('')
  push('  [q] Quit')

  local buf = M.create_scratch_buffer(lines)
  buf_set_option(buf, 'modifiable', false)

  vim.cmd('noautocmd buffer ' .. buf)

  -- Highlight locked chapters with a dimmed group
  for i, chapter in ipairs(chapters_data) do
    local unlocked = i <= (progress_state and progress_state.chapters_unlocked or 1)
    if not unlocked then
      -- lines offset: header=3 lines, optional continue=2, index i
      local line_offset = has_progress and 5 or 3
      local line_idx = line_offset + (i - 1)  -- 0-indexed
      pcall(vim.api.nvim_buf_add_highlight, buf, M._ns, 'NVTutorHint', line_idx, 0, -1)
    end
  end

  -- Number key bindings
  for i, chapter in ipairs(chapters_data) do
    local unlocked = i <= (progress_state and progress_state.chapters_unlocked or 1)

    if unlocked then
      local key = tostring(i)
      map(buf, 'n', key, function()
        on_select(i)
      end, 'Select chapter ' .. i)
    end
  end

  if has_progress then
    map(buf, 'n', 'c', function()
      on_select('continue')
    end, 'Continue from last position')
  end

  map(buf, 'n', 'q', function()
    vim.cmd('bwipeout')
  end, 'Quit menu')
end

-- ---------------------------------------------------------------------------
-- 4. show_lesson_menu
-- ---------------------------------------------------------------------------

---Lesson selection within a chapter, rendered in the current window.
---@param chapter_n integer
---@param lessons_data table[]
---@param progress_state table
---@param on_select fun(lesson_n: integer)
function M.show_lesson_menu(chapter_n, lessons_data, progress_state, on_select)
  local lines = {}
  local function push(s) lines[#lines + 1] = s end

  push(string.format('  NVTutor — Chapter %d Lessons', chapter_n))
  push('  ' .. string.rep('─', 40))
  push('')

  local progress_mod = require('nvtutor.progress')
  local basics_done = progress_mod.all_basic_complete(chapter_n)
  local locked_lines = {} -- track which display lines are locked (0-indexed)
  local line_idx = 3      -- 0-indexed: title(0) + separator(1) + blank(2)

  for i, lesson in ipairs(lessons_data) do
    local is_advanced = lesson.advanced == true
    local locked = is_advanced and not basics_done

    local done_icon = ''
    if progress_state and progress_state.lessons_completed then
      local key = chapter_n .. ':' .. i
      if progress_state.lessons_completed[key] then
        done_icon = ' ✓'
      end
    end

    local mastery = ''
    if progress_state and progress_state.mastery and lesson.challenges then
      local gold_n, total = 0, 0
      for _, chal in ipairs(lesson.challenges) do
        local tier = progress_state.mastery[chal.command]
        if tier then
          total = total + 1
          if tier == 'gold' then gold_n = gold_n + 1 end
        end
      end
      if total > 0 then
        mastery = string.format(' [%d/%d gold]', gold_n, total)
      end
    end

    local prefix = is_advanced and '★ ' or ''
    local suffix = locked and ' [locked]' or ''
    push(string.format('  [%d] %s%s%s%s%s', i, prefix, lesson.title or ('Lesson ' .. i), done_icon, mastery, suffix))
    if locked then
      locked_lines[line_idx] = true
    end
    line_idx = line_idx + 1
  end

  push('')
  push('  [q] Back')

  local buf = M.create_scratch_buffer(lines)
  buf_set_option(buf, 'modifiable', false)
  vim.cmd('noautocmd buffer ' .. buf)

  -- Dim locked advanced lessons
  for ln, _ in pairs(locked_lines) do
    pcall(vim.api.nvim_buf_add_highlight, buf, M._ns, 'NVTutorHint', ln, 0, -1)
  end

  for i, lesson in ipairs(lessons_data) do
    local is_advanced = lesson.advanced == true
    local locked = is_advanced and not basics_done
    if not locked then
      local key = tostring(i)
      map(buf, 'n', key, function()
        on_select(i)
      end, 'Select lesson ' .. i)
    end
  end

  map(buf, 'n', 'q', function()
    vim.cmd('bwipeout')
  end, 'Go back')
end

-- ---------------------------------------------------------------------------
-- 5. show_lesson_intro
-- ---------------------------------------------------------------------------

---Show lesson explanation in a floating window at the top of the screen.
---Dismisses on any keypress and calls on_dismiss.
---@param explanation_lines string[]
---@param on_dismiss fun()
function M.show_lesson_intro(explanation_lines, on_dismiss)
  local lines = {}
  for _, l in ipairs(explanation_lines) do
    lines[#lines + 1] = '  ' .. l
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '  [Press any key to continue]'

  -- Capture the current window BEFORE opening or focusing the float
  local prev_win = vim.api.nvim_get_current_win()

  local handle = M.show_floating(lines, { position = 'center' })

  -- Ensure we're in normal mode before focusing the float
  vim.cmd('noautocmd stopinsert')
  -- Focus the float so keypresses are captured
  vim.api.nvim_set_current_win(handle.win)

  local dismissed = false
  local function dismiss()
    if dismissed then return end
    dismissed = true
    remove_float(handle)
    -- Return focus to the practice buffer window
    if prev_win and vim.api.nvim_win_is_valid(prev_win) then
      vim.api.nvim_set_current_win(prev_win)
    end
    if on_dismiss then vim.schedule(on_dismiss) end
  end

  -- Map keys in BOTH normal and insert mode so dismiss works regardless
  local keys = {
    '<CR>', '<Space>', '<Esc>', '<Tab>',
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    '0','1','2','3','4','5','6','7','8','9',
  }
  for _, k in ipairs(keys) do
    map(handle.buf, 'n', k, dismiss, 'Dismiss')
    map(handle.buf, 'i', k, dismiss, 'Dismiss')
  end
end

-- ---------------------------------------------------------------------------
-- 6. show_challenge_prompt
-- ---------------------------------------------------------------------------

---Show a small floating window with the current challenge instruction.
---@param challenge_num integer
---@param total integer
---@param instruction string
---@return table { buf, win } handle (so caller can close it)
function M.show_challenge_prompt(challenge_num, total, instruction)
  local header = string.format('  Challenge %d/%d', challenge_num, total)
  local lines = {
    header,
    '  ' .. string.rep('─', math.max(#header, #instruction + 2)),
    '  ' .. instruction,
    '',
    '  Ctrl-L: retry  |  Ctrl-H: hint  |  Ctrl-N: skip',
  }

  -- Place at bottom so it doesn't cover the practice buffer text
  local handle = M.show_floating(lines, { position = 'bottom', border = 'rounded' })
  return handle
end

-- ---------------------------------------------------------------------------
-- 6b. Hint toggle
-- ---------------------------------------------------------------------------

-- Track active hint float so we can toggle it
M._hint_handle = nil

---Show a hint float. If already visible, close it (toggle).
---@param hint_text string
function M.toggle_hint(hint_text)
  -- If hint is showing, dismiss it
  if M._hint_handle then
    close_float(M._hint_handle)
    M._hint_handle = nil
    return
  end
  -- Show hint in a centered float
  local lines = {
    '',
    '  💡 ' .. hint_text,
    '',
    '  [Ctrl-H to dismiss]',
  }
  M._hint_handle = M.show_floating(lines, { position = 'center', border = 'rounded' })
end

---Close the hint if visible (called on challenge finish)
function M.close_hint()
  if M._hint_handle then
    close_float(M._hint_handle)
    M._hint_handle = nil
  end
end

-- ---------------------------------------------------------------------------
-- 7. show_feedback
-- ---------------------------------------------------------------------------

---Flash success/error with tier badge and keystroke comparison.
---Auto-dismisses after 1.5s (2.5s when optimal_solution is shown).
---@param success boolean
---@param tier string   'bronze'|'silver'|'gold'|nil
---@param keystrokes integer  Keystrokes used
---@param optimal integer     Optimal keystrokes
---@param time number         Time in seconds
---@param optimal_solution? string  Optional text describing the best approach
function M.show_feedback(success, tier, keystrokes, optimal, time, optimal_solution)
  local icon   = success and '  NICE! ' or '  Oops… '
  local result = success and 'Correct!' or 'Try again'

  local tier_badge = ''
  if tier == 'gold'   then tier_badge = '  [GOLD]'
  elseif tier == 'silver' then tier_badge = '  [SILVER]'
  elseif tier == 'bronze' then tier_badge = '  [BRONZE]'
  end

  local ks_line = string.format(
    '  Keystrokes: %d  (optimal: %d)  Time: %.1fs',
    keystrokes, optimal, time
  )

  local lines = {
    icon .. result,
    tier_badge ~= '' and tier_badge or '  ',
    ks_line,
  }

  -- Append optimal solution when provided
  if optimal_solution then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '  Optimal: ' .. optimal_solution
  end

  local handle = M.show_floating(lines, { position = 'bottom', border = 'rounded' })

  -- Apply highlight group to first line
  local hl = success and 'NVTutorSuccess' or 'NVTutorError'
  pcall(vim.api.nvim_buf_add_highlight, handle.buf, M._ns, hl, 0, 0, -1)

  -- Apply tier highlight if present
  if tier == 'gold' then
    pcall(vim.api.nvim_buf_add_highlight, handle.buf, M._ns, 'NVTutorGold', 1, 0, -1)
  elseif tier == 'silver' then
    pcall(vim.api.nvim_buf_add_highlight, handle.buf, M._ns, 'NVTutorSilver', 1, 0, -1)
  elseif tier == 'bronze' then
    pcall(vim.api.nvim_buf_add_highlight, handle.buf, M._ns, 'NVTutorBronze', 1, 0, -1)
  end

  -- Highlight the optimal solution line in gold if present
  if optimal_solution then
    pcall(vim.api.nvim_buf_add_highlight, handle.buf, M._ns, 'NVTutorGold', #lines - 1, 0, -1)
  end

  -- Content-aware dismiss: extra time when optimal_solution is shown
  local delay = 1500 + (optimal_solution and 1000 or 0)
  vim.defer_fn(function()
    remove_float(handle)
  end, delay)
end

-- ---------------------------------------------------------------------------
-- 8. show_feedback_message
-- ---------------------------------------------------------------------------

---Show a simple message in a floating window; dismiss on any keypress.
---@param message string
---@param on_dismiss fun()
function M.show_feedback_message(message, on_dismiss)
  local lines = {
    '',
    '  ' .. message,
    '',
    '  [Press any key to continue]',
  }

  local handle = M.show_floating(lines, { position = 'center', border = 'rounded' })
  vim.cmd('noautocmd stopinsert')
  vim.api.nvim_set_current_win(handle.win)

  local dismissed = false
  local function dismiss()
    if dismissed then return end
    dismissed = true
    remove_float(handle)
    if on_dismiss then vim.schedule(on_dismiss) end
  end

  local keys = {
    '<CR>', '<Space>', '<Esc>', '<Tab>',
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    '0','1','2','3','4','5','6','7','8','9',
  }
  for _, k in ipairs(keys) do
    map(handle.buf, 'n', k, dismiss, 'Dismiss message')
    map(handle.buf, 'i', k, dismiss, 'Dismiss message')
  end
end

-- ---------------------------------------------------------------------------
-- 8c. show_chapter_complete
-- ---------------------------------------------------------------------------

---Show chapter completion with choices: next chapter, replay, or menu.
---@param chapter_n integer
---@param is_final boolean  true if this is the last chapter
---@param on_choice fun(choice: string)  'next', 'replay', or 'menu'
function M.show_chapter_complete(chapter_n, is_final, on_choice)
  local lines = {
    '',
    string.format('  Chapter %d complete!', chapter_n),
    '',
  }

  if is_final then
    lines[#lines + 1] = '  [g] Start the Final Gauntlet'
    lines[#lines + 1] = '  [r] Replay this chapter'
  else
    lines[#lines + 1] = string.format('  [n] Next chapter (%d)', chapter_n + 1)
    lines[#lines + 1] = '  [r] Replay this chapter'
    lines[#lines + 1] = '  [m] Back to menu'
  end

  lines[#lines + 1] = ''

  local handle = M.show_floating(lines, { position = 'center', border = 'rounded' })
  pcall(vim.api.nvim_buf_add_highlight, handle.buf, M._ns, 'NVTutorGold', 1, 0, -1)
  vim.api.nvim_set_current_win(handle.win)

  local chosen = false
  local function choose(choice)
    if chosen then return end
    chosen = true
    remove_float(handle)
    if on_choice then vim.schedule(function() on_choice(choice) end) end
  end

  map(handle.buf, 'n', 'r', function() choose('replay') end, 'Replay chapter')

  if is_final then
    map(handle.buf, 'n', 'g', function() choose('next') end, 'Start gauntlet')
    -- Auto-advance to gauntlet after 5s if no choice
    vim.defer_fn(function() choose('next') end, 5000)
  else
    map(handle.buf, 'n', 'n', function() choose('next') end, 'Next chapter')
    map(handle.buf, 'n', 'm', function() choose('menu') end, 'Back to menu')
    -- Auto-advance to next chapter after 5s if no choice
    vim.defer_fn(function() choose('next') end, 5000)
  end
end

-- ---------------------------------------------------------------------------
-- 9. show_stats
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 8b. show_timed_message
-- ---------------------------------------------------------------------------

---Show a message that auto-dismisses after a delay (also dismissable by keypress).
---@param message string
---@param delay_ms number  milliseconds before auto-dismiss
---@param on_done fun()    callback after dismiss
function M.show_timed_message(message, delay_ms, on_done)
  local lines = {
    '',
    '  ' .. message,
    '',
  }

  local handle = M.show_floating(lines, { position = 'center', border = 'rounded' })
  pcall(vim.api.nvim_buf_add_highlight, handle.buf, M._ns, 'NVTutorSuccess', 1, 0, -1)

  local dismissed = false
  local function dismiss()
    if dismissed then return end
    dismissed = true
    remove_float(handle)
    if on_done then vim.schedule(on_done) end
  end

  -- Auto-dismiss after delay
  vim.defer_fn(dismiss, delay_ms)

  -- Also allow early dismiss by keypress
  local keys = {
    '<CR>', '<Space>', '<Esc>',
    'j','k','h','l','q',
  }
  for _, k in ipairs(keys) do
    map(handle.buf, 'n', k, dismiss, 'Dismiss')
    map(handle.buf, 'i', k, dismiss, 'Dismiss')
  end
end

-- ---------------------------------------------------------------------------
-- 9. show_stats
-- ---------------------------------------------------------------------------

---Full stats screen rendered in the current window.
---@param progress_state table
function M.show_stats(progress_state)
  local lines = {}
  local function push(s) lines[#lines + 1] = s end

  push('  NVTutor — Statistics')
  push('  ' .. string.rep('─', 42))
  push('')

  -- Chapters completed
  local chapters_done = 0
  if progress_state.chapters_completed then
    for _, v in pairs(progress_state.chapters_completed) do
      if v then chapters_done = chapters_done + 1 end
    end
  end
  -- Gauntlet
  local gauntlet = progress_state.gauntlet_completed and 'Yes  ' or 'No'
  push('  Gauntlet cleared   : ' .. gauntlet)
  push('')

  -- Commands / mastery breakdown (flat map: command -> "gold"/"silver"/"bronze")
  local total_cmds, bronze_n, silver_n, gold_n = 0, 0, 0, 0
  if progress_state.mastery then
    for _, tier in pairs(progress_state.mastery) do
      total_cmds = total_cmds + 1
      if tier == 'gold' then
        gold_n = gold_n + 1
      elseif tier == 'silver' then
        silver_n = silver_n + 1
      elseif tier == 'bronze' then
        bronze_n = bronze_n + 1
      end
    end
  end
  local ch_count = require('nvtutor.chapters').get_chapter_count()
  push(string.format('  Chapters completed : %d / %d', chapters_done, ch_count))

  push(string.format('  Commands tracked   : %d', total_cmds))
  push(string.format('  Gold mastery       : %d', gold_n))
  push(string.format('  Silver mastery     : %d', silver_n))
  push(string.format('  Bronze mastery     : %d', bronze_n))
  push('')

  -- Total time
  local total_seconds = progress_state.total_time or 0
  local total_min = math.floor(total_seconds / 60)
  local total_sec = math.floor(total_seconds % 60)
  push(string.format('  Total practice time: %dm %ds', total_min, total_sec))

  -- Today's practice
  local today = os.date('%Y-%m-%d')
  local daily = progress_state.daily_practice or {}
  local today_secs = daily[today] or 0
  local today_min = math.floor(today_secs / 60)
  local today_sec = math.floor(today_secs % 60)
  push(string.format('  Today             : %dm %ds', today_min, today_sec))
  push('')

  -- Practice activity (last 7 days as horizontal bars)
  push('  Recent Activity')
  push('  ' .. string.rep('─', 42))
  local day_names = { 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' }
  local bar_data = {} -- store for highlighting after buffer creation

  for d = 6, 0, -1 do
    local t = os.time() - d * 86400
    local date_str = os.date('%Y-%m-%d', t)
    local dow = tonumber(os.date('%w', t))
    local day_label = day_names[dow + 1]
    local secs = daily[date_str] or 0
    local mins = math.floor(secs / 60)

    -- Bar: each █ = 2 minutes, max 20 chars (40 min)
    local bar_len = math.min(math.floor(secs / 120), 20)
    local bar = string.rep('█', bar_len)
    local time_str = mins > 0 and string.format('%dm', mins) or ''

    local hl
    if secs == 0 then
      hl = 'NVTutorHint'
      bar = '·'
      time_str = ''
    elseif secs < 300 then
      hl = 'NVTutorBronze'
    elseif secs < 900 then
      hl = 'NVTutorSilver'
    else
      hl = 'NVTutorGold'
    end

    local is_today = d == 0
    local marker = is_today and ' ◀ today' or ''
    local line = string.format('  %s  %s %s%s', day_label, bar, time_str, marker)
    push(line)
    bar_data[#lines] = hl
  end

  push('')
  push('  [q] Close')

  local buf = M.create_scratch_buffer(lines)
  buf_set_option(buf, 'modifiable', false)
  vim.cmd('noautocmd buffer ' .. buf)

  -- Colour the mastery lines
  -- Line indices (0-based): gold=10, silver=11, bronze=12 after the header block
  -- Use a simple scan to find matching lines
  for idx, line in ipairs(lines) do
    if line:match('Gold mastery') then
      pcall(vim.api.nvim_buf_add_highlight, buf, M._ns, 'NVTutorGold', idx - 1, 0, -1)
    elseif line:match('Silver mastery') then
      pcall(vim.api.nvim_buf_add_highlight, buf, M._ns, 'NVTutorSilver', idx - 1, 0, -1)
    elseif line:match('Bronze mastery') then
      pcall(vim.api.nvim_buf_add_highlight, buf, M._ns, 'NVTutorBronze', idx - 1, 0, -1)
    end
  end

  -- Apply activity bar highlights
  for line_num, hl in pairs(bar_data) do
    pcall(vim.api.nvim_buf_add_highlight, buf, M._ns, hl, line_num - 1, 0, -1)
  end

  map(buf, 'n', 'q', function()
    vim.cmd('bwipeout')
  end, 'Close stats')
end

-- ---------------------------------------------------------------------------
-- 10. configure_practice_window
-- ---------------------------------------------------------------------------

local SCROLLOFF = 3

---Configure the practice window for optimal challenge display.
---@param win integer window handle
function M.configure_practice_window(win)
  vim.api.nvim_set_option_value('cursorline', true, { win = win })
  vim.api.nvim_set_option_value('number', true, { win = win })
  vim.api.nvim_set_option_value('relativenumber', true, { win = win })
  vim.api.nvim_set_option_value('signcolumn', 'no', { win = win })
  vim.api.nvim_set_option_value('scrolloff', SCROLLOFF, { win = win })
  vim.api.nvim_set_option_value('wrap', true, { win = win })
end

-- ---------------------------------------------------------------------------
-- 11. teardown
-- ---------------------------------------------------------------------------

---Close all tracked floating windows only (preserves scratch buffers).
---Use this between challenges to dismiss prompts without destroying the practice buffer.
function M.close_floats()
  for _, handle in ipairs(M._floats) do
    close_float(handle)
  end
  M._floats = {}
end

---Close all tracked floating windows and wipe scratch buffers.
---Use this for full session cleanup (quit, reset).
function M.teardown()
  M.close_floats()

  for _, buf in ipairs(M._scratch_bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
  M._scratch_bufs = {}
end

-- ---------------------------------------------------------------------------
-- 11–13. Extmark highlight helpers
-- ---------------------------------------------------------------------------

---Apply the NVTutorTarget extmark highlight to a range in a buffer.
---@param buf integer
---@param line integer   0-indexed line number
---@param col_start integer
---@param col_end integer
function M.set_target_highlight(buf, line, col_start, col_end)
  vim.api.nvim_buf_set_extmark(buf, M._ns, line, col_start, {
    end_col   = col_end,
    hl_group  = 'NVTutorTarget',
    priority  = 100,
  })
end

---Apply the NVTutorSuccess extmark highlight to a range in a buffer.
---@param buf integer
---@param line integer   0-indexed line number
---@param col_start integer
---@param col_end integer
function M.set_success_highlight(buf, line, col_start, col_end)
  vim.api.nvim_buf_set_extmark(buf, M._ns, line, col_start, {
    end_col   = col_end,
    hl_group  = 'NVTutorSuccess',
    priority  = 100,
  })
end

---Remove all NVTutor extmarks from a buffer.
---@param buf integer
function M.clear_highlights(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, M._ns, 0, -1)
  end
end

return M
