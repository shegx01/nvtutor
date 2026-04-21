local h = require('nvtutor.chapters.helpers')
local M = {}

M.title = 'Insert & Change Mastery'
M.description = 'Vim offers a precise set of commands for entering Insert mode and making targeted changes. Knowing when to use i vs a, o vs O, or s vs c lets you edit with surgical accuracy.'

M.lessons = {
  -- Lesson 1: Insert Lines (o, O)
  {
    title = 'Insert Lines',
    description = 'o opens a new line below the current line and enters Insert mode. O opens a new line above and enters Insert mode. Neither requires you to move to the end of a line first.',
    challenges = {
      -- Challenge 1: o — open line below
      h.editing({
        command = 'o',
        instruction = 'Open a new line below "local x = 1" and type "local y = 2".',
        lines = {
          'local x = 1',
          'local z = 3',
        },
        start = { 1, 0 },
        expected = {
          'local x = 1',
          'local y = 2',
          'local z = 3',
        },
        optimal = 13,
        time = 10.0,
        hint = 'o opens a new indented line below and enters Insert mode immediately',
      }),
      -- Challenge 2: O — open line above
      h.editing({
        command = 'O',
        instruction = 'Insert a blank comment line "-- initialise" above the "local count = 0" line.',
        lines = {
          'function run()',
          'local count = 0',
          'end',
        },
        start = { 2, 0 },
        expected = {
          'function run()',
          '-- initialise',
          'local count = 0',
          'end',
        },
        optimal = 16,
        time = 10.0,
        hint = 'O opens a new line ABOVE the cursor line — no need to move up first',
      }),
      -- Challenge 3: o at end of function to add a return
      h.editing({
        command = 'o',
        instruction = 'Add "  return total" on a new line after "  total = total + n".',
        lines = {
          'local function add(n)',
          '  local total = 0',
          '  total = total + n',
          'end',
        },
        start = { 3, 0 },
        expected = {
          'local function add(n)',
          '  local total = 0',
          '  total = total + n',
          '  return total',
          'end',
        },
        optimal = 15,
        time = 10.0,
        hint = 'o on the last body line; type the return statement; Esc',
      }),
    },
  },

  -- Lesson 2: Paste Precisely (p, P)
  {
    title = 'Paste Precisely',
    description = 'p pastes after the cursor (or below the current line for linewise yanks). P pastes before the cursor (or above the line). The direction matters more than you think.',
    challenges = {
      -- Challenge 1: p after a character yank
      h.editing({
        command = 'ylp',
        instruction = 'Yank the "H" in "Hello" and paste a copy of it immediately after the "H".',
        lines = {
          'Hello',
        },
        start = { 1, 0 },
        expected = {
          'HHello',
        },
        optimal = 3,
        time = 5.0,
        hint = 'yl yanks one character to the right; p pastes it after the cursor',
      }),
      -- Challenge 2: P before cursor
      h.editing({
        command = 'ylP',
        instruction = 'Yank the "!" at column 5 and paste it before itself to double the exclamation.',
        lines = {
          'Hello!',
        },
        start = { 1, 5 },
        expected = {
          'Hello!!',
        },
        optimal = 3,
        time = 5.0,
        hint = 'yl yanks the char under cursor; P pastes it before the cursor',
      }),
      -- Challenge 3: linewise yank and paste order
      h.editing({
        command = 'yyp',
        instruction = 'Duplicate line 3 by yanking and pasting it below itself.',
        lines = {
          'apple',
          'banana',
          'cherry',
          'date',
        },
        start = { 3, 0 },
        expected = {
          'apple',
          'banana',
          'cherry',
          'cherry',
          'date',
        },
        optimal = 3,
        time = 5.0,
        hint = 'yyp is the classic line-duplication sequence',
      }),
      -- Challenge 4: paste a line above with P
      h.editing({
        command = 'jyykkP',
        instruction = 'Move to line 2, yank it, then paste it above line 1.',
        lines = {
          'local b = 2',
          'local a = 1',
          'local c = 3',
        },
        start = { 1, 0 },
        expected = {
          'local a = 1',
          'local b = 2',
          'local a = 1',
          'local c = 3',
        },
        optimal = 6,
        time = 8.0,
        hint = 'yyP on line 2 pastes the line above itself — but navigating first is needed here',
      }),
    },
  },

  -- Lesson 3: Replace Character (r)
  {
    title = 'Replace Character',
    description = 'r replaces the single character under the cursor without entering Insert mode. It is the fastest way to fix a typo when only one character is wrong.',
    challenges = {
      -- Challenge 1: fix a single typo
      h.editing({
        command = 'r',
        instruction = 'The word "teh" should be "the". The cursor is on "t". Replace the "e" (at col 1) with "h" and "h" (at col 2) with "e".',
        lines = {
          'teh quick brown fox',
        },
        start = { 1, 1 },
        expected = {
          'the quick brown fox',
        },
        optimal = 4,
        time = 6.0,
        hint = 'rh replaces under cursor with h; move right; re replaces with e',
      }),
      -- Challenge 2: replace a digit
      h.editing({
        command = 'r',
        instruction = 'Change the version from "1.0.0" to "2.0.0" by replacing the first character.',
        lines = {
          'version = "1.0.0"',
        },
        start = { 1, 11 },
        expected = {
          'version = "2.0.0"',
        },
        optimal = 2,
        time = 4.0,
        hint = 'r2 replaces the character under cursor with "2"',
      }),
      -- Challenge 3: replace to fix wrong operator
      h.editing({
        command = 'r',
        instruction = 'The condition uses "=" (assignment) instead of ">" (greater-than). Fix it.',
        lines = {
          'if count = 10 then',
        },
        start = { 1, 9 },
        expected = {
          'if count > 10 then',
        },
        optimal = 2,
        time = 4.0,
        hint = 'r> replaces the single character with >',
      }),
    },
  },

  -- Lesson 4: Substitute (s, S)
  {
    title = 'Substitute',
    description = 's substitutes the character under the cursor: it deletes it and enters Insert mode. S substitutes the entire line: it clears the line content and enters Insert mode at the proper indent.',
    challenges = {
      -- Challenge 1: s on a single character
      h.editing({
        command = 's',
        instruction = 'The "x" in "axle" is wrong — it should read "able". Substitute "x" with "bl".',
        lines = {
          'axle seating',
        },
        start = { 1, 1 },
        expected = {
          'able seating',
        },
        optimal = 4,
        time = 6.0,
        hint = 's deletes the char under cursor and drops you into Insert mode',
      }),
      -- Challenge 2: s with a count (substitute multiple chars)
      h.editing({
        command = 's',
        instruction = 'Replace "foo" (3 chars starting at col 6) with "bar" using 3s.',
        lines = {
          'local foo_count = 0',
        },
        start = { 1, 6 },
        expected = {
          'local bar_count = 0',
        },
        optimal = 5,
        time = 6.0,
        hint = '3s deletes 3 characters and enters Insert mode — then type "bar"',
      }),
      -- Challenge 3: S to rewrite a whole line
      h.editing({
        command = 'S',
        instruction = 'The debug line needs to be completely replaced. Use S to clear it and type "  return nil" instead.',
        lines = {
          'function find()',
          '  print("FIXME")',
          'end',
        },
        start = { 2, 2 },
        expected = {
          'function find()',
          '  return nil',
          'end',
        },
        optimal = 13,
        time = 8.0,
        hint = 'S clears the whole line (keeping indentation) and enters Insert mode',
      }),
    },
  },

  -- Lesson 5: Insert and Append (i, a)
  {
    title = 'Insert and Append',
    description = 'i enters Insert mode before the cursor character. a enters Insert mode after the cursor character. The difference of one character position matters for building text precisely.',
    challenges = {
      -- Challenge 1: i to insert before
      h.editing({
        command = 'i',
        instruction = 'The cursor is on "w" in "world". Insert "beautiful " before "world" using i.',
        lines = {
          'Hello world!',
        },
        start = { 1, 6 },
        expected = {
          'Hello beautiful world!',
        },
        optimal = 12,
        time = 8.0,
        hint = 'i inserts at the cursor position (before the character under cursor)',
      }),
      -- Challenge 2: a to append after
      h.editing({
        command = 'a',
        instruction = 'The cursor is on "o" in "Hello". Append ", Vim" after the "o" using a.',
        lines = {
          'Hello world',
        },
        start = { 1, 4 },
        expected = {
          'Hello, Vim world',
        },
        optimal = 8,
        time = 8.0,
        hint = 'a enters Insert mode AFTER the cursor character',
      }),
      -- Challenge 3: choose i vs a correctly
      h.editing({
        command = 'a',
        instruction = 'Cursor is on the closing ) of greet(). Append " -- called" as a trailing comment.',
        lines = {
          'greet()',
        },
        start = { 1, 6 },
        expected = {
          'greet() -- called',
        },
        optimal = 12,
        time = 8.0,
        hint = 'a after ) puts you right where you need to type the comment',
      }),
    },
  },

  -- Lesson 6: Line Based Insert and Append (I, A)
  {
    title = 'Line Based Insert and Append',
    description = 'I (capital I) enters Insert mode at the first non-blank character of the line. A (capital A) enters Insert mode at the very end of the line. Neither requires you to move the cursor first.',
    challenges = {
      -- Challenge 1: A to append at end of line
      h.editing({
        command = 'A',
        instruction = 'Add " -- deprecated" at the end of the function signature line. The cursor is anywhere on that line.',
        lines = {
          'function old_api()',
          '  return nil',
          'end',
        },
        start = { 1, 4 },
        expected = {
          'function old_api() -- deprecated',
          '  return nil',
          'end',
        },
        optimal = 16,
        time = 8.0,
        hint = 'A jumps to end of line and enters Insert mode — no $ needed first',
      }),
      -- Challenge 2: I to insert at line start
      h.editing({
        command = 'I',
        instruction = 'Add "-- " at the start of the print line to comment it out. Cursor is in the middle of the line.',
        lines = {
          '  print("debug value:", x)',
        },
        start = { 1, 10 },
        expected = {
          '  -- print("debug value:", x)',
        },
        optimal = 5,
        time = 6.0,
        hint = 'I jumps to the first non-blank character and enters Insert mode',
      }),
      -- Challenge 3: A to complete an incomplete statement
      h.editing({
        command = 'A',
        instruction = 'The assignment is missing its value. Use A to append " = true" at the end.',
        lines = {
          'local verbose',
          'local quiet = false',
        },
        start = { 1, 0 },
        expected = {
          'local verbose = true',
          'local quiet = false',
        },
        optimal = 9,
        time = 8.0,
        hint = 'A from anywhere on the line goes straight to the end for insertion',
      }),
    },
  },

  -- Lesson 7: Delete and Change Lines (D, C, cc)
  {
    title = 'Delete and Change Lines',
    description = 'D deletes from the cursor to the end of the line (equivalent to d$). C changes from the cursor to the end of the line (equivalent to c$) and enters Insert mode. cc clears the entire line content and enters Insert mode.',
    challenges = {
      -- Challenge 1: D to delete to end of line
      h.editing({
        command = 'D',
        instruction = 'The cursor is on the space before "-- REMOVE THIS". Delete from there to the end of the line.',
        lines = {
          'local x = 10 -- REMOVE THIS',
          'local y = 20',
        },
        start = { 1, 13 },
        expected = {
          'local x = 10',
          'local y = 20',
        },
        optimal = 1,
        time = 4.0,
        hint = 'D deletes from cursor position to end of line in one keystroke',
      }),
      -- Challenge 2: C to change to end of line
      h.editing({
        command = 'C',
        instruction = 'Cursor is at the start of the wrong return value. Use C to change "false" to "true".',
        lines = {
          'local function is_ready()',
          '  return false',
          'end',
        },
        start = { 2, 9 },
        expected = {
          'local function is_ready()',
          '  return true',
          'end',
        },
        optimal = 6,
        time = 8.0,
        hint = 'C deletes to end of line and enters Insert mode — type the replacement',
      }),
      -- Challenge 3: cc to rewrite an entire line
      h.editing({
        command = 'cc',
        instruction = 'Rewrite the entire second line from scratch to say "  local sum = a + b".',
        lines = {
          'local function add(a, b)',
          '  return nil -- placeholder',
          'end',
        },
        start = { 2, 5 },
        expected = {
          'local function add(a, b)',
          '  local sum = a + b',
          'end',
        },
        optimal = 20,
        time = 12.0,
        hint = 'cc clears the whole line (preserving indent) and enters Insert mode',
      }),
      -- Challenge 4: D to strip trailing content then C on another line
      h.editing({
        command = 'D',
        instruction = 'Delete the trailing " | unused" annotation from the end of line 1 (cursor at col 11).',
        lines = {
          'local name | unused',
          'local age = 25',
        },
        start = { 1, 11 },
        expected = {
          'local name',
          'local age = 25',
        },
        optimal = 1,
        time = 4.0,
        hint = 'D is a single keystroke — it deletes everything after the cursor on the line',
      }),
    },
  },
}

return M
