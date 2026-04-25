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
        instruction = 'Copy "greet" to line 2 so it reads "local fn = greet".',
        lines = {
          'function greet(name)',
          'local fn =',
        },
        start = { 1, 9 },
        expected = {
          'function greet(name)',
          'local fn = greet',
        },
        optimal = 7,
        time = 10.0,
        hint = 'yiw yanks "greet". j moves to line 2. Use l or w to reach the end. Then a to append, type a space, Esc, then p to paste.',
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
        optimal = 15,
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


  -- Lesson 3: gn Text Object (dgn, cgn) [advanced]
  {
    title = 'gn Text Object',
    description = 'gn is a text object that matches the next search pattern. dgn deletes it; cgn changes it. Both are dot-repeatable, making multi-match editing trivially fast: search once, then hammer . to repeat.',
    advanced = true,
    challenges = {
      -- Challenge 1: delete next search match with dgn
      h.vim_language({
        command = 'dgn',
        instruction = 'Search /todo then delete the match with dgn',
        lines = {
          'local todo = "buy milk"',
          'local task = "todo: call dentist"',
          'local note = "nothing here"',
        },
        start = { 1, 0 },
        expected = {
          'local  = "buy milk"',
          'local task = "todo: call dentist"',
          'local note = "nothing here"',
        },
        optimal = 9,
        time = 10.0,
        hint = '/todo<CR> positions on first match; dgn deletes that match (3 more keys)',
      }),
      -- Challenge 2: change next match with cgn then dot-repeat
      h.vim_language({
        command = 'cgn',
        instruction = 'Search /foo then change each match to bar with cgn and .',
        lines = {
          'local foo = 1',
          'local foo_count = foo + 1',
        },
        start = { 1, 0 },
        expected = {
          'local bar = 1',
          'local bar_count = bar + 1',
        },
        optimal = 14,
        time = 15.0,
        hint = '/foo<CR>, cgn, type bar, Esc — then . twice to repeat for the remaining matches',
      }),
      -- Challenge 3: dgn is dot-repeatable across matches
      h.vim_language({
        command = 'dgn.',
        instruction = 'Delete every occurrence of "old" using dgn then dot-repeat',
        lines = {
          'old system, old config, old data',
        },
        start = { 1, 0 },
        expected = {
          ' system,  config,  data',
        },
        optimal = 10,
        time = 12.0,
        hint = '/old<CR>, dgn deletes first match — press . twice more for the rest',
      }),
      -- Challenge 4: cgn to rename a variable across a function
      h.vim_language({
        command = 'cgn',
        instruction = 'Rename "val" to "num" throughout the buffer using cgn and .',
        lines = {
          'local val = 0',
          'val = val + 1',
          'return val',
        },
        start = { 1, 0 },
        expected = {
          'local num = 0',
          'num = num + 1',
          'return num',
        },
        optimal = 15,
        time = 20.0,
        hint = '/val<CR>, cgn, num, Esc — press . for each remaining match',
      }),
    },
  },

  -- Lesson 4: Extended Text Objects (dis, dap, dit, dat) [advanced]
  {
    title = 'Extended Text Objects',
    description = 'Vim text objects extend beyond words and brackets. "is" = inner sentence; "ap" = a paragraph (with surrounding blank line); "it" = inner tag content; "at" = a tag (including the tags themselves).',
    advanced = true,
    challenges = {
      -- Challenge 1: delete inner sentence with dis
      h.vim_language({
        command = 'dis',
        instruction = 'Delete the middle sentence with dis',
        lines = {
          'First sentence here.  Remove this one completely.  Last sentence here.',
        },
        start = { 1, 22 },
        expected = {
          'First sentence here.  Last sentence here.',
        },
        optimal = 3,
        time = 6.0,
        hint = 'dis deletes from the start to the end of the current sentence (no surrounding space)',
      }),
      -- Challenge 2: delete a paragraph with dap
      h.vim_language({
        command = 'dap',
        instruction = 'Delete the whole middle paragraph with dap',
        lines = {
          'Keep this paragraph.',
          '',
          'Delete this paragraph.',
          'It has two lines.',
          '',
          'Keep this paragraph too.',
        },
        start = { 3, 0 },
        expected = {
          'Keep this paragraph.',
          '',
          'Keep this paragraph too.',
        },
        optimal = 3,
        time = 6.0,
        hint = 'dap deletes the paragraph the cursor is in plus the surrounding blank line',
      }),
      -- Challenge 3: delete inner tag content with dit
      h.vim_language({
        command = 'dit',
        instruction = 'Clear the tag content with dit leaving <p></p>',
        lines = {
          '<p>Hello, world!</p>',
        },
        start = { 1, 4 },
        expected = {
          '<p></p>',
        },
        optimal = 3,
        time = 6.0,
        hint = 'dit deletes everything between the opening and closing tag — cursor anywhere inside',
      }),
    },
  },
}

return M
