local h = require('nvtutor.chapters.helpers')
local M = {}

M.title = 'Power Commands'
M.description = 'Turbocharge your editing with macros, the dot command, number operations, and more.'

-- ─── shared buffer content ────────────────────────────────────────────────────

local number_lines = {
  'local version   = 1',
  'local max_retry = 3',
  'local timeout   = 10',
  'local pool_size = 4',
  'local threshold = 100',
}

local macro_lines = {
  'const firstName = "alice"',
  'const lastName  = "bob"',
  'const cityName  = "chicago"',
  'const teamName  = "devs"',
  'const codeName  = "falcon"',
}

local bracket_lines = {
  'function process(data) {',
  '  if (data.valid) {',
  '    const result = transform(data.payload);',
  '    return [result, null];',
  '  } else {',
  '    return [null, new Error("invalid")];',
  '  }',
  '}',
  '',
  'const output = process({ valid: true, payload: 42 });',
}

local dot_lines = {
  'The API endpoint is http not https.',
  'The fallback URL uses http as well.',
  'All internal calls also use http for now.',
  'We must update every http reference before launch.',
}

local join_lines = {
  'const greeting =',
  '  "Hello, world!";',
  'const farewell =',
  '  "Goodbye, world!";',
  'const message =',
  '  greeting + " " + farewell;',
}

local case_lines = {
  'the quick brown fox',
  'JUMPS OVER THE LAZY DOG',
  'a Mixed Case Line Here',
  'another line to transform',
}

-- ─── Lesson 1 — Dealing With Numbers (Ctrl-a, Ctrl-x) ────────────────────────

local lesson1 = {
  title = 'Dealing With Numbers',
  explanation = {
    'Ctrl-a  — increment the number under (or nearest after) the cursor by 1.',
    'Ctrl-x  — decrement the number under the cursor by 1.',
    '',
    '{n}Ctrl-a  — increment by n  (e.g. 10<C-a> adds 10).',
    '{n}Ctrl-x  — decrement by n.',
    '',
    'Vim recognises decimal, hex (0x…), octal (0…), and binary (0b…) literals.',
    'The cursor does not need to be ON the digit — just before it on the same line.',
  },
  challenges = {
    -- 1. Ctrl-a increments by 1
    h.power({
      command = '<C-a>',
      instruction = 'Increment version from 1 to 2 with Ctrl-a',
      lines = number_lines,
      start = { 1, 6 },
      expected = {
        'local version   = 2',
        'local max_retry = 3',
        'local timeout   = 10',
        'local pool_size = 4',
        'local threshold = 100',
      },
      optimal = 1,
      hint = 'Ctrl-a finds the next number on the line and increments it.',
    }),
    -- 2. Ctrl-x decrements by 1
    h.power({
      command = '<C-x>',
      instruction = 'Decrement max_retry from 3 to 2 with Ctrl-x',
      lines = number_lines,
      start = { 2, 0 },
      expected = {
        'local version   = 1',
        'local max_retry = 2',
        'local timeout   = 10',
        'local pool_size = 4',
        'local threshold = 100',
      },
      optimal = 1,
      hint = 'Ctrl-x finds the next number on the line and decrements it.',
    }),
    -- 3. Count + Ctrl-a to add a larger amount
    h.power({
      command = '<C-a>',
      instruction = 'Increase timeout from 10 to 30 using 20 Ctrl-a',
      lines = number_lines,
      start = { 3, 0 },
      expected = {
        'local version   = 1',
        'local max_retry = 3',
        'local timeout   = 30',
        'local pool_size = 4',
        'local threshold = 100',
      },
      optimal = 3,   -- 2, 0, <C-a>
      hint = 'Prepend the count 20 before Ctrl-a: 20<C-a> adds 20 to the number.',
    }),
    -- 4. Count + Ctrl-x to subtract
    h.power({
      command = '<C-x>',
      instruction = 'Decrease threshold from 100 to 50 using 50 Ctrl-x',
      lines = number_lines,
      start = { 5, 0 },
      expected = {
        'local version   = 1',
        'local max_retry = 3',
        'local timeout   = 10',
        'local pool_size = 4',
        'local threshold = 50',
      },
      optimal = 3,   -- 5, 0, <C-x> = 3 keystrokes
      hint = '50<C-x> subtracts 50 from the number. Three keystrokes: 5, 0, Ctrl-x.',
    }),
    -- 5. Ctrl-a on pool_size with cursor before the digit
    h.power({
      command = '<C-a>',
      instruction = 'Increment pool_size from 4 to 5 with Ctrl-a',
      lines = number_lines,
      start = { 4, 6 },
      expected = {
        'local version   = 1',
        'local max_retry = 3',
        'local timeout   = 10',
        'local pool_size = 5',
        'local threshold = 100',
      },
      optimal = 1,
      hint = 'Ctrl-a searches rightward from the cursor on the same line for a number.',
    }),
  },
}

