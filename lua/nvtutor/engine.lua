local M = {}

-- Lazy require to avoid potential circular dependency
local function ui()
  return require('nvtutor.ui')
end

-- Module-level state shared with init.lua via require
M._state = {
  keystroke_count = 0,
  start_time = nil,
  on_key_id = nil,
  active_challenge = nil,
  completion_cb = nil,
}

---Start counting keystrokes using vim.on_key()
---@param challenge_def table
function M.start_counting(challenge_def)
  M._state.keystroke_count = 0
  M._state.on_key_id = vim.on_key(function(_key, typed)
    -- Only count keys the user actually typed
    if typed and #typed > 0 then
      M._state.keystroke_count = M._state.keystroke_count + 1
    elseif challenge_def.count_macro_keys and vim.fn.reg_executing() ~= '' then
      -- For Ch8 macro challenges, also count replayed keys
      M._state.keystroke_count = M._state.keystroke_count + 1
    end
  end)
end

---Stop counting keystrokes
function M.stop_counting()
  if M._state.on_key_id then
    vim.on_key(nil, M._state.on_key_id)
    M._state.on_key_id = nil
  end
end

---Compare buffer lines, optionally only checking specific lines
---@param actual string[]
---@param expected string[]
---@param check_lines? number[]
---@return boolean
function M.lines_match(actual, expected, check_lines)
  if check_lines then
    for _, ln in ipairs(check_lines) do
      local a = actual[ln] and actual[ln]:gsub('%s+$', '') or ''
      local e = expected[ln] and expected[ln]:gsub('%s+$', '') or ''
      if a ~= e then
        return false
      end
    end
    return true
  end

  if #actual ~= #expected then
    return false
  end
  for i = 1, #expected do
    local a = actual[i]:gsub('%s+$', '')
    local e = expected[i]:gsub('%s+$', '')
    if a ~= e then
      return false
    end
  end
  return true
end

---Check if visual selection matches target
---@param vstart table getpos("'<") result
---@param vend table getpos("'>") result
---@param target table { start_line, start_col, end_line, end_col }
---@return boolean
function M.selection_matches(vstart, vend, target)
  -- getpos returns {bufnum, lnum, col, off} where col is 1-indexed
  -- Our target uses 0-indexed columns (matching nvim_win_set_cursor)
  local sl = vstart[2]
  local el = vend[2]

  -- In Visual Line mode (V), only the lines matter — columns are irrelevant
  local mode = vim.api.nvim_get_mode().mode
  if mode == 'V' then
    return sl == target.start_line and el == target.end_line
  end

  -- Character and Block visual: check exact columns too
  local sc = vstart[3] - 1  -- convert to 0-indexed
  local ec = vend[3] - 1
  return sl == target.start_line and sc == target.start_col
     and el == target.end_line and ec == target.end_col
end

---Set up the practice buffer for a challenge
---@param buf number
---@param challenge_def table
---@param win? number  explicit window handle showing buf (falls back to current window)
function M.setup_buffer(buf, challenge_def, win)
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, challenge_def.buffer_lines)

  -- Set modifiable based on challenge type
  local editable_types = { editing = true, vim_language = true, power = true }
  vim.api.nvim_set_option_value('modifiable', editable_types[challenge_def.type] or false, { buf = buf })

  -- Configure the practice window for clear cursor visibility
  local target_win = (win and vim.api.nvim_win_is_valid(win)) and win or 0
  vim.api.nvim_set_option_value('cursorline', true, { win = target_win })
  vim.api.nvim_set_option_value('number', true, { win = target_win })
  vim.api.nvim_set_option_value('relativenumber', true, { win = target_win })
  vim.api.nvim_set_option_value('signcolumn', 'no', { win = target_win })
  -- Scroll offset keeps the cursor away from the very top/bottom edge
  vim.api.nvim_set_option_value('scrolloff', 3, { win = target_win })

  -- Position cursor
  local line = challenge_def.start_pos[1]
  local col = challenge_def.start_pos[2]
  vim.api.nvim_win_set_cursor(target_win, { line, col })

  -- Highlight target
  ui().clear_highlights(buf)
  if challenge_def.target then
    if challenge_def.target.line then
      -- Single position target (movement/search)
      ui().set_target_highlight(
        buf,
        challenge_def.target.line - 1, -- 0-indexed for extmarks
        challenge_def.target.col or 0,
        (challenge_def.target.col or 0) + 1
      )
    elseif challenge_def.target.start_line then
      -- Region target (visual/editing)
      for ln = challenge_def.target.start_line, challenge_def.target.end_line do
        local sc = ln == challenge_def.target.start_line and (challenge_def.target.start_col - 1) or 0
        local ec = ln == challenge_def.target.end_line and challenge_def.target.end_col or -1
        if ec == -1 then
          ec = #(challenge_def.buffer_lines[ln] or '')
        end
        ui().set_target_highlight(buf, ln - 1, sc, ec)
      end
    end
  end
