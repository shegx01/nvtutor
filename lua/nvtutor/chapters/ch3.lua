local h = require('nvtutor.chapters.helpers')
local M = {}

M.title = 'The Vim Language'
M.description = 'Vim commands compose like a language: Verb + (Modifier) + Text Object. Once you internalise this grammar, you can express almost any edit in two or three keystrokes.'

M.lessons = {
  -- Lesson 1: Verb + Text Object (diw, daw, ciw, yiw, etc.)
  {
    title = 'Verb + Text Object',
    description = 'Text objects let operators act on a meaningful chunk of text. "iw" = inner word (no surrounding space); "aw" = a word (includes surrounding space). Combine with d (delete), c (change), y (yank), and more.',
    challenges = {
      -- Challenge 1: diw — delete inner word
      h.vim_language({
        command = 'diw',
        instruction = 'Delete the word "ugly" (leaving the spaces) using diw.',
        lines = {
          'Remove the ugly comment now.',
        },
        start = { 1, 11 },
        expected = {
          'Remove the  comment now.',
        },
        optimal = 3,
        time = 6.0,
        hint = 'diw = delete inner word — works from anywhere inside the word',
      }),
      -- Challenge 2: daw — delete a word (with space)
      h.vim_language({
        command = 'daw',
        instruction = 'Delete "very" and its space to get "This is important." using daw.',
        lines = {
          'This is very important.',
        },
        start = { 1, 8 },
        expected = {
          'This is important.',
        },
        optimal = 3,
        time = 6.0,
        hint = 'daw = delete a word — absorbs one surrounding space automatically',
      }),
      -- Challenge 3: ciw — change inner word
      h.vim_language({
        command = 'ciw',
        instruction = 'Change "foo" to "result" using ciw.',
        lines = {
          'local foo = compute()',
        },
        start = { 1, 6 },
        expected = {
          'local result = compute()',
        },
        optimal = 10,
        time = 8.0,
        hint = 'ciw deletes the word and drops you into Insert mode. Type the replacement then Esc.',
      }),
      -- Challenge 4: yiw — yank inner word and paste
      h.vim_language({
        command = 'yiw',
        instruction = 'Add "greet" at the end of line 2. Yank it with yiw then paste at end of line 2.',
        lines = {
          'function greet(name)',
          'local fn = ',
        },
        start = { 1, 9 },
        expected = {
          'function greet(name)',
          'local fn = greet',
        },
        optimal = 6,
        time = 10.0,
        hint = 'yiw yanks just the word; then navigate to line 2 end and p to paste',
      }),
      -- Challenge 5: ciw on a number
      h.vim_language({
        command = 'ciw',
        instruction = 'Change the timeout from 100 to 500 using ciw.',
        lines = {
          'local timeout = 100',
          'local retries = 3',
        },
        start = { 1, 16 },
        expected = {
          'local timeout = 500',
          'local retries = 3',
        },
        optimal = 7,
        time = 6.0,
        hint = 'ciw works on any sequence of word characters, including numbers. Don\'t forget Esc!',
      }),
    },
  },

  -- Lesson 2: Verb + Modifier + Text Object (di(, ci", da[, etc.)
  {
    title = 'Verb + Modifier + Text Object',
    description = 'Modifier "i" means "inner" (inside the delimiters, not including them). Modifier "a" means "a" (including the delimiters themselves). Works with (, ), {, }, [, ], ", \', `, and more.',
    challenges = {
      -- Challenge 1: di( — delete inside parentheses
      h.vim_language({
        command = 'di(',
        instruction = 'Clear the arguments to get greet() using di(.',
        lines = {
          'greet("Alice", "Bob")',
        },
        start = { 1, 7 },
        expected = {
          'greet()',
        },
        optimal = 3,
        time = 6.0,
        hint = 'di( deletes everything between the nearest ( and ) — cursor can be anywhere inside',
      }),
      -- Challenge 2: ci" — change inside double quotes
      h.vim_language({
        command = 'ci"',
        instruction = 'Change "old" to "new" inside the quotes using ci".',
        lines = {
          'local msg = "old"',
        },
        start = { 1, 13 },
        expected = {
          'local msg = "new"',
        },
        optimal = 7,
        time = 8.0,
        hint = 'ci" clears between the quotes and enters Insert mode. Type "new" then Esc.',
      }),
      -- Challenge 3: da[ — delete a bracket (including brackets)
      h.vim_language({
        command = 'da[',
        instruction = 'Delete "[1, 2, 3]" including brackets using da[.',
        lines = {
          'local nums = [1, 2, 3]',
        },
        start = { 1, 14 },
        expected = {
          'local nums = ',
        },
        optimal = 3,
        time = 6.0,
        hint = 'da[ deletes inside the brackets AND the [ ] themselves',
      }),
      -- Challenge 4: ci{ — change inside curly braces
      h.vim_language({
        command = 'ci{',
        instruction = 'Change the table body to "ok = true" using ci{.',
        lines = {
          'local t = { x = 1, y = 2 }',
        },
        start = { 1, 12 },
        expected = {
          'local t = { ok = true }',
        },
        optimal = 13,
        time = 12.0,
        hint = 'ci{ clears inside { } and enters Insert mode. Type " ok = true " then Esc.',
      }),
      -- Challenge 5: di' — delete inside single quotes
      h.vim_language({
        command = "di'",
        instruction = "Clear 'insert' to get an empty '' using di'.",
        lines = {
          "local mode = 'insert'",
        },
        start = { 1, 14 },
        expected = {
          "local mode = ''",
        },
        optimal = 3,
        time = 5.0,
        hint = "di' removes the text between the nearest pair of single quotes",
      }),
    },
  },
}

return M