-- ─── Lesson 2 — Macros (q, @, @@) ────────────────────────────────────────────

local lesson2 = {
  title = 'Macros',
  explanation = {
    'q{reg}     — start recording a macro into register {reg} (a–z).',
    'q          — stop recording.',
    '@{reg}     — replay the macro stored in register {reg}.',
    '@@         — replay the last-used macro.',
    '{n}@{reg}  — replay the macro n times.',
    '',
    'Macros replay every keystroke you recorded: movements, edits, searches.',
    'Design your macro to leave the cursor ready for the NEXT repetition.',
  },
  challenges = {
    -- 1. Simple macro: capitalise first letter then advance
    h.power({
      command = 'q',
      instruction = 'Capitalise the first letter of each quoted word on lines 1-5 using a macro in register "a"',
      lines = macro_lines,
      start = { 1, 0 },
      expected = {
        'const firstName = "Alice"',
        'const lastName  = "Bob"',
        'const cityName  = "Chicago"',
        'const teamName  = "Devs"',
        'const codeName  = "Falcon"',
      },
      optimal = 16,   -- qa f" w ~ q  then 4@a
      count_macro_keys = true,
      hint = 'qa starts recording. f" moves to quote, w jumps inside, ~ toggles case. q stops. Then 4@a replays 4 times.',
    }),
    -- 2. Macro with substitution pattern
    h.power({
      command = 'q',
      instruction = 'Change "const" to "let" on all 5 lines using a macro in register "b"',
      lines = macro_lines,
      start = { 1, 0 },
      expected = {
        'let firstName = "alice"',
        'let lastName  = "bob"',
        'let cityName  = "chicago"',
        'let teamName  = "devs"',
        'let codeName  = "falcon"',
      },
      optimal = 17,   -- qb ^cw let <Esc> j q  then 4@b
      count_macro_keys = true,
      hint = 'qb starts recording. ^cw replaces the first word, type "let", Esc, then j. q stops. 4@b finishes the rest.',
    }),
    -- 3. @@ to replay last macro
    h.power({
      command = '@@',
      instruction = 'Run @a on line 1, then repeat on line 2 with @@',
      lines = macro_lines,
      start = { 1, 0 },
      expected = {
        'const firstName = "Alice"',
        'const lastName  = "Bob"',
        'const cityName  = "chicago"',
        'const teamName  = "devs"',
        'const codeName  = "falcon"',
      },
      optimal = 14,   -- qa f" w ~ j q  then @a @@
      count_macro_keys = true,
      hint = 'Record the macro with qa. Run @a on line 1, then @@ replays it on line 2 with two keystrokes.',
    }),
    -- 4. Counted macro replay
    h.power({
      command = '@',
      instruction = 'Append a semicolon to all 5 lines using a macro in register "c" with 5@c',
      lines = macro_lines,
      start = { 1, 0 },
      expected = {
        'const firstName = "alice";',
        'const lastName  = "bob";',
        'const cityName  = "chicago";',
        'const teamName  = "devs";',
        'const codeName  = "falcon";',
      },
      optimal = 11,   -- qc A ; <Esc> j q  then 5@c
      count_macro_keys = true,
      hint = 'qc records. A enters Insert at end, type ";", Esc, j moves down, q stops. 5@c runs it 5 times.',
    }),
    -- 5. Macro that inserts surrounding quotes
    h.power({
      command = 'q',
      instruction = 'Wrap the first word in backticks on all 5 lines using a macro in register "d"',
      lines = macro_lines,
      start = { 1, 0 },
      expected = {
        '`const` firstName = "alice"',
        '`const` lastName  = "bob"',
        '`const` cityName  = "chicago"',
        '`const` teamName  = "devs"',
        '`const` codeName  = "falcon"',
      },
      optimal = 16,   -- qd ^ i ` <Esc> ea ` <Esc> j q  then 4@d
      count_macro_keys = true,
      hint = 'qd ^ i ` Esc ea ` Esc j q records the macro. 4@d replays it for the remaining lines.',
    }),
  },
}

