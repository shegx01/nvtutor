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

M.lessons = { lesson1, lesson2, lesson3, lesson4, lesson5, lesson6 }

return M
