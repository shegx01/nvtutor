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
        instruction = 'Move down to line 4 using j.',
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
        instruction = 'Jump to the last line in one motion using 5j.',
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
        instruction = 'Move up to line 2 using k.',
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
        instruction = 'Reach line 3 using j and k (try overshooting then correcting).',
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
        instruction = 'Move right to the "q" in "quick" using l.',
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
        instruction = 'Move left to the "m" in "my" using h.',
        lines = {
          'Pack my box with five dozen liquor jugs.',
        },
        from = { 1, 10 },
        to   = { 1, 5 },
        optimal = 2,
        time = 5.0,
        hint = '5h moves five characters left',
      }),
      -- Challenge 3: precise column targeting
      h.movement({
        command = 'l',
        instruction = 'Move to the "f" in "fox" using l.',
        lines = {
          'The quick brown fox jumps over the lazy dog.',
        },
        from = { 1, 0 },
        to   = { 1, 16 },
        optimal = 3,
        time = 6.0,
        hint = '16l or break it into chunks',
      }),
      -- Challenge 4: navigate right then back left
      h.movement({
        command = 'hl',
        instruction = 'Land on the "m" in "my" by moving right to "box" then back left with h and l.',
        lines = {
          'Pack my box with five dozen.',
        },
        from = { 1, 0 },
        to   = { 1, 5 },
        optimal = 4,
        time = 8.0,
        hint = '8l reaches column 8, then 3h goes back to column 5 — 4 keystrokes total.',
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
        instruction = 'Turn "Hello world" into "Hello beautiful world". Press i then type: beautiful ',
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
      -- Challenge 2: append text after cursor
      h.editing({
        command = 'a',
        instruction = 'Turn "Hello" into "Hello, Vim user". Press a then type: , Vim user',
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
        hint = 'a enters Insert mode AFTER the character under the cursor. Type ", Vim user" then Esc.',
      }),
      -- Challenge 3: escape back to normal and verify position
      h.editing({
        command = 'iEsc',
        instruction = 'Turn " the bug here" into "fix the bug here". Press i then type: fix',
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
        instruction = 'Jump to "brown" using w.',
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
        instruction = 'Jump back to "quick" using b.',
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
        instruction = 'Jump to "box" using w.',
        lines = {
          'Pack my box with five dozen jugs.',
        },
        from = { 1, 0 },
        to   = { 1, 8 },
        optimal = 2,
        time = 5.0,
        hint = '2w jumps two words in one stroke',
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
        instruction = 'Jump to the end of "quick" using e.',
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
        instruction = 'Jump back to the end of "quick" using ge.',
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
        instruction = 'Jump to the end of "brown" using w and e.',
        lines = {
          'The quick brown fox.',
        },
        from = { 1, 0 },
        to   = { 1, 14 },
        optimal = 2,
        time = 6.0,
        hint = '3e jumps to the end of the third word — just 2 keystrokes!',
      }),
      -- Challenge 4: full word navigation across a longer line
      h.movement({
        command = 'wbe',
        instruction = 'Jump to the end of "dozen" using w, b, and e.',
        lines = {
          'Pack my box with five dozen jugs.',
        },
        from = { 1, 0 },
        to   = { 1, 26 },
        optimal = 2,
        time = 8.0,
        hint = '5e or 5w then e — count words from the start',
      }),
    },
  },


  -- Lesson 6: Screen Positioning (H, M, L, zz, zt, zb) [advanced]
  {
    title = 'Screen Positioning',
    description = 'H, M, L jump the cursor to the top, middle, and bottom of the visible screen without scrolling. zz centers the screen on the cursor; zt scrolls the cursor to the top; zb scrolls it to the bottom.',
    advanced = true,
    challenges = {
      -- Challenge 1: jump to middle of screen with M
      h.movement({
        command = 'M',
        instruction = 'Jump to screen middle with M',
        lines = {
          'Line  1: The quick brown fox jumps over the lazy dog.',
          'Line  2: Pack my box with five dozen liquor jugs.',
          'Line  3: How vexingly quick daft zebras jump.',
          'Line  4: The five boxing wizards jump quickly.',
          'Line  5: Jinxed wizards pluck ivy from the big quilt.',
          'Line  6: Bright vixens jump; dozy fowl quack.',
          'Line  7: Waltz, bad nymph, for quick jigs vex.',
          'Line  8: Sphinx of black quartz, judge my vow.',
          'Line  9: Two driven jocks help fax my big quiz.',
          'Line 10: The jay, pig, fox, zebra and my wolves quack!',
          'Line 11: The quick brown fox jumps over the lazy dog.',
          'Line 12: Pack my box with five dozen liquor jugs.',
          'Line 13: How vexingly quick daft zebras jump.',
          'Line 14: The five boxing wizards jump quickly.',
          'Line 15: Jinxed wizards pluck ivy from the big quilt.',
          'Line 16: Bright vixens jump; dozy fowl quack.',
          'Line 17: Waltz, bad nymph, for quick jigs vex.',
          'Line 18: Sphinx of black quartz, judge my vow.',
          'Line 19: Two driven jocks help fax my big quiz.',
          'Line 20: The jay, pig, fox, zebra and my wolves quack!',
        },
        from = { 1, 0 },
        to   = { 10, 0 },
        optimal = 1,
        time = 4.0,
        hint = 'M moves the cursor to the middle line of the visible window',
        optimal_solution = 'M — jump to middle of screen',
      }),
      -- Challenge 2: jump to top of screen with H
      h.movement({
        command = 'H',
        instruction = 'Jump to screen top with H',
        lines = {
          'Line  1: The quick brown fox jumps over the lazy dog.',
          'Line  2: Pack my box with five dozen liquor jugs.',
          'Line  3: How vexingly quick daft zebras jump.',
          'Line  4: The five boxing wizards jump quickly.',
          'Line  5: Jinxed wizards pluck ivy from the big quilt.',
          'Line  6: Bright vixens jump; dozy fowl quack.',
          'Line  7: Waltz, bad nymph, for quick jigs vex.',
          'Line  8: Sphinx of black quartz, judge my vow.',
          'Line  9: Two driven jocks help fax my big quiz.',
          'Line 10: The jay, pig, fox, zebra and my wolves quack!',
          'Line 11: The quick brown fox jumps over the lazy dog.',
          'Line 12: Pack my box with five dozen liquor jugs.',
          'Line 13: How vexingly quick daft zebras jump.',
          'Line 14: The five boxing wizards jump quickly.',
          'Line 15: Jinxed wizards pluck ivy from the big quilt.',
          'Line 16: Bright vixens jump; dozy fowl quack.',
          'Line 17: Waltz, bad nymph, for quick jigs vex.',
          'Line 18: Sphinx of black quartz, judge my vow.',
          'Line 19: Two driven jocks help fax my big quiz.',
          'Line 20: The jay, pig, fox, zebra and my wolves quack!',
        },
        from = { 10, 0 },
        to   = { 1, 0 },
        optimal = 1,
        time = 4.0,
        hint = 'H places the cursor on the topmost visible line',
        optimal_solution = 'H — jump to top of screen',
      }),
      -- Challenge 3: jump to bottom of screen with L
      h.movement({
        command = 'L',
        instruction = 'Jump to screen bottom with L',
        lines = {
          'Line  1: The quick brown fox jumps over the lazy dog.',
          'Line  2: Pack my box with five dozen liquor jugs.',
          'Line  3: How vexingly quick daft zebras jump.',
          'Line  4: The five boxing wizards jump quickly.',
          'Line  5: Jinxed wizards pluck ivy from the big quilt.',
          'Line  6: Bright vixens jump; dozy fowl quack.',
          'Line  7: Waltz, bad nymph, for quick jigs vex.',
          'Line  8: Sphinx of black quartz, judge my vow.',
          'Line  9: Two driven jocks help fax my big quiz.',
          'Line 10: The jay, pig, fox, zebra and my wolves quack!',
          'Line 11: The quick brown fox jumps over the lazy dog.',
          'Line 12: Pack my box with five dozen liquor jugs.',
          'Line 13: How vexingly quick daft zebras jump.',
          'Line 14: The five boxing wizards jump quickly.',
          'Line 15: Jinxed wizards pluck ivy from the big quilt.',
          'Line 16: Bright vixens jump; dozy fowl quack.',
          'Line 17: Waltz, bad nymph, for quick jigs vex.',
          'Line 18: Sphinx of black quartz, judge my vow.',
          'Line 19: Two driven jocks help fax my big quiz.',
          'Line 20: The jay, pig, fox, zebra and my wolves quack!',
        },
        from = { 1, 0 },
        to   = { 20, 0 },
        optimal = 1,
        time = 4.0,
        hint = 'L places the cursor on the bottommost visible line',
        optimal_solution = 'L — jump to bottom of screen',
      }),
      -- Challenge 4: use zt to scroll cursor to top, then H to verify
      h.movement({
        command = 'zt',
        instruction = 'Scroll so the cursor line is at the top using zt, then jump to line 1 with gg.',
        lines = {
          'Line  1: The quick brown fox jumps over the lazy dog.',
          'Line  2: Pack my box with five dozen liquor jugs.',
          'Line  3: How vexingly quick daft zebras jump.',
          'Line  4: The five boxing wizards jump quickly.',
          'Line  5: Jinxed wizards pluck ivy from the big quilt.',
          'Line  6: Bright vixens jump; dozy fowl quack.',
          'Line  7: Waltz, bad nymph, for quick jigs vex.',
          'Line  8: Sphinx of black quartz, judge my vow.',
          'Line  9: Two driven jocks help fax my big quiz.',
          'Line 10: The jay, pig, fox, zebra and my wolves quack!',
          'Line 11: The quick brown fox jumps over the lazy dog.',
          'Line 12: Pack my box with five dozen liquor jugs.',
          'Line 13: How vexingly quick daft zebras jump.',
          'Line 14: The five boxing wizards jump quickly.',
          'Line 15: Jinxed wizards pluck ivy from the big quilt.',
          'Line 16: Bright vixens jump; dozy fowl quack.',
          'Line 17: Waltz, bad nymph, for quick jigs vex.',
          'Line 18: Sphinx of black quartz, judge my vow.',
          'Line 19: Two driven jocks help fax my big quiz.',
          'Line 20: The jay, pig, fox, zebra and my wolves quack!',
        },
        from = { 10, 0 },
        to   = { 1, 0 },
        optimal = 4,
        time = 5.0,
        hint = 'zt scrolls the view so cursor is at the top of the screen. Then gg jumps to line 1.',
        optimal_solution = 'zt then gg',
      }),
    },
  },

  -- Lesson 7: Page Navigation (Ctrl-f, Ctrl-b, Ctrl-d, Ctrl-u) [advanced]
  {
    title = 'Page Navigation',
    description = 'Ctrl-f scrolls a full page forward; Ctrl-b scrolls a full page back. Ctrl-d scrolls half a page down; Ctrl-u scrolls half a page up. These keep context visible while covering large distances fast.',
    advanced = true,
    challenges = {
      -- Challenge 1: full page forward with Ctrl-f
      h.movement({
        command = '<C-f>',
        instruction = 'Scroll a full page forward with Ctrl-f',
        lines = {
          'Line  1: The quick brown fox jumps over the lazy dog.',
          'Line  2: Pack my box with five dozen liquor jugs.',
          'Line  3: How vexingly quick daft zebras jump.',
          'Line  4: The five boxing wizards jump quickly.',
          'Line  5: Jinxed wizards pluck ivy from the big quilt.',
          'Line  6: Bright vixens jump; dozy fowl quack.',
          'Line  7: Waltz, bad nymph, for quick jigs vex.',
          'Line  8: Sphinx of black quartz, judge my vow.',
          'Line  9: Two driven jocks help fax my big quiz.',
          'Line 10: The jay, pig, fox, zebra and my wolves quack!',
          'Line 11: The quick brown fox jumps over the lazy dog.',
          'Line 12: Pack my box with five dozen liquor jugs.',
          'Line 13: How vexingly quick daft zebras jump.',
          'Line 14: The five boxing wizards jump quickly.',
          'Line 15: Jinxed wizards pluck ivy from the big quilt.',
          'Line 16: Bright vixens jump; dozy fowl quack.',
          'Line 17: Waltz, bad nymph, for quick jigs vex.',
          'Line 18: Sphinx of black quartz, judge my vow.',
          'Line 19: Two driven jocks help fax my big quiz.',
          'Line 20: The jay, pig, fox, zebra and my wolves quack!',
          'Line 21: The quick brown fox jumps over the lazy dog.',
          'Line 22: Pack my box with five dozen liquor jugs.',
          'Line 23: How vexingly quick daft zebras jump.',
          'Line 24: The five boxing wizards jump quickly.',
          'Line 25: Jinxed wizards pluck ivy from the big quilt.',
        },
        from = { 1, 0 },
        to   = { 25, 0 },
        optimal = 2,
        time = 5.0,
        hint = 'Ctrl-f scrolls a full page forward — hold Ctrl and press f',
        optimal_solution = 'Ctrl-f — scroll full page forward',
      }),
      -- Challenge 2: full page back with Ctrl-b
      h.movement({
        command = '<C-b>',
        instruction = 'Scroll a full page back with Ctrl-b',
        lines = {
          'Line  1: The quick brown fox jumps over the lazy dog.',
          'Line  2: Pack my box with five dozen liquor jugs.',
          'Line  3: How vexingly quick daft zebras jump.',
          'Line  4: The five boxing wizards jump quickly.',
          'Line  5: Jinxed wizards pluck ivy from the big quilt.',
          'Line  6: Bright vixens jump; dozy fowl quack.',
          'Line  7: Waltz, bad nymph, for quick jigs vex.',
          'Line  8: Sphinx of black quartz, judge my vow.',
          'Line  9: Two driven jocks help fax my big quiz.',
          'Line 10: The jay, pig, fox, zebra and my wolves quack!',
          'Line 11: The quick brown fox jumps over the lazy dog.',
          'Line 12: Pack my box with five dozen liquor jugs.',
          'Line 13: How vexingly quick daft zebras jump.',
          'Line 14: The five boxing wizards jump quickly.',
          'Line 15: Jinxed wizards pluck ivy from the big quilt.',
          'Line 16: Bright vixens jump; dozy fowl quack.',
          'Line 17: Waltz, bad nymph, for quick jigs vex.',
          'Line 18: Sphinx of black quartz, judge my vow.',
          'Line 19: Two driven jocks help fax my big quiz.',
          'Line 20: The jay, pig, fox, zebra and my wolves quack!',
          'Line 21: The quick brown fox jumps over the lazy dog.',
          'Line 22: Pack my box with five dozen liquor jugs.',
          'Line 23: How vexingly quick daft zebras jump.',
          'Line 24: The five boxing wizards jump quickly.',
          'Line 25: Jinxed wizards pluck ivy from the big quilt.',
        },
        from = { 25, 0 },
        to   = { 1, 0 },
        optimal = 2,
        time = 5.0,
        hint = 'Ctrl-b scrolls a full page backward — the opposite of Ctrl-f',
        optimal_solution = 'Ctrl-b — scroll full page back',
      }),
      -- Challenge 3: half page down with Ctrl-d (open-ended — any reasonable landing is valid)
      h.movement({
        command = '<C-d>',
        instruction = 'Scroll half a page down with Ctrl-d',
        lines = {
          'Line  1: The quick brown fox jumps over the lazy dog.',
          'Line  2: Pack my box with five dozen liquor jugs.',
          'Line  3: How vexingly quick daft zebras jump.',
          'Line  4: The five boxing wizards jump quickly.',
          'Line  5: Jinxed wizards pluck ivy from the big quilt.',
          'Line  6: Bright vixens jump; dozy fowl quack.',
          'Line  7: Waltz, bad nymph, for quick jigs vex.',
          'Line  8: Sphinx of black quartz, judge my vow.',
          'Line  9: Two driven jocks help fax my big quiz.',
          'Line 10: The jay, pig, fox, zebra and my wolves quack!',
          'Line 11: The quick brown fox jumps over the lazy dog.',
          'Line 12: Pack my box with five dozen liquor jugs.',
          'Line 13: How vexingly quick daft zebras jump.',
          'Line 14: The five boxing wizards jump quickly.',
          'Line 15: Jinxed wizards pluck ivy from the big quilt.',
          'Line 16: Bright vixens jump; dozy fowl quack.',
          'Line 17: Waltz, bad nymph, for quick jigs vex.',
          'Line 18: Sphinx of black quartz, judge my vow.',
          'Line 19: Two driven jocks help fax my big quiz.',
          'Line 20: The jay, pig, fox, zebra and my wolves quack!',
        },
        from = { 1, 0 },
        to   = { 10, 0 },
        optimal = 2,
        time = 5.0,
        hint = 'Ctrl-d moves down by half the window height — the exact distance depends on your window size',
        optimal_solution = 'Ctrl-d — scroll half page down',
      }),
    },
  },
}

return M