-- ─── Lesson 3 — Matching Brackets (%) ────────────────────────────────────────

local lesson3 = {
  title = 'Matching Brackets',
  explanation = {
    '%  — jump to the bracket/delimiter that matches the one under the cursor.',
    '',
    'Supported pairs: ()  {}  []',
    'Some plugins extend % to match HTML tags, do/end, if/end, etc.',
    '',
    'Useful workflows:',
    '  d%  — delete from cursor to the matching bracket (inclusive).',
    '  v%  — visually select from cursor to the matching bracket.',
    '',
    'If the cursor is NOT on a bracket, % jumps to the NEXT bracket on the line first.',
  },
  challenges = {
    -- 1. % from opening to closing paren
    h.movement({
      command = '%',
      instruction = 'Jump from the opening "{" to its matching closing "}" with %',
      lines = bracket_lines,
      from = { 1, 23 },   -- '{' at end of 'function process(data) {'
      to   = { 8, 0 },    -- matching '}' on line 8
      optimal = 1,
      hint = '% on an opening bracket jumps to the corresponding closing bracket.',
    }),
    -- 2. % from closing to opening
    h.movement({
      command = '%',
      instruction = 'Jump from the closing "}" back to the matching opening "{" on line 1 with %',
      lines = bracket_lines,
      from = { 8, 0 },
      to   = { 1, 23 },
      optimal = 1,
      hint = '% works in both directions — from closing bracket back to its opening.',
    }),
    -- 3. % on inner bracket
    h.movement({
      command = '%',
      instruction = 'Jump from the "(" after "if" to its matching ")" with %',
      lines = bracket_lines,
      from = { 2, 5 },    -- '(' in 'if (data.valid)'
      to   = { 2, 16 },   -- matching ')'
      optimal = 1,
      hint = '% jumps between matched pairs on the same line too.',
    }),
    -- 4. % on square bracket
    h.movement({
      command = '%',
      instruction = 'Jump from the opening "[" to the closing "]" in the return tuple with %',
      lines = bracket_lines,
      from = { 4, 11 },   -- '[' in 'return [result, null];'
      to   = { 4, 24 },   -- ']'
      optimal = 1,
      hint = '% works on [] as well as () and {}.',
    }),
    -- 5. d% to delete a block
    h.vim_language({
      command = 'd%',
      instruction = 'Delete the entire object literal with d%',
      lines = bracket_lines,
      start = { 10, 23 },  -- '{' in 'process({ valid: ... })'
      expected = {
        'function process(data) {',
        '  if (data.valid) {',
        '    const result = transform(data.payload);',
        '    return [result, null];',
        '  } else {',
        '    return [null, new Error("invalid")];',
        '  }',
        '}',
        '',
        'const output = process();',
      },
      optimal = 2,
      hint = 'd% deletes from the cursor (the "{") through its matching "}" inclusive.',
    }),
  },
}

-- ─── Lesson 4 — Dot Command (.) ───────────────────────────────────────────────

