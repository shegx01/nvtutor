local h = require('nvtutor.chapters.helpers')
local M = {}

M.title = 'Precision Movement'
M.description = 'Master character-level navigation with find, till, and line-boundary motions.'

-- ─── shared buffer content ────────────────────────────────────────────────────

local find_lines = {
  'The function returns an error if the argument is nil.',
  'Call greet("world") to print a friendly message.',
  'Set timeout=30 and retry=true before running the job.',
  'Extract the final token after the last colon: done.',
  'Replace every semicolon; then verify; the output.',
}

local compose_lines = {
  'local result = calculate(width, height, depth)',
  'print("error: " .. tostring(err))',
  'config.timeout = 30  -- seconds until retry',
  'local names = {"Alice", "Bob", "Charlie", "Dave"}',
  'return { status = "ok", data = payload }',
}

local boundary_lines = {
  '    function initialize(opts)',
  '        local cfg = opts or {}',
  '        cfg.debug = cfg.debug or false',
  '        return cfg',
  '    end',
  '',
  '    local result = initialize({ debug = true })',
}

-- ─── Lesson 1 — Find and Till (f, F, t, T) ───────────────────────────────────

local lesson1 = {
  title = 'Find and Till',
  explanation = {
    'f{char}  — move forward to the next occurrence of {char} on the current line.',
    'F{char}  — move backward to the previous occurrence of {char}.',
    't{char}  — move forward, stopping one cell BEFORE {char} (till).',
    'T{char}  — move backward, stopping one cell AFTER {char}.',
    '',
    '; repeats the last f/F/t/T forward.  , repeats it backward.',
    '',
    'These motions stay on the current line — they never jump to another line.',
  },
  challenges = {
    -- 1. f forward to a character
    h.movement({
      command = 'f',
      instruction = 'Line 1: cursor is at column 0. Jump to the "e" in "error" using f.',
      lines = find_lines,
      from = { 1, 0 },
      to   = { 1, 19 },   -- 'e' of 'error' — "The function returns an e..."
      optimal = 2,         -- fe
      hint = 'fe finds the first "e" after the cursor. Use ; to advance to subsequent matches.',
    }),
    -- 2. F backward to a character
    h.movement({
      command = 'F',
      instruction = 'Line 2: cursor starts at end of "world")". Jump back to the opening "(" with F.',
      lines = find_lines,
      from = { 2, 24 },   -- positioned on the closing ')'
      to   = { 2, 12 },   -- opening '('
      optimal = 2,         -- F(
      hint = 'F( searches backward on the same line for "(".',
    }),
    -- 3. t forward (till, stop before char)
    h.movement({
      command = 't',
      instruction = 'Line 3: cursor is at column 0. Move to just before the "=" in "timeout=30" using t.',
      lines = find_lines,
      from = { 3, 0 },
      to   = { 3, 11 },   -- one before '=' in "timeout=30"  (col 12 is '=')
      optimal = 2,         -- t=
      hint = 't= stops the cursor one character BEFORE the "=" sign.',
    }),
    -- 4. T backward (till, stop after char)
    h.movement({
      command = 'T',
      instruction = 'Line 4: cursor is at the period at the end. Move back to just after the ":" with T.',
      lines = find_lines,
      from = { 4, 53 },   -- period at the end
      to   = { 4, 45 },   -- one after ':' (col 44 is ':')
      optimal = 2,         -- T:
      hint = 'T: stops one character AFTER the ":" when searching backward.',
    }),
    -- 5. Chaining ; to repeat
    h.movement({
      command = 'f',
      instruction = 'Line 5: cursor at column 0. Jump to the THIRD semicolon using f and ;.',
      lines = find_lines,
      from = { 5, 0 },
      to   = { 5, 37 },   -- third ';'  ("Replace every semicolon; then verify; the output.")
      optimal = 4,         -- f;;;
      hint = 'Press f; once to land on the first ";", then ; twice to advance to the third.',
    }),
  },
}

-- ─── Lesson 2 — Vim Language with Find and Till (df, ct, etc.) ───────────────

local lesson2 = {
  title = 'Vim Language with Find and Till',
  explanation = {
    'Find and till motions compose with verbs just like w or e.',
    '',
    'df{c}  — delete forward through (and including) the character {c}.',
    'dt{c}  — delete forward up to (but not including) {c}.',
    'cf{c}  — change through {c} (delete + enter Insert mode).',
    'ct{c}  — change up to {c}.',
    'yf{c}  — yank through {c}.',
    '',
    'Capital F/T variants work the same way but move backward.',
  },
  challenges = {
    -- 1. dt to delete up to a character
    h.vim_language({
      command = 'dt',
      instruction = 'Line 1: cursor on "r" of "result". Delete from "result" up to (not including) the "(" with dt(.',
      lines = compose_lines,
      start = { 1, 6 },    -- 'r' of 'result'
      expected = {
        'local (width, height, depth)',
        'print("error: " .. tostring(err))',
        'config.timeout = 30  -- seconds until retry',
        'local names = {"Alice", "Bob", "Charlie", "Dave"}',
        'return { status = "ok", data = payload }',
      },
      optimal = 3,          -- dt(
      hint = 'dt( deletes everything from the cursor up to but not including "(".',
    }),
    -- 2. df to delete through a character
    h.vim_language({
      command = 'df',
      instruction = 'Line 2: cursor on the opening quote. Delete through the closing quote of "error: " with df".',
      lines = compose_lines,
      start = { 2, 6 },    -- opening '"' of '"error: "'
      expected = {
        'local result = calculate(width, height, depth)',
        'print( .. tostring(err))',
        'config.timeout = 30  -- seconds until retry',
        'local names = {"Alice", "Bob", "Charlie", "Dave"}',
        'return { status = "ok", data = payload }',
      },
      optimal = 3,          -- df"  (lands on second '"', df" deletes through it)
      hint = 'df" deletes from the cursor through the next occurrence of the double-quote.',
    }),
    -- 3. ct to change up to a character
    h.vim_language({
      command = 'ct',
      instruction = 'Line 3: cursor is on "t" of "timeout". Change up to "=" so you can type a new key, using ct=.',
      lines = compose_lines,
      start = { 3, 7 },    -- 't' of 'timeout'
      expected = {
        'local result = calculate(width, height, depth)',
        'print("error: " .. tostring(err))',
        'config.deadline = 30  -- seconds until retry',
        'local names = {"Alice", "Bob", "Charlie", "Dave"}',
        'return { status = "ok", data = payload }',
      },
      optimal = 11,         -- ct= then type "deadline"
      hint = 'ct= removes text before "=" and leaves you in Insert mode. Type "deadline" then Esc.',
    }),
    -- 4. cf to change through a character
    h.vim_language({
      command = 'cf',
      instruction = 'Line 4: cursor on "A" of "Alice". Change through the closing quote with cf" to rename to "Eve".',
      lines = compose_lines,
      start = { 4, 15 },   -- 'A' of '"Alice"'
      expected = {
        'local result = calculate(width, height, depth)',
        'print("error: " .. tostring(err))',
        'config.timeout = 30  -- seconds until retry',
        'local names = {"Eve", "Bob", "Charlie", "Dave"}',
        'return { status = "ok", data = payload }',
      },
      optimal = 7,          -- cf" then type Eve
      hint = 'cf" deletes through the closing quote and puts you in Insert mode. Type Eve then ".',
    }),
    -- 5. yf to yank through a character
    h.vim_language({
      command = 'yf',
      instruction = 'Line 5: cursor on "s" of "status". Yank through the closing quote with yf", then paste after "data = " to duplicate the key.',
      lines = compose_lines,
      start = { 5, 10 },   -- 's' of '"status"'
      expected = {
        'local result = calculate(width, height, depth)',
        'print("error: " .. tostring(err))',
        'config.timeout = 30  -- seconds until retry',
        'local names = {"Alice", "Bob", "Charlie", "Dave"}',
        'return { status = "ok", data = "status" }',
      },
      optimal = 10,         -- yf" then navigate to position and p
      hint = 'yf" yanks from cursor through the closing quote. Move to the target position with w or f, then p.',
    }),
  },
}

-- ─── Lesson 3 — Start and End of Line (0, ^, $) ──────────────────────────────

local lesson3 = {
  title = 'Start and End of Line',
  explanation = {
    '0  — jump to column 0 (the very first character, even if it is whitespace).',
    '^  — jump to the first NON-WHITESPACE character on the line.',
    '$  — jump to the last character on the line.',
    '',
    'Composing with verbs:',
    '  d0  — delete from cursor back to column 0.',
    '  d^  — delete from cursor back to the first non-blank.',
    '  d$  — delete from cursor to end of line (same as D).',
    '  c$  — change to end of line (same as C).',
  },
  challenges = {
    -- 1. 0 to column zero
    h.movement({
      command = '0',
      instruction = 'Line 1: cursor is somewhere in the middle. Jump to column 0 (start of line) with 0.',
      lines = boundary_lines,
      from = { 1, 20 },
      to   = { 1, 0 },
      optimal = 1,
      hint = '0 always jumps to the very first column, regardless of whitespace.',
    }),
    -- 2. ^ to first non-blank
    h.movement({
      command = '^',
      instruction = 'Line 2: cursor is at the end. Move to the first non-whitespace character with ^.',
      lines = boundary_lines,
      from = { 2, 26 },
      to   = { 2, 8 },    -- 'l' of 'local' after 8 spaces
      optimal = 1,
      hint = '^ skips leading spaces/tabs and lands on the first real character.',
    }),
    -- 3. $ to end of line
    h.movement({
      command = '$',
      instruction = 'Line 3: cursor is at the start. Move to the last character on the line with $.',
      lines = boundary_lines,
      from = { 3, 8 },
      to   = { 3, 35 },   -- 'e' at end of "        cfg.debug = cfg.debug or false"
      optimal = 1,
      hint = '$ always moves to the last character (not past it).',
    }),
    -- 4. d$ to delete to end of line
    h.vim_language({
      command = 'd$',
      instruction = 'Line 3: cursor is on the space before "or false". Delete to end of line with d$.',
      lines = boundary_lines,
      start = { 3, 27 },   -- space before 'or'
      expected = {
        '    function initialize(opts)',
        '        local cfg = opts or {}',
        '        cfg.debug =',
        '        return cfg',
        '    end',
        '',
        '    local result = initialize({ debug = true })',
      },
      optimal = 2,
      hint = 'd$ deletes from the cursor through the end of the line.',
    }),
    -- 5. c^ to change from first non-blank to cursor
    h.vim_language({
      command = 'd^',
      instruction = 'Line 7: cursor is on "r" of "result". Delete from cursor back to the first non-blank with d^.',
      lines = boundary_lines,
      start = { 7, 10 },   -- 'r' of 'result'
      expected = {
        '    function initialize(opts)',
        '        local cfg = opts or {}',
        '        cfg.debug = cfg.debug or false',
        '        return cfg',
        '    end',
        '',
        'result = initialize({ debug = true })',
      },
      optimal = 2,
      hint = 'd^ deletes from the cursor back to (but not including) the first non-blank character.',
    }),
  },
}

M.lessons = { lesson1, lesson2, lesson3 }

return M
