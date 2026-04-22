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
      instruction = 'Jump to the "r" in "returns" using fr',
      lines = find_lines,
      from = { 1, 0 },
      to   = { 1, 13 },   -- 'r' of 'returns'
      optimal = 2,         -- fr
      hint = 'fr finds the first "r" after the cursor.',
    }),
    -- 2. F backward to a character
    h.movement({
      command = 'F',
      instruction = 'Jump back to the opening "(" with F(',
      lines = find_lines,
      from = { 2, 18 },   -- closing ')' in greet("world")
      to   = { 2, 10 },   -- opening '(' in greet(
      optimal = 2,         -- F(
      hint = 'F( searches backward on the same line for "(".',
    }),
    -- 3. t forward (till, stop before char)
    h.movement({
      command = 't',
      instruction = 'Move to just before the "=" in "timeout=30" using t=',
      lines = find_lines,
      from = { 3, 0 },
      to   = { 3, 10 },   -- one before '=' ("timeout=30": t=4,i=5,m=6,e=7,o=8,u=9,t=10,=11)
      optimal = 2,         -- t=
      hint = 't= stops the cursor one character BEFORE the "=" sign.',
    }),
    -- 4. T backward (till, stop after char)
    h.movement({
      command = 'T',
      instruction = 'Move back to just after the ":" using T:',
      lines = find_lines,
      from = { 4, 50 },   -- period at end of "done."
      to   = { 4, 45 },   -- one after ':' ("colon: done." — colon is at col 44)
      optimal = 2,         -- T:
      hint = 'T: stops one character AFTER the ":" when searching backward.',
    }),
    -- 5. Chaining ; to repeat
    h.movement({
      command = 'f',
      instruction = 'Jump to the second semicolon using f; then ;',
      lines = find_lines,
      from = { 5, 0 },
      to   = { 5, 36 },   -- second ';' in "then verify; the output." (col 23 and 36)
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
      instruction = 'Delete "result = calculate" up to the "(" with dt(',
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
      instruction = 'Delete "error: " including its closing quote using df"',
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
      instruction = 'Change "timeout" to "deadline" using ct= then type the new key name',
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
      instruction = 'Rename "Alice" to "Eve" using cf" then type the new name and closing quote',
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
      instruction = 'Delete the value "ok" up to the comma using dt,',
      lines = compose_lines,
      start = { 5, 19 },   -- 'o' of '"ok"' (col 19 in 'return { status = "ok", ...}')
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
      instruction = 'Jump to column 0 (start of line) with 0',
      lines = boundary_lines,
      from = { 1, 20 },
      to   = { 1, 0 },
      optimal = 1,
      hint = '0 always jumps to the very first column, regardless of whitespace.',
    }),
    -- 2. ^ to first non-blank
    h.movement({
      command = '^',
      instruction = 'Move to the first non-whitespace character with ^',
      lines = boundary_lines,
      from = { 2, 26 },
      to   = { 2, 8 },    -- 'l' of 'local' after 8 spaces
      optimal = 1,
      hint = '^ skips leading spaces/tabs and lands on the first real character.',
    }),
    -- 3. $ to end of line
    h.movement({
      command = '$',
      instruction = 'Move to the last character on the line with $',
      lines = boundary_lines,
      from = { 3, 8 },
      to   = { 3, 37 },   -- 'e' at end of "        cfg.debug = cfg.debug or false" (38 chars, last is col 37)
      optimal = 1,
      hint = '$ always moves to the last character (not past it).',
    }),
    -- 4. d$ to delete to end of line
    h.vim_language({
      command = 'd$',
      instruction = 'Delete from the cursor to end of line with d$',
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
      instruction = 'Delete "local " before "result" using d^',
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

-- ─── Lesson 4 — Repeat Find Motions (;, ,) ───────────────────────────────────

local repeat_find_lines = {
  'local alpha = activate(args, allow_all)',
  'call abort() after any available action',
  'attach agents; advance and await approval',
}

local lesson4 = {
  title = 'Repeat Find Motions',
  description = 'Advance or reverse through find targets without retyping the search.',
  advanced = true,
  explanation = {
    ';  — repeat the last f/F/t/T in the same direction.',
    ',  — repeat the last f/F/t/T in the opposite direction.',
    '',
    'After fa, press ; to jump to the next "a" on the line.',
    'Press , to step back to the previous "a".',
    '',
    'Works with f, F, t, and T — the repeat always knows the original direction.',
  },
  challenges = {
    -- 1. ; advances to next match
    h.movement({
      command = ';',
      instruction = 'Reach the second "a" on the line using fa then ;',
      lines = repeat_find_lines,
      from = { 1, 0 },
      to   = { 1, 6 },    -- 'a' in "alpha" (second 'a' on line)
      optimal = 3,          -- f a ;
      hint = 'fa finds the first "a" at col 3. ; repeats to the next "a" at col 6.',
      optimal_solution = 'fa;',
    }),
    -- 2. , reverses back
    h.movement({
      command = ',',
      instruction = 'Go to the third "a", then step back to the second using ,',
      lines = repeat_find_lines,
      from = { 1, 0 },
      to   = { 1, 6 },    -- back to second 'a' after fa;;,
      optimal = 5,          -- f a ; ; ,
      hint = 'fa;; reaches the third "a". Then , reverses one step back.',
      optimal_solution = 'fa;;,',
    }),
    -- 3. Chain ; across a line
    h.movement({
      command = ';',
      instruction = 'Reach the third "a" on line 2 using fa then ;;',
      lines = repeat_find_lines,
      from = { 2, 0 },
      to   = { 2, 13 },   -- 'call abort() after any...' — a(1),a(5),a(13)='a' of "after"
      optimal = 4,          -- f a ; ;
      hint = 'Each ; repeats the same find one step forward along the line.',
      optimal_solution = 'fa;;',
    }),
  },
}

-- ─── Lesson 5 — The cgn + Dot Loop ───────────────────────────────────────────

local cgn_lines = {
  'var count = 0',
  'var name  = "world"',
  'var total = var_count + var_offset',
  'console.log(var, count)',
}

local lesson5 = {
  title = 'The cgn + Dot Loop',
  description = 'Search, change the match, then dot-repeat to replace every occurrence.',
  advanced = true,
  explanation = {
    'cgn  — change the next search match (enter Insert mode over it).',
    '',
    'Workflow:',
    '  1. /pattern<CR>  — set the search register.',
    '  2. cgn           — delete the match and enter Insert mode.',
    '  3. Type replacement text, then Esc.',
    '  4. .             — repeat: find next match and apply the same change.',
    '',
    'Each . applies the "delete match + insert text" operation to the next hit.',
    'Skip a match by pressing n instead of . to advance without changing.',
  },
  challenges = {
    -- 1. cgn to change the first match
    h.vim_language({
      command = 'cgn',
      instruction = 'Search /var then cgn to change the first "var" to "let"',
      lines = cgn_lines,
      start = { 1, 0 },
      expected = {
        'let count = 0',
        'var name  = "world"',
        'var total = var_count + var_offset',
        'console.log(var, count)',
      },
      optimal = 12,   -- /var<CR>(5) cgn(3) let(3) Esc(1)
      hint = '/var<CR> sets the search. cgn deletes the first match. Type "let" then Esc.',
      optimal_solution = '/var\rcgnlet\27',
    }),
    -- 2. . to dot-repeat cgn replacement
    h.vim_language({
      command = '.',
      instruction = 'After changing first "var" to "let" with cgn, press . to change the next',
      lines = {
        'let count = 0',
        'var name  = "world"',
        'var total = var_count + var_offset',
        'console.log(var, count)',
      },
      start = { 1, 0 },
      expected = {
        'let count = 0',
        'let name  = "world"',
        'var total = var_count + var_offset',
        'console.log(var, count)',
      },
      optimal = 1,
      hint = '. repeats the cgn change on the next occurrence of the search pattern.',
    }),
    -- 3. Open-ended: use /var cgn + dot to replace all standalone "var" occurrences
    h.vim_language({
      command = '.',
      instruction = 'Change all standalone "var" to "let" using /var, cgn, Esc, then . twice',
      lines = cgn_lines,
      start = { 1, 0 },
      expected = {
        'let count = 0',
        'let name  = "world"',
        'var total = var_count + var_offset',
        'console.log(let, count)',
      },
      optimal = 14,   -- /var<CR> cgn let <Esc> . .
      check_lines = { 1, 2, 4 },
      hint = '/var<CR> searches for "var" (not whole-word). cgn then dot chains replacements. n skips compound tokens.',
      optimal_solution = '/var\rcgnlet\27..',
    }),
  },
}

M.lessons = { lesson1, lesson2, lesson3, lesson4, lesson5 }

return M