local lesson4 = {
  title = 'Dot Command',
  explanation = {
    '.  — repeat the last change at the current cursor position.',
    '',
    '"Change" means: anything that modified the buffer.',
    'Examples: dw, ciw, A<text><Esc>, x, r{char}, >>, etc.',
    '',
    'Workflow: make the change once, move to the next location, press ".".',
    'Combine . with n (or ;) to race through repeated edits.',
    '',
    'The dot command does NOT repeat motions — only the editing action.',
  },
  challenges = {
    -- 1. Append text with A then dot-repeat across lines
    h.power({
      command = '.',
      instruction = 'Append " -- checked" to lines 1-3 using A then j. to repeat',
      lines = {
        'validate(input)',
        'process(data)',
        'render(output)',
        'return result',
      },
      start = { 1, 0 },
      expected = {
        'validate(input) -- checked',
        'process(data) -- checked',
        'render(output) -- checked',
        'return result',
      },
      optimal = 17,   -- A(1) + " -- checked"(11) + Esc(1) + j.(2) + j.(2) = 17
      check_lines = { 1, 2, 3 },
      hint = 'A enters Insert at end of line. Type " -- checked" then Esc. j moves down, . repeats.',
    }),
    -- 2. Append semicolons with A then dot-repeat
    h.power({
      command = '.',
      instruction = 'Add a trailing semicolon to lines 2-4 using A; then j. to repeat',
      lines = {
        'const alpha = 1;',
        'const beta  = 2',
        'const gamma = 3',
        'const delta = 4',
      },
      start = { 2, 0 },
      expected = {
        'const alpha = 1;',
        'const beta  = 2;',
        'const gamma = 3;',
        'const delta = 4;',
      },
      optimal = 7,   -- A ; <Esc> j. j.
      hint = 'A moves to end of line and enters Insert. Type ";", Esc. Then j. repeats on the next line.',
    }),
    -- 3. Delete a trailing comment and dot-repeat
    h.power({
      command = '.',
      instruction = 'Delete " -- TODO" from each line using d$ then j. to repeat',
      lines = {
        'local alpha = 1 -- TODO',
        'local beta  = 2 -- TODO',
        'local gamma = 3 -- TODO',
      },
      start = { 1, 15 },   -- space before '-- TODO'
      expected = {
        'local alpha = 1',
        'local beta  = 2',
        'local gamma = 3',
      },
      optimal = 6,   -- d$ j. j.
      hint = 'd$ deletes to end of line. j moves to the next line. . repeats the d$ deletion.',
    }),
    -- 4. Indent a block and dot-repeat
    h.power({
      command = '.',
      instruction = 'Indent lines 2-4 by one level using >> then j. to repeat',
      lines = {
        'function foo() {',
        'const x = 1;',
        'const y = 2;',
        'const z = 3;',
        '}',
      },
      start = { 2, 0 },
      expected = {
        'function foo() {',
        '  const x = 1;',
        '  const y = 2;',
        '  const z = 3;',
        '}',
      },
      optimal = 6,   -- >>(2) j.(2) j.(2) = 6
      hint = '>> indents the current line. j. repeats on each subsequent line. Or use 3>> (3 keys).',
    }),
    -- 5. Replace character and dot-repeat
    h.power({
      command = '.',
      instruction = 'Replace the first "-" with "_" on each line using r_ then f-. to repeat',
      lines = {
        'my-module = require("my-module")',
        'my-helper = require("my-helper")',
        'my-config = require("my-config")',
        'my-plugin = require("my-plugin")',
      },
      start = { 1, 2 },    -- first '-' on line 1
      expected = {
        'my_module = require("my-module")',
        'my_helper = require("my-helper")',
        'my_config = require("my-config")',
        'my_plugin = require("my-plugin")',
      },
      check_lines = { 1, 2, 3, 4 },
      optimal = 8,    -- r_ j f- . j f- . j f- .
      hint = 'r_ replaces the character under the cursor. Move to the next occurrence with j then f-, then press . to repeat.',
    }),
  },
}

-- ─── Lesson 5 — Join Lines (J) ────────────────────────────────────────────────

