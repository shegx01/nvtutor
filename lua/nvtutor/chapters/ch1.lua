local h = require('nvtutor.chapters.helpers')
local M = {}

M.title = 'First Steps'
M.description = 'Learn the fundamental motions that make Vim feel like a language. Master vertical and horizontal movement, understand modes, and start navigating by word.'

M.lessons = {
  -- Lesson 1: Vertical Movement (j, k)
  {
    title = 'Vertical Movement',
    description = 'j moves down one line, k moves up one line. Prefix with a count to jump multiple lines at once.',
    challenges = {
      -- Challenge 1: simple j
      h.movement({
        command = 'j',
        instruction = 'Move the cursor down to line 4 (the fox line).',
        lines = {
          'Pack my box with five dozen liquor jugs.',
          'How vexingly quick daft zebras jump.',
          'The five boxing wizards jump quickly.',
          'The quick brown fox jumps over the lazy dog.',
          'Jinxed wizards pluck ivy from the big quilt.',
          'Bright vixens jump; dozy fowl quack.',
        },
        from = { 1, 0 },
        to   = { 4, 0 },
        optimal = 3,
        time = 5.0,
        hint = 'Press j three times, or use 3j',
      }),
      -- Challenge 2: count jump downward
      h.movement({
        command = 'j',
        instruction = 'Jump down 5 lines in a single motion to land on the last line.',
        lines = {
          'Sphinx of black quartz, judge my vow.',
          'Two driven jocks help fax my big quiz.',
          'The jay, pig, fox, zebra and my wolves quack!',
          'Waltz, bad nymph, for quick jigs vex.',
          'Pack my box with five dozen liquor jugs.',
          'How vexingly quick daft zebras jump.',
        },
        from = { 1, 0 },
        to   = { 6, 0 },
        optimal = 2,
        time = 5.0,
        hint = '5j jumps five lines at once',
      }),
      -- Challenge 3: move up with k
      h.movement({
        command = 'k',
        instruction = 'Move the cursor up from the bottom line to line 2.',
        lines = {
          'The quick brown fox jumps over the lazy dog.',
          'Waltz, bad nymph, for quick jigs vex.',
          'Bright vixens jump; dozy fowl quack.',
          'Jinxed wizards pluck ivy from the big quilt.',
          'Two driven jocks help fax my big quiz.',
        },
        from = { 5, 0 },
        to   = { 2, 0 },
        optimal = 2,
        time = 5.0,
        hint = '3k moves up three lines',
      }),
      -- Challenge 4: combine j and k
      h.movement({
        command = 'jk',
        instruction = 'Start on line 1, jump to line 6, then come back up to line 3.',
        lines = h.default_prose,
        from = { 1, 0 },
        to   = { 3, 0 },
        optimal = 4,
        time = 8.0,
        hint = 'Try 5j then 3k, or think of a shorter path',
      }),
    },
  },

  -- Lesson 2: Horizontal Movement (h, l)
  {
    title = 'Horizontal Movement',
    description = 'h moves left one character, l moves right one character. Like j/k, prefix with a count to jump multiple columns.',
    challenges = {
      -- Challenge 1: move right
      h.movement({
        command = 'l',
        instruction = 'Move right to column 5 (the "q" in "quick").',
        lines = {
          'The quick brown fox.',
          'A second line here.',
        },
        from = { 1, 0 },
        to   = { 1, 4 },
        optimal = 2,
        time = 5.0,
        hint = '4l moves four characters right',
      }),
      -- Challenge 2: move left
      h.movement({
        command = 'h',
        instruction = 'Move left from column 10 back to column 4.',
        lines = {
          'Pack my box with five dozen liquor jugs.',
        },
        from = { 1, 10 },
        to   = { 1, 4 },
        optimal = 2,
        time = 5.0,
        hint = '6h moves six characters left',
      }),
      -- Challenge 3: precise column targeting
      h.movement({
        command = 'l',
        instruction = 'Position the cursor on the "f" in "fox" (column 16).',
        lines = {
          'The quick brown fox jumps over the lazy dog.',
        },
        from = { 1, 0 },
        to   = { 1, 16 },
        optimal = 3,
        time = 6.0,
        hint = '16l or break it into chunks',
      }),
      -- Challenge 4: navigate to end of word then back
      h.movement({
        command = 'hl',
        instruction = 'From column 0 reach column 8 (the "x" in "box"), then return to column 5.',
        lines = {
          'Pack my box with five dozen.',
        },
        from = { 1, 0 },
        to   = { 1, 5 },
        optimal = 5,
        time = 8.0,
        hint = '8l then 3h — or think of a shorter route using w and b later',
      }),
    },
  },

  -- Lesson 3: Introduction to Modes (i, Esc, :, v)
  {
    title = 'Introduction to Modes',
    description = 'Vim is a modal editor. Normal mode is for navigation; Insert mode is for typing; Visual mode is for selection; Command mode (after :) is for commands like :w and :q.',
    challenges = {
      -- Challenge 1: enter insert mode and type a word
      h.editing({
        command = 'i',
        instruction = 'The line reads "Hello world". Position is before "world". Enter insert mode and type "beautiful " (with trailing space) so it reads "Hello beautiful world".',
        lines = {
          'Hello world',
        },
        start = { 1, 6 },
        expected = {
          'Hello beautiful world',
        },
        optimal = 12,
        time = 10.0,
        hint = 'i enters Insert mode; type your text; Esc returns to Normal',
      }),
      -- Challenge 2: append at end of line
      h.editing({
        command = 'a',
        instruction = 'The cursor is at the end of "Hello". Use a to append ", Vim user" after the cursor.',
        lines = {
          'Hello',
          'Second line stays.',
        },
        start = { 1, 4 },
        expected = {
          'Hello, Vim user',
          'Second line stays.',
        },
        optimal = 12,
        time = 10.0,
        hint = 'a (lowercase) appends after the cursor character',
      }),
      -- Challenge 3: escape back to normal and verify position
      h.editing({
        command = 'iEsc',
        instruction = 'Press i, type "fix", then press Esc to return to Normal mode. The line should now start with "fix".',
        lines = {
          ' the bug here',
        },
        start = { 1, 0 },
        expected = {
          'fix the bug here',
        },
        optimal = 5,
        time = 8.0,
        hint = 'i → type → Esc is the fundamental Insert-mode loop',
      }),
    },
  },

  -- Lesson 4: Text Objects in Vim — word intro (w, b)
  {
    title = 'Text Objects in Vim',
    description = 'w jumps forward to the start of the next word. b jumps backward to the start of the current or previous word. Word boundaries are spaces and punctuation.',
    challenges = {
      -- Challenge 1: jump forward one word
      h.movement({
        command = 'w',
        instruction = 'Move forward by two words to land on "brown".',
        lines = {
          'The quick brown fox.',
        },
        from = { 1, 0 },
        to   = { 1, 10 },
        optimal = 2,
        time = 5.0,
        hint = 'w once → "quick"; w again → "brown"',
      }),
      -- Challenge 2: jump backward with b
      h.movement({
        command = 'b',
        instruction = 'You are on "fox". Jump back two words to land on "quick".',
        lines = {
          'The quick brown fox jumps.',
        },
        from = { 1, 16 },
        to   = { 1, 4 },
        optimal = 2,
        time = 5.0,
        hint = 'b moves to the start of the previous word',
      }),
      -- Challenge 3: w across punctuation
      h.movement({
        command = 'w',
        instruction = 'Jump forward three words from "Pack" to land on "box".',
        lines = {
          'Pack my box with five dozen jugs.',
        },
        from = { 1, 0 },
        to   = { 1, 8 },
        optimal = 2,
        time = 5.0,
        hint = '3w jumps three words in one stroke',
      }),
    },
  },

  -- Lesson 5: Word Based Movement (w, b, e, ge)
  {
    title = 'Word Based Movement',
    description = 'e jumps to the end of the current word. ge jumps backward to the end of the previous word. Combine these four motions (w, b, e, ge) for precise word-level navigation.',
    challenges = {
      -- Challenge 1: land on word end with e
      h.movement({
        command = 'e',
        instruction = 'Jump to the end of the word "quick" (column 8).',
        lines = {
          'The quick brown fox.',
        },
        from = { 1, 4 },
        to   = { 1, 8 },
        optimal = 1,
        time = 4.0,
        hint = 'e from anywhere inside a word jumps to its last character',
      }),
      -- Challenge 2: ge backward to previous word end
      h.movement({
        command = 'ge',
        instruction = 'You are on "brown". Use ge to jump back to the end of "quick" (column 8).',
        lines = {
          'The quick brown fox.',
        },
        from = { 1, 10 },
        to   = { 1, 8 },
        optimal = 2,
        time = 5.0,
        hint = 'ge is two keystrokes: g then e',
      }),
      -- Challenge 3: combine w and e for precision
      h.movement({
        command = 'we',
        instruction = 'From "The", jump to the end of "brown" (column 14) using the fewest keystrokes.',
        lines = {
          'The quick brown fox.',
        },
        from = { 1, 0 },
        to   = { 1, 14 },
        optimal = 4,
        time = 6.0,
        hint = '2we or wwe — reach "brown" with w then land its end with e',
      }),
      -- Challenge 4: full word navigation across a longer line
      h.movement({
        command = 'wbe',
        instruction = 'Navigate from "Pack" (col 0) to land precisely on the end of "dozen" (col 27).',
        lines = {
          'Pack my box with five dozen jugs.',
        },
        from = { 1, 0 },
        to   = { 1, 27 },
        optimal = 4,
        time = 8.0,
        hint = '5e or 5w then e — count words from the start',
      }),
    },
  },
}

return M
