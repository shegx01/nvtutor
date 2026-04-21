-- Challenge builder factories to reduce authoring boilerplate.
-- Each function returns a plain Lua table (preserving the declarative principle).

local M = {}

-- Reusable default prose for movement challenges
M.default_prose = {
  'The quick brown fox jumps over the lazy dog.',
  'Pack my box with five dozen liquor jugs.',
  'How vexingly quick daft zebras jump.',
  'The five boxing wizards jump quickly.',
  'Jinxed wizards pluck ivy from the big quilt.',
  'Bright vixens jump; dozy fowl quack.',
  'Waltz, bad nymph, for quick jigs vex.',
  'Sphinx of black quartz, judge my vow.',
  'Two driven jocks help fax my big quiz.',
  'The jay, pig, fox, zebra and my wolves quack!',
}

M.code_sample = {
  'function greet(name)',
  '  local message = "Hello, " .. name',
  '  print(message)',
  '  return message',
  'end',
  '',
  'local names = { "Alice", "Bob", "Charlie" }',
  'for _, name in ipairs(names) do',
  '  greet(name)',
  'end',
}

M.python_sample = {
  'def calculate_total(items):',
  '    total = 0',
  '    for item in items:',
  '        total += item.price',
  '    return total',
  '',
  'class ShoppingCart:',
  '    def __init__(self):',
  '        self.items = []',
  '',
  '    def add_item(self, item):',
  '        self.items.append(item)',
  '',
  '    def get_total(self):',
  '        return calculate_total(self.items)',
}

---Build a movement challenge
---@param opts table {command, instruction, lines?, from, to, optimal, time?, hint?}
---@return table
function M.movement(opts)
  return {
    type = 'movement',
    command = opts.command,
    instruction = opts.instruction,
    buffer_lines = opts.lines or M.default_prose,
    start_pos = opts.from,
    target = { line = opts.to[1], col = opts.to[2] },
    optimal_keystrokes = opts.optimal,
    optimal_time = opts.time or 5.0,
    hint = opts.hint,
  }
end

---Build an editing challenge
---@param opts table {command, instruction, lines, start, expected, optimal, time?, hint?, check_lines?}
---@return table
function M.editing(opts)
  return {
    type = 'editing',
    command = opts.command,
    instruction = opts.instruction,
    buffer_lines = opts.lines,
    start_pos = opts.start,
    target = opts.target,
    expected_lines = opts.expected,
    optimal_keystrokes = opts.optimal,
    optimal_time = opts.time or 5.0,
    hint = opts.hint,
    check_lines = opts.check_lines,
  }
end

---Build a visual mode challenge
---@param opts table {command, instruction, lines, start, target_region, optimal, time?, hint?}
---@return table
function M.visual(opts)
  -- Normalize target_region from { {line,col}, {line,col} } to named fields
  local region = opts.target_region
  local target
  if region then
    if region.start_line then
      -- Already in named format
      target = region
    elseif region[1] and region[2] then
      -- Array format: { {start_line, start_col}, {end_line, end_col} }
      target = {
        start_line = region[1][1],
        start_col  = region[1][2],
        end_line   = region[2][1],
        end_col    = region[2][2],
      }
    end
  end
  return {
    type = 'visual',
    command = opts.command,
    instruction = opts.instruction,
    buffer_lines = opts.lines,
    start_pos = opts.start,
    target = target,
    optimal_keystrokes = opts.optimal,
    optimal_time = opts.time or 5.0,
    hint = opts.hint,
  }
end

---Build a vim language challenge
---@param opts table {command, instruction, lines, start, expected, optimal, time?, hint?, check_lines?}
---@return table
function M.vim_language(opts)
  return {
    type = 'vim_language',
    command = opts.command,
    instruction = opts.instruction,
    buffer_lines = opts.lines,
    start_pos = opts.start,
    expected_lines = opts.expected,
    optimal_keystrokes = opts.optimal,
    optimal_time = opts.time or 5.0,
    hint = opts.hint,
    check_lines = opts.check_lines,
  }
end

---Build a search/find challenge
---@param opts table {command, instruction, lines?, from, to, optimal, time?, hint?}
---@return table
function M.search(opts)
  return {
    type = 'search',
    command = opts.command,
    instruction = opts.instruction,
    buffer_lines = opts.lines or M.default_prose,
    start_pos = opts.from,
    target = { line = opts.to[1], col = opts.to[2] },
    optimal_keystrokes = opts.optimal,
    optimal_time = opts.time or 5.0,
    hint = opts.hint,
  }
end

---Build a power command challenge
---@param opts table {command, instruction, lines, start, expected, optimal, time?, hint?, count_macro_keys?, check_lines?}
---@return table
function M.power(opts)
  return {
    type = 'power',
    command = opts.command,
    instruction = opts.instruction,
    buffer_lines = opts.lines,
    start_pos = opts.start,
    expected_lines = opts.expected,
    optimal_keystrokes = opts.optimal,
    optimal_time = opts.time or 8.0,
    hint = opts.hint,
    count_macro_keys = opts.count_macro_keys,
    check_lines = opts.check_lines,
  }
end

return M