local lesson5 = {
  title = 'Join Lines',
  explanation = {
    'J        — join the current line with the line below; inserts a single space between them.',
    '{n}J     — join n lines together (e.g. 3J joins the current line + 2 below).',
    'gJ       — join without inserting any space.',
    '',
    'J is an editing change, so . repeats it and u undoes it.',
    '',
    'Common use: collapse multi-line expressions back to one line.',
  },
  challenges = {
    -- 1. J joins two lines
    h.power({
      command = 'J',
      instruction = 'Join lines 1 and 2 into one line with J',
      lines = join_lines,
      start = { 1, 0 },
      expected = {
        'const greeting = "Hello, world!";',
        'const farewell =',
        '  "Goodbye, world!";',
        'const message =',
        '  greeting + " " + farewell;',
      },
      optimal = 1,
      hint = 'J joins the current line with the next one, replacing the newline with a space.',
    }),
    -- 2. J twice to join three lines
    h.power({
      command = 'J',
      instruction = 'Join "const farewell" with its value on the next line using J',
      lines = {
        'const greeting = "Hello, world!";',
        'const farewell =',
        '  "Goodbye, world!";',
        'const message =',
        '  greeting + " " + farewell;',
      },
      start = { 2, 0 },
      expected = {
        'const greeting = "Hello, world!";',
        'const farewell = "Goodbye, world!";',
        'const message =',
        '  greeting + " " + farewell;',
      },
      optimal = 1,
      hint = 'Position on line 2, press J once to pull line 3 up.',
    }),
    -- 3. 3J to join three lines at once
    h.power({
      command = 'J',
      instruction = 'Collapse the 3-line message assignment into one line with 3J',
      lines = {
        'const greeting = "Hello, world!";',
        'const farewell = "Goodbye, world!";',
        'const message =',
        '  greeting +',
        '  farewell;',
      },
      start = { 3, 0 },
      expected = {
        'const greeting = "Hello, world!";',
        'const farewell = "Goodbye, world!";',
        'const message = greeting + farewell;',
      },
      optimal = 2,   -- 3J (2 keystrokes: '3' and 'J')
      hint = '3J joins 3 lines together (current line + 2 below).',
    }),
    -- 4. gJ join without space
    h.power({
      command = 'gJ',
      instruction = 'Join the split URL into one line without a space using gJ',
      lines = {
        'https://example.com',
        '/api/v1/users',
        'https://example.com',
        '/api/v1/posts',
      },
      start = { 1, 0 },
      expected = {
        'https://example.com/api/v1/users',
        'https://example.com',
        '/api/v1/posts',
      },
      optimal = 2,
      hint = 'gJ joins without inserting a space, so the URL stays intact.',
    }),
    -- 5. J then dot-repeat
    h.power({
      command = 'J',
      instruction = 'Join all four pairs of lines using J then j. to repeat',
      lines = {
        'alpha =',
        '  1',
        'beta =',
        '  2',
        'gamma =',
        '  3',
        'delta =',
        '  4',
      },
      start = { 1, 0 },
      expected = {
        'alpha = 1',
        'beta = 2',
        'gamma = 3',
        'delta = 4',
      },
      optimal = 7,   -- J(1) + j.(2) + j.(2) + j.(2) = 7
      hint = 'J joins the first pair. j moves past the joined line. . repeats the join on the next pair.',
    }),
  },
}

-- ─── Lesson 6 — Lowercase and Uppercase (~, gu, gU) ──────────────────────────

local lesson6 = {
  title = 'Lowercase and Uppercase',
  explanation = {
    '~    — toggle the case of the character under the cursor and advance.',
    'gu{motion}  — make the text covered by {motion} lowercase.',
    'gU{motion}  — make the text covered by {motion} uppercase.',
    '',
    'Examples:',
    '  guiw  — lowercase the current word.',
    '  gUiw  — uppercase the current word.',
    '  gu$   — lowercase from cursor to end of line.',
    '  gU0   — uppercase from cursor to the start of line.',
    '',
    'These are regular changes — "." repeats them, "u" undoes them.',
  },
  challenges = {
    -- 1. ~ to toggle a single character
    h.power({
      command = '~',
      instruction = 'Toggle "t" to uppercase "T" with ~',
      lines = case_lines,
      start = { 1, 0 },
      expected = {
        'The quick brown fox',
        'JUMPS OVER THE LAZY DOG',
        'a Mixed Case Line Here',
        'another line to transform',
      },
      optimal = 1,
      hint = '~ toggles the case of one character and moves the cursor forward.',
    }),
    -- 2. gUiw to uppercase a word
    h.power({
      command = 'gU',
      instruction = 'Uppercase the word "Mixed" with gUiw',
      lines = case_lines,
      start = { 3, 2 },   -- 'M' of 'Mixed'
      expected = {
        'the quick brown fox',
        'JUMPS OVER THE LAZY DOG',
        'a MIXED Case Line Here',
        'another line to transform',
      },
      optimal = 4,   -- gUiw
      hint = 'gU is the operator. iw selects the inner word. Together they uppercase the word.',
    }),
    -- 3. guiw to lowercase a word
    h.power({
      command = 'gu',
      instruction = 'Lowercase the word "JUMPS" with guiw',
      lines = case_lines,
      start = { 2, 0 },
      expected = {
        'the quick brown fox',
        'jumps OVER THE LAZY DOG',
        'a Mixed Case Line Here',
        'another line to transform',
      },
      optimal = 4,   -- guiw
      hint = 'gu is the lowercase operator. iw selects the inner word.',
    }),
    -- 4. gU$ to uppercase to end of line
    h.power({
      command = 'gU',
      instruction = 'Uppercase from "to" to end of line with gU$',
      lines = case_lines,
      start = { 4, 13 },  -- 't' of 'to' in 'another line to transform'
      expected = {
        'the quick brown fox',
        'JUMPS OVER THE LAZY DOG',
        'a Mixed Case Line Here',
        'another line TO TRANSFORM',
      },
      optimal = 3,   -- gU$
      hint = 'gU$ applies uppercase from cursor to end of line.',
    }),
    -- 5. gu$ to lowercase entire line
    h.power({
      command = 'gu',
      instruction = 'Lowercase the entire line with gu$',
      lines = case_lines,
      start = { 2, 0 },
      expected = {
        'the quick brown fox',
        'jumps over the lazy dog',
        'a Mixed Case Line Here',
        'another line to transform',
      },
      optimal = 3,   -- gu$
      hint = 'gu$ lowercases from the cursor all the way to the end of the line.',
    }),
  },
}

