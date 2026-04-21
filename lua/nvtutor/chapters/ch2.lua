local h = require('nvtutor.chapters.helpers')
local M = {}

M.title = 'Editing Essentials'
M.description = 'Master the core editing operators: yank, delete, and the three visual selection modes. These primitives underpin almost every editing workflow in Vim.'

M.lessons = {
  -- Lesson 1: Yanking and Putting (y, p, P)
  {
    title = 'Yanking and Putting',
    description = 'y yanks (copies) text. p puts (pastes) it after the cursor; P puts before the cursor. yy yanks the entire current line.',
    challenges = {
      -- Challenge 1: yank a line and put below
      h.editing({
        command = 'yyp',
        instruction = 'Duplicate line 1 below itself using yyp.',
        lines = {
          'function greet(name)',
          '  print("Hello")',
          'end',
        },
        start = { 1, 0 },
        expected = {
          'function greet(name)',
          'function greet(name)',
          '  print("Hello")',
          'end',
        },
        optimal = 3,
        time = 5.0,
        hint = 'yyp: yank line (yy) then put below (p)',
      }),
      -- Challenge 2: yank a word and put it at end of line
      h.editing({
        command = 'yiw',
        instruction = 'Add "hello" at the end to get "hello worldhello". Yank with yiw then paste at line end.',
        lines = {
          'hello world',
        },
        start = { 1, 0 },
        expected = {
          'hello worldhello',
        },
        optimal = 5,
        time = 8.0,
        hint = 'yiw yanks the inner word (no space), then $ to end of line, then p to paste after',
      }),
      -- Challenge 3: put before cursor with P
      h.editing({
        command = 'yyP',
        instruction = 'Duplicate line 2 above itself using yyP.',
        lines = {
          'local x = 10',
          'local y = 20',
          'local z = 30',
        },
        start = { 2, 0 },
        expected = {
          'local x = 10',
          'local y = 20',
          'local y = 20',
          'local z = 30',
        },
        optimal = 3,
        time = 6.0,
        hint = 'yyP: yank current line (yy), then P puts it above the current line',
      }),
      -- Challenge 4: yank 2 lines and put them
      h.editing({
        command = '2yyp',
        instruction = 'Duplicate lines 1-2 below themselves using 2yyp.',
        lines = {
          '  greet("Alice")',
          '  greet("Bob")',
          '  greet("Charlie")',
        },
        start = { 1, 0 },
        expected = {
          '  greet("Alice")',
          '  greet("Bob")',
          '  greet("Alice")',
          '  greet("Bob")',
          '  greet("Charlie")',
        },
        optimal = 4,
        time = 8.0,
        hint = '2yy yanks two lines; p pastes them as a block',
      }),
    },
  },

  -- Lesson 2: Deletion (d, dd, x)
  {
    title = 'Deletion',
    description = 'x deletes the character under the cursor. dd deletes the entire current line. dw deletes from cursor to start of next word. All deletions go into the default register and can be pasted.',
    challenges = {
      -- Challenge 1: delete a character with x
      h.editing({
        command = 'x',
        instruction = 'Change "colour" to "color" by deleting the "u" with x.',
        lines = {
          'Change the colour of the background.',
        },
        start = { 1, 15 },
        expected = {
          'Change the color of the background.',
        },
        optimal = 1,
        time = 4.0,
        hint = 'x deletes the character under the cursor',
      }),
      -- Challenge 2: delete a word with dw
      h.editing({
        command = 'dw',
        instruction = 'Delete "very " to get "This is a important line." using dw.',
        lines = {
          'This is a very important line.',
        },
        start = { 1, 10 },
        expected = {
          'This is a important line.',
        },
        optimal = 2,
        time = 5.0,
        hint = 'dw deletes from cursor to start of the next word',
      }),
      -- Challenge 3: delete an entire line with dd
      h.editing({
        command = 'dd',
        instruction = 'Remove the blank line between the two calls using dd.',
        lines = {
          'greet("Alice")',
          '',
          'greet("Bob")',
        },
        start = { 2, 0 },
        expected = {
          'greet("Alice")',
          'greet("Bob")',
        },
        optimal = 2,
        time = 4.0,
        hint = 'dd deletes the whole line the cursor is on',
      }),
      -- Challenge 4: delete multiple lines with count
      h.editing({
        command = '3dd',
        instruction = 'Delete the three debug print lines at once using 3dd.',
        lines = {
          'local result = compute()',
          'print("debug: entering")',
          'print("debug: value=" .. result)',
          'print("debug: exiting")',
          'return result',
        },
        start = { 2, 0 },
        expected = {
          'local result = compute()',
          'return result',
        },
        optimal = 3,
        time = 5.0,
        hint = '3dd deletes 3 lines starting from the cursor line',
      }),
    },
  },

  -- Lesson 3: Visual Character Mode (v)
  {
    title = 'Visual Character Mode',
    description = 'v enters Visual character mode. Move the cursor to extend the selection character by character. Operators like d, y, and c then act on the selected region.',
    challenges = {
      -- Challenge 1: select a single word visually and yank
      h.visual({
        command = 'v',
        instruction = 'Enter Visual mode from the "q" in "quick" and extend the selection to cover the whole word "quick" (to column 8).',
        lines = {
          'The quick brown fox.',
        },
        start = { 1, 4 },
        target_region = { { 1, 4 }, { 1, 8 } },
        optimal = 2,
        time = 6.0,
        hint = 'v then e extends the selection to end of word — just 2 keystrokes!',
      }),
      -- Challenge 2: select across words
      h.visual({
        command = 'v',
        instruction = 'Select "brown fox" (columns 10-18) using Visual mode.',
        lines = {
          'The quick brown fox jumps.',
        },
        start = { 1, 10 },
        target_region = { { 1, 10 }, { 1, 18 } },
        optimal = 3,
        time = 8.0,
        hint = 'v then 2e extends the selection two word-ends — covering "brown fox"',
      }),
      -- Challenge 3: select and delete
      h.editing({
        command = 'vd',
        instruction = 'Use Visual mode to select "TODO: " (columns 0-5) at the start of the line, then delete it.',
        lines = {
          'TODO: fix the off-by-one error',
          'return count - 1',
        },
        start = { 1, 0 },
        expected = {
          'fix the off-by-one error',
          'return count - 1',
        },
        optimal = 4,
        time = 8.0,
        hint = 'v then 5l selects "TODO: ", then d deletes it — 4 keystrokes total',
      }),
    },
  },

  -- Lesson 4: Visual Line Mode (V)
  {
    title = 'Visual Line Mode',
    description = 'V (capital V) enters Visual Line mode. Entire lines are selected at once. Great for yanking or deleting whole lines without worrying about column positions.',
    challenges = {
      -- Challenge 1: select one line and yank
      h.visual({
        command = 'V',
        instruction = 'Select the entire second line using Visual Line mode.',
        lines = {
          'def hello():',
          '    print("Hello, world!")',
          '    return True',
        },
        start = { 2, 4 },
        target_region = { { 2, 0 }, { 2, 24 } },
        optimal = 1,
        time = 4.0,
        hint = 'V instantly selects the whole line — no need to move',
      }),
      -- Challenge 2: select multiple lines
      h.visual({
        command = 'V',
        instruction = 'Select lines 2 through 4 using Visual Line mode and a downward motion.',
        lines = {
          'local names = {',
          '  "Alice",',
          '  "Bob",',
          '  "Charlie",',
          '}',
        },
        start = { 2, 0 },
        target_region = { { 2, 0 }, { 4, 11 } },
        optimal = 3,
        time = 5.0,
        hint = 'V then 2j extends the line selection downward by 2 lines',
      }),
      -- Challenge 3: select and delete entire lines
      h.editing({
        command = 'Vd',
        instruction = 'Delete both comment lines (lines 1 and 2) using Visual Line mode.',
        lines = {
          '-- TODO: remove before shipping',
          '-- HACK: temporary workaround',
          'return process(data)',
        },
        start = { 1, 0 },
        expected = {
          'return process(data)',
        },
        optimal = 3,
        time = 6.0,
        hint = 'Vjd — V selects line 1; j extends to line 2; d deletes both — 3 keystrokes',
      }),
      -- Challenge 4: select lines and move them with p
      h.editing({
        command = 'Vdp',
        instruction = 'Cut the first line with Visual Line mode and paste it after line 2.',
        lines = {
          '  local z = 30',
          '  local x = 10',
          '  local y = 20',
        },
        start = { 1, 0 },
        expected = {
          '  local x = 10',
          '  local z = 30',
          '  local y = 20',
        },
        optimal = 3,
        time = 8.0,
        hint = 'Vdp — V selects, d cuts, p pastes below the next line — 3 keystrokes',
      }),
    },
  },

  -- Lesson 5: Blockwise Visual Mode (Ctrl-v)
  {
    title = 'Blockwise Visual Mode',
    description = 'Ctrl-v enters Visual Block mode. You select a rectangular column of text across multiple lines. Use I or A to insert the same text on every selected line simultaneously.',
    challenges = {
      -- Challenge 1: select a column of visible characters
      h.visual({
        command = '<C-v>',
        instruction = 'Select the ">" markers at the start of all 3 lines using block select (Ctrl-v then 2j).',
        lines = {
          '> Buy groceries',
          '> Walk the dog',
          '> Read a book',
        },
        start = { 1, 0 },
        target_region = { { 1, 0 }, { 3, 0 } },
        optimal = 3,
        time = 6.0,
        hint = 'Ctrl-v starts block mode at the ">". Press 2j to extend down 2 lines.',
      }),
      -- Challenge 2: select a rectangular block of text
      h.visual({
        command = '<C-v>',
        instruction = 'Select the 3-letter status codes ("200", "404", "500") in the first column across all 3 lines.',
        lines = {
          '200 OK',
          '404 Not Found',
          '500 Server Error',
        },
        start = { 1, 0 },
        target_region = { { 1, 0 }, { 3, 2 } },
        optimal = 4,
        time = 8.0,
        hint = 'Ctrl-v then 2l selects 3 columns wide. Then 2j extends down 2 lines.',
      }),
      -- Challenge 3: block delete a column of characters
      h.editing({
        command = '<C-v>d',
        instruction = 'Delete the leading "- " marker from each of the three list items using block delete.',
        lines = {
          '- apple',
          '- banana',
          '- cherry',
        },
        start = { 1, 0 },
        expected = {
          'apple',
          'banana',
          'cherry',
        },
        optimal = 5,
        time = 8.0,
        hint = 'Ctrl-v, select 2j then l to cover "- ", then d',
      }),
    },
  },

  -- Lesson 6: Indentation (>, <, =)
  {
    title = 'Indentation',
    description = '> indents lines right by one shiftwidth. < dedents left. == auto-indents the current line. Combine with counts or Visual Line mode to indent blocks.',
    challenges = {
      -- Challenge 1: indent a single line
      h.editing({
        command = '>>',
        instruction = 'Indent the function body line one level to the right.',
        lines = {
          'function run()',
          'print("running")',
          'end',
        },
        start = { 2, 0 },
        expected = {
          'function run()',
          '  print("running")',
          'end',
        },
        optimal = 2,
        time = 4.0,
        hint = '>> indents the current line by one shiftwidth (usually 2 or 4 spaces)',
      }),
      -- Challenge 2: dedent a line
      h.editing({
        command = '<<',
        instruction = 'The return line is over-indented. Dedent it one level.',
        lines = {
          'function total()',
          '  local sum = 0',
          '    return sum',
          'end',
        },
        start = { 3, 0 },
        expected = {
          'function total()',
          '  local sum = 0',
          '  return sum',
          'end',
        },
        optimal = 2,
        time = 4.0,
        hint = '<< removes one shiftwidth of indentation from the current line',
      }),
      -- Challenge 3: indent a block with Visual mode
      h.editing({
        command = 'V2j>',
        instruction = 'Indent the three body lines of the loop one level using Visual Line mode.',
        lines = {
          'for i = 1, 10 do',
          'print(i)',
          'total = total + i',
          'io.write(i)',
          'end',
        },
        start = { 2, 0 },
        expected = {
          'for i = 1, 10 do',
          '  print(i)',
          '  total = total + i',
          '  io.write(i)',
          'end',
        },
        optimal = 4,
        time = 8.0,
        hint = 'V2j> — V selects, 2j extends down 2 lines, > indents — 4 keystrokes',
      }),
      -- Challenge 4: auto-indent with ==
      h.editing({
        command = '==',
        instruction = 'The else-branch line has wrong indentation. Auto-indent it with ==.',
        lines = {
          'if x > 0 then',
          '  print("positive")',
          'print("non-positive")',
          'end',
        },
        start = { 3, 0 },
        expected = {
          'if x > 0 then',
          '  print("positive")',
          '  print("non-positive")',
          'end',
        },
        optimal = 2,
        time = 4.0,
        hint = '== auto-indents the current line based on the surrounding context',
      }),
    },
  },
}

return M