end

---Restore buffer to initial state for retry
---@param buf number
---@param challenge_def table
---@param win? number  explicit window handle (forwarded to setup_buffer)
function M.reset_buffer(buf, challenge_def, win)
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  M.setup_buffer(buf, challenge_def, win)
end

---Validator factories for each challenge type
M.validators = {
  movement = function(challenge_def, buf, on_complete)
    return {
      events = { 'CursorMoved' },
      check = function()
        local pos = vim.api.nvim_win_get_cursor(0)
        if pos[1] == challenge_def.target.line and pos[2] == challenge_def.target.col then
          on_complete()
        end
      end,
    }
  end,

  editing = function(challenge_def, buf, on_complete)
    return {
      events = { 'TextChanged', 'TextChangedI' },
      check = function()
        vim.schedule(function()
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          if M.lines_match(lines, challenge_def.expected_lines, challenge_def.check_lines) then
            on_complete()
          end
        end)
      end,
    }
  end,

  visual = function(challenge_def, buf, on_complete)
    local function check()
      vim.schedule(function()
        -- Only check while in a visual mode (v, V, or Ctrl-V)
        local mode = vim.api.nvim_get_mode().mode
        if not mode:match('^[vV\22]') then return end
        -- Guard: only for practice buffer
        if vim.api.nvim_get_current_buf() ~= buf then return end
        -- Guard: buffer unchanged
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if not M.lines_match(lines, challenge_def.buffer_lines) then
          return
        end
        -- getpos('v') = visual start, getpos('.') = cursor (visual end)
        local vstart = vim.fn.getpos('v')
        local vend = vim.fn.getpos('.')
        -- Ensure start <= end (user might select backwards)
        if vstart[2] > vend[2] or (vstart[2] == vend[2] and vstart[3] > vend[3]) then
          vstart, vend = vend, vstart
        end
        if M.selection_matches(vstart, vend, challenge_def.target) then
          on_complete()
        end
      end)
    end
    -- Two autocmds: ModeChanged catches the initial v/V press (no cursor
    -- movement yet), CursorMoved catches subsequent selection extensions.
    return {
      multi_autocmds = {
        { event = 'ModeChanged', pattern = 'n:*', callback = check },
        { event = 'CursorMoved', buffer = buf,    callback = check },
      },
    }
  end,

  vim_language = function(challenge_def, buf, on_complete)
    return {
      events = { 'TextChanged', 'TextChangedI' },
      check = function()
        vim.schedule(function()
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          if M.lines_match(lines, challenge_def.expected_lines, challenge_def.check_lines) then
            on_complete()
          end
        end)
      end,
    }
  end,

  search = function(challenge_def, buf, on_complete)
    return {
      events = { 'CursorMoved' },
      check = function()
        local pos = vim.api.nvim_win_get_cursor(0)
        if pos[1] == challenge_def.target.line and pos[2] == challenge_def.target.col then
          on_complete()
        end
      end,
    }
  end,

  power = function(challenge_def, buf, on_complete)
    return {
      events = { 'TextChanged', 'TextChangedI' },
      check = function()
        vim.schedule(function()
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          if M.lines_match(lines, challenge_def.expected_lines, challenge_def.check_lines) then
            on_complete()
          end
        end)
      end,
    }
  end,
}