-- ─── Lesson 7 — :norm on Ranges ──────────────────────────────────────────────

local norm_lines = {
  'function alpha',
  'function beta',
  'function gamma',
  'function delta',
  'function epsilon',
}

local norm_comment_lines = {
  'const alpha = 1',
  'const beta  = 2',
  'const gamma = 3',
  'const delta = 4',
}

local lesson7 = {
  title = ':norm on Ranges',
  description = 'Apply a Normal-mode sequence to every line in a range with :norm.',
  advanced = true,
  explanation = {
    ":'<,'>norm A;  — append a semicolon to every line in the visual selection.",
    ':%norm I//     — prepend "//" to every line in the file (comment all).',
    ':%norm A;      — append ";" to every line.',
    '',
    ':norm {keys} executes the given Normal-mode keystrokes on each line.',
    'Combine with ranges: %, line numbers, or visual selection marks (<,>).',
    '',
    'Useful for batch structural edits that macros would also handle.',
    'No need to record a macro when the edit is a simple prefix/suffix.',
  },
  challenges = {
    -- 1. :%norm A to append to all lines
    h.power({
      command = ':%norm',
      instruction = 'Append "()" to every line using :%norm A()',
      lines = norm_lines,
      start = { 1, 0 },
      expected = {
        'function alpha()',
        'function beta()',
        'function gamma()',
        'function delta()',
        'function epsilon()',
      },
      optimal = 11,   -- :%norm A()<CR>
      hint = ':%norm A() runs A (append) then "()" on every line in the buffer.',
      optimal_solution = ':%norm A()\r',
    }),
    -- 2. :%norm I to prepend to all lines
    h.power({
      command = ':%norm',
      instruction = 'Comment every line by prepending "-- " using :%norm I-- ',
      lines = norm_lines,
      start = { 1, 0 },
      expected = {
        '-- function alpha',
        '-- function beta',
        '-- function gamma',
        '-- function delta',
        '-- function epsilon',
      },
      optimal = 12,   -- :%norm I-- <CR>
      hint = 'I enters Insert at the start of the line. Everything after I is the inserted text.',
      optimal_solution = ':%norm I-- \r',
    }),
    -- 3. Range norm on specific lines
    h.power({
      command = ':2,3norm',
      instruction = 'Append ";" to lines 2-3 only using :2,3norm A;',
      lines = norm_comment_lines,
      start = { 1, 0 },
      expected = {
        'const alpha = 1',
        'const beta  = 2;',
        'const gamma = 3;',
        'const delta = 4',
      },
      optimal = 12,
      hint = ':2,3norm limits :norm to lines 2 and 3. Lines 1 and 4 are unchanged.',
      optimal_solution = ':2,3norm A;\r',
    }),
  },
}

