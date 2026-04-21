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
      instruction = 'Line 1: jump to the "r" in "returns" using fr.',
      lines = find_lines,
      from = { 1, 0 },
      to   = { 1, 13 },   -- 'r' of 'returns'
      optimal = 2,         -- fr
      hint = 'fr finds the first "r" after the cursor.',
    }),
    -- 2. F backward to a character
    h.movement({
      command = 'F',
      instruction = 'Line 2: cursor is at the closing ")". Jump back to the opening "(" with F.',
      lines = find_lines,
      from = { 2, 18 },   -- closing ')' in greet("world")
      to   = { 2, 10 },   -- opening '(' in greet(
      optimal = 2,         -- F(
      hint = 'F( searches backward on the same line for "(".',
    }),
    -- 3. t forward (till, stop before char)
    h.movement({
      command = 't',
      instruction = 'Line 3: cursor is at column 0. Move to just before the "=" in "timeout=30" using t.',
      lines = find_lines,
      from = { 3, 0 },
      to   = { 3, 10 },   -- one before '=' ("timeout=30": t=4,i=5,m=6,e=7,o=8,u=9,t=10,=11)
      optimal = 2,         -- t=
      hint = 't= stops the cursor one character BEFORE the "=" sign.',
    }),
    -- 4. T backward (till, stop after char)
    h.movement({
      command = 'T',
      instruction = 'Line 4: cursor is at the period. Move back to just after the ":" with T.',
      lines = find_lines,
      from = { 4, 50 },   -- period at end of "done."
      to   = { 4, 43 },   -- one after ':' ("colon: done." — colon is at col 42)
      optimal = 2,         -- T:
      hint = 'T: stops one character AFTER the ":" when searching backward.',
    }),
    -- 5. Chaining ; to repeat
    h.movement({
      command = 'f',
      instruction = 'Line 5: jump to the SECOND semicolon using f; then ;.',
      lines = find_lines,
      from = { 5, 0 },
      to   = { 5, 35 },   -- second ';' in "then verify; the output."
      optimal = 3,         -- f;;
      hint = 'Press f; to land on the first ";", then ; to advance to the second.',
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
      optimal = 12,         -- ct=(3) + "deadline"(8) + Esc(1) = 12
      hint = 'ct= removes text before "=" and leaves you in Insert mode. Type "deadline" then Esc.',
    }),
    -- 4. cf to change through a character
    h.vim_language({
      command = 'cf',
      instruction = 'Line 4: cursor on "A" of "Alice". Change through the closing quote with cf" to rename to "Eve".',
      lines = compose_lines,
      start = { 4, 16 },   -- 'A' of '"Alice"' (col 15 is the opening quote)
      expected = {
        'local result = calculate(width, height, depth)',
        'print("error: " .. tostring(err))',
        'config.timeout = 30  -- seconds until retry',
        'local names = {"Eve", "Bob", "Charlie", "Dave"}',
        'return { status = "ok", data = payload }',
      },
      optimal = 8,          -- cf"(3) + Eve"(4) + Esc(1) = 8
      hint = 'cf" deletes through the closing quote and puts you in Insert mode. Type Eve" then Esc.',
    }),
    -- 5. dt to delete up to a character
    h.vim_language({
      command = 'dt',
      instruction = 'Line 5: cursor on "o" of "ok". Delete up to the comma with dt, to remove the status key.',
      lines = compose_lines,
      start = { 5, 11 },   -- 'o' of '"ok"'
      expected = {
        'local result = calculate(width, height, depth)',
        'print("error: " .. tostring(err))',
        'config.timeout = 30  -- seconds until retry',
        'local names = {"Alice", "Bob", "Charlie", "Dave"}',
        'return { status = ", data = payload }',
      },
      optimal = 3,          -- dt,
      hint = 'dt, deletes from cursor up to (but not including) the comma.',
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
      to   = { 3, 37 },   -- 'e' at end of "        cfg.debug = cfg.debug or false" (38 chars, last is col 37)
      optimal = 1,
      hint = '$ always moves to the last character (not past it).',
    }),
    -- 4. d$ to delete to end of line
    h.vim_language({
      command = 'd$',
      instruction = 'Line 3: cursor is on the space after "=". Delete to end of line with d$.',
      lines = boundary_lines,
      start = { 3, 20 },   -- space after '='
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
      hint = 'd$ deletes from the cursor through the end of the line. Also available as D.',
    }),
    -- 5. d^ to delete back to first non-blank
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
        '    result = initialize({ debug = true })',
      },
      optimal = 2,
      hint = 'd^ deletes from the cursor back to (but not including) the first non-blank character. Leading spaces are preserved.',
    }),
  },
}

M.lessons = { lesson1, lesson2, lesson3 }

return M