---Start a challenge
---@param buf number practice buffer
---@param win number  window handle that is showing the practice buffer
---@param challenge_def table challenge definition
---@param challenge_num number current challenge number (1-indexed)
---@param total number total challenges in lesson
---@param on_done function callback({keystrokes, time, tier, skipped})
function M.start_challenge(buf, win, challenge_def, challenge_num, total, on_done)
  M._state.active_challenge = challenge_def
  M._state.completion_cb = on_done

  -- Set up buffer using the explicit window handle
  M.setup_buffer(buf, challenge_def, win)

  -- Show challenge prompt
  ui().show_challenge_prompt(challenge_num, total, challenge_def.instruction)

  -- Start counting
  M._state.keystroke_count = 0
  M._state.start_time = vim.loop.hrtime()
  M.start_counting(challenge_def)

  -- Set up retry/skip keybindings
  vim.keymap.set('n', '<C-l>', function()
    M.stop_counting()
    M.reset_buffer(buf, challenge_def, win)
    M._state.keystroke_count = 0
    M._state.start_time = vim.loop.hrtime()
    M.start_counting(challenge_def)
  end, { buffer = buf, nowait = true, desc = 'NVTutor: Retry challenge' })

  vim.keymap.set('n', '<C-n>', function()
    M._finish_challenge(buf, true)
  end, { buffer = buf, nowait = true, desc = 'NVTutor: Skip challenge' })

  -- Hint toggle — Ctrl-H shows/hides the hint
  if challenge_def.hint then
    vim.keymap.set('n', '<C-h>', function()
      ui().toggle_hint(challenge_def.hint)
    end, { buffer = buf, nowait = true, desc = 'NVTutor: Toggle hint' })
  end

  -- Create completion handler
  local completed = false
  local function on_complete()
    if completed then return end
    completed = true
    M._finish_challenge(buf, false)
  end

  -- Register validator
  local augroup = vim.api.nvim_create_augroup('NVTutorChallenge', { clear = true })
  local validator_factory = M.validators[challenge_def.type]
  if not validator_factory then
    vim.notify('Unknown challenge type: ' .. challenge_def.type, vim.log.levels.ERROR)
    return
  end

  local validator = validator_factory(challenge_def, buf, on_complete)

  if validator.multi_autocmds then
    -- Visual validator: needs separate autocmds with different opts
    for _, spec in ipairs(validator.multi_autocmds) do
      local opts = { group = augroup, callback = spec.callback }
      if spec.buffer then opts.buffer = spec.buffer end
      if spec.pattern then opts.pattern = spec.pattern end
      vim.api.nvim_create_autocmd(spec.event, opts)
    end
  else
    -- Standard validators: single event list with shared opts
    local au_opts = {
      group = augroup,
      buffer = buf,
      callback = validator.check,
    }
    if validator.pattern then
      au_opts.buffer = nil
      au_opts.pattern = validator.pattern
    end
    for _, event in ipairs(validator.events) do
      vim.api.nvim_create_autocmd(event, vim.tbl_extend('force', {}, au_opts))
    end
  end
end

---Finish a challenge (complete or skip)
---@param buf number
---@param skipped boolean
function M._finish_challenge(buf, skipped)
  M.stop_counting()

  -- Force back to normal mode — the user may still be in insert/visual mode
  vim.cmd('noautocmd stopinsert')
  -- Also escape visual mode if active
  local mode = vim.api.nvim_get_mode().mode
  if mode:match('^[vVsS\22]') then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
  end

  -- Clean up autocmds
  pcall(vim.api.nvim_del_augroup_by_name, 'NVTutorChallenge')

  -- Clean up keymaps
  pcall(vim.keymap.del, 'n', '<C-l>', { buffer = buf })
  pcall(vim.keymap.del, 'n', '<C-h>', { buffer = buf })
  pcall(vim.keymap.del, 'n', '<C-n>', { buffer = buf })

  -- Dismiss hint if showing
  ui().close_hint()

  -- Close challenge prompt (preserve practice buffer)
  ui().close_floats()

  local elapsed = (vim.loop.hrtime() - M._state.start_time) / 1e9
  local keystrokes = M._state.keystroke_count
  local challenge_def = M._state.active_challenge

  if skipped then
    if M._state.completion_cb then
      M._state.completion_cb({ skipped = true })
    end
    return
  end

  -- Calculate tier
  local progress = require('nvtutor.progress')
  local tier = progress.get_mastery_tier(
    keystrokes,
    challenge_def.optimal_keystrokes,
    elapsed,
    challenge_def.optimal_time
  )

  -- Show success highlight on target line
  if challenge_def.target and challenge_def.target.line then
    local target_ln = challenge_def.target.line - 1
    local line_text = vim.api.nvim_buf_get_lines(buf, target_ln, target_ln + 1, false)[1] or ''
    ui().set_success_highlight(buf, target_ln, 0, #line_text)
  end

  -- Show feedback (with optional optimal solution text)
  ui().show_feedback(true, tier, keystrokes, challenge_def.optimal_keystrokes, elapsed, challenge_def.optimal_solution)

  -- Callback (include whether optimal_solution was shown for timer adjustment)
  if M._state.completion_cb then
    M._state.completion_cb({
      skipped = false,
      keystrokes = keystrokes,
      time = elapsed,
      tier = tier,
      has_optimal = challenge_def.optimal_solution ~= nil,
    })
  end
end

return M