-- ─── Lesson 8 — Command-Line Window (q:, q/) ──────────────────────────────────

local cmdwin_lines = {
  'alpha = 1',
  'beta  = 2',
  'gamma = 3',
  'delta = 4',
}

local lesson8 = {
  title = 'Command-Line Window',
  description = 'Edit and re-run past commands and searches from an editable buffer.',
  advanced = true,
  explanation = {
    'q:  — open the command-line window showing ex command history.',
    'q/  — open the search history as an editable buffer.',
    'q?  — open backward-search history.',
    '',
    'Inside the window you can:',
    '  - Edit any past command with full Normal-mode motions.',
    '  - Press <CR> on a line to execute it.',
    '  - Press <C-c> or :q to close without executing.',
    '',
    'This is powerful for tweaking a long substitute command you ran before.',
  },
  challenges = {
    -- 1. Use q: window to run a substitute
    h.power({
      command = 'q:',
      instruction = 'Open q:, type :%s/alpha/ALPHA/g and press Enter to execute',
      lines = cmdwin_lines,
      start = { 1, 0 },
      expected = {
        'ALPHA = 1',
        'beta  = 2',
        'gamma = 3',
        'delta = 4',
      },
      optimal = 22,
      hint = 'q: opens the command window. Type the substitute command and press Enter to run it.',
      optimal_solution = 'q::%s/alpha/ALPHA/g\r',
    }),
    -- 2. Run a global delete via q:
    h.power({
      command = 'q:',
      instruction = 'Via q:, run :g/beta/d to delete the "beta" line',
      lines = cmdwin_lines,
      start = { 1, 0 },
      expected = {
        'alpha = 1',
        'gamma = 3',
        'delta = 4',
      },
      optimal = 14,
      hint = 'In the command window, type :g/beta/d and press Enter.',
      optimal_solution = 'q::g/beta/d\r',
    }),
    -- 3. q: to uppercase a specific line
    h.power({
      command = 'q:',
      instruction = 'Open q: and run :3s/.*/\\U&/ to uppercase line 3',
      lines = cmdwin_lines,
      start = { 1, 0 },
      expected = {
        'alpha = 1',
        'beta  = 2',
        'GAMMA = 3',
        'delta = 4',
      },
      optimal = 16,
      hint = 'In the command window, type :3s/.*/\\U&/ and press Enter. \\U& uppercases the whole match.',
      optimal_solution = 'q::3s/.*/\\U&/\r',
    }),
  },
}

-- ─── Lesson 9 — Repeat & Chain (@:, @@) ──────────────────────────────────────

local repeat_lines = {
  'const alpha = "old"',
  'const beta  = "old"',
  'const gamma = "old"',
  'const delta = "old"',
}

local lesson9 = {
  title = 'Repeat & Chain',
  description = 'Replay the last ex command with @: and chain repeats with @@.',
  advanced = true,
  explanation = {
    '@:   — repeat the last ex command (: command) exactly as typed.',
    '@@   — repeat the last @{reg} or @: invocation.',
    '',
    'Workflow:',
    '  1. Run an ex command: :s/old/new/',
    '  2. Move to the next target line.',
    '  3. @: repeats the :s command on the new line.',
    '  4. @@ repeats @: again without re-typing.',
    '',
    '@: is the ex-command equivalent of . for Normal changes.',
    'Great for running the same :norm, :s, or :g on multiple disconnected lines.',
  },
  challenges = {
    -- 1. @: to repeat last :s command
    h.power({
      command = '@:',
      instruction = 'Run :s/old/new/ on line 1, then @: on line 2 to repeat it',
      lines = repeat_lines,
      start = { 1, 0 },
      expected = {
        'const alpha = "new"',
        'const beta  = "new"',
        'const gamma = "old"',
        'const delta = "old"',
      },
      optimal = 16,   -- :s/old/new/<CR> j @:
      hint = ':s/old/new/ changes line 1. j moves down. @: replays the substitute on line 2.',
      optimal_solution = ':s/old/new/\rj@:',
    }),
    -- 2. @@ to repeat @:
    h.power({
      command = '@@',
      instruction = 'After @: replaces line 2, press j then @@ to continue to line 3',
      lines = {
        'const alpha = "new"',
        'const beta  = "new"',
        'const gamma = "old"',
        'const delta = "old"',
      },
      start = { 3, 0 },
      expected = {
        'const alpha = "new"',
        'const beta  = "new"',
        'const gamma = "new"',
        'const delta = "old"',
      },
      optimal = 2,   -- @@ (after @: was already used)
      hint = '@@ re-runs the most recent @:. Two keystrokes continue the chain.',
      optimal_solution = '@@',
    }),
    -- 3. Chain @: and @@ to process all remaining lines
    h.power({
      command = '@@',
      instruction = 'Process line 4 with @@ to replace the last "old"',
      lines = {
        'const alpha = "new"',
        'const beta  = "new"',
        'const gamma = "new"',
        'const delta = "old"',
      },
      start = { 4, 0 },
      expected = {
        'const alpha = "new"',
        'const beta  = "new"',
        'const gamma = "new"',
        'const delta = "new"',
      },
      optimal = 2,
      hint = '@@ keeps replaying the last ex command. Every subsequent line needs only two keystrokes.',
      optimal_solution = '@@',
    }),
  },
}

-- ─── Lesson 10 — Project-Wide Replace ────────────────────────────────────────

local project_lines = {
  'require("utils.logger")',
  'require("utils.parser")',
  'require("utils.formatter")',
  'local mod = require("utils")',
  '-- see mod docs for details',
}

local lesson10 = {
  title = 'Project-Wide Replace',
  description = 'Learn :vimgrep, :cdo, and :args patterns via single-buffer substitution.',
  advanced = true,
  explanation = {
    'Real project-wide replace workflow:',
    '  :args **/*.lua          — load all Lua files into the args list.',
    '  :vimgrep /pattern/ %   — populate the quickfix list with matches.',
    '  :cdo s/old/new/g       — run substitute on every quickfix entry.',
    '  :cfdo update           — save all changed files.',
    '',
    'In this buffer we practise the same patterns with :%s and :g:',
    '  :%s  — equivalent of :cdo s applied to one buffer.',
    '  :g   — equivalent of filtering + acting on matching lines.',
    '',
    'The key insight: :cdo s/old/new/g is :%s/old/new/g across every file.',
  },
  challenges = {
    -- 1. :%s to simulate cdo substitute
    h.power({
      command = ':%s',
      instruction = 'Replace "utils" with "lib" everywhere using :%s/utils/lib/g',
      lines = project_lines,
      start = { 1, 0 },
      expected = {
        'require("lib.logger")',
        'require("lib.parser")',
        'require("lib.formatter")',
        'local lib = require("lib")',
        '-- see lib docs for details',
      },
      optimal = 17,
      hint = ':%s/utils/lib/g is what :cdo s/utils/lib/g does to each file. /g replaces all per line.',
      optimal_solution = ':%s/utils/lib/g\r',
    }),
    -- 2. :g to simulate vimgrep + norm action
    h.power({
      command = ':g',
      instruction = 'Prepend "-- " to every require() line using :g/require/norm I-- ',
      lines = project_lines,
      start = { 1, 0 },
      expected = {
        '-- require("utils.logger")',
        '-- require("utils.parser")',
        '-- require("utils.formatter")',
        '-- local mod = require("utils")',
        '-- see mod docs for details',
      },
      optimal = 20,
      hint = ':g/require/norm I-- runs I (insert at start) + "-- " on every matching line.',
      optimal_solution = ':g/require/norm I-- \r',
    }),
    -- 3. Combine :g and :s for targeted replacement
    h.power({
      command = ':g',
      instruction = 'On require() lines only, replace "utils" with "core" using :g/require/s/utils/core/g',
      lines = project_lines,
      start = { 1, 0 },
      expected = {
        'require("core.logger")',
        'require("core.parser")',
        'require("core.formatter")',
        'local mod = require("core")',
        '-- see mod docs for details',
      },
      optimal = 28,
      hint = ':g/require/s/utils/core/g — :g filters to require lines, :s replaces only there.',
      optimal_solution = ':g/require/s/utils/core/g\r',
    }),
  },
}

M.lessons = { lesson1, lesson2, lesson3, lesson4, lesson5, lesson6, lesson7, lesson8, lesson9, lesson10 }

return M
