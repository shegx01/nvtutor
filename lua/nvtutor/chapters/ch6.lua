local h = require('nvtutor.chapters.helpers')
local M = {}

M.title = 'Document Navigation'
M.description = 'Fly through files with whole-document, line-number, and paragraph motions.'

-- ─── shared buffer content ────────────────────────────────────────────────────

local doc_lines = {
  '# Project Architecture',
  '',
  'This document describes the high-level architecture of the application.',
  'Each module is responsible for a single concern.',
  '',
  '## Core Modules',
  '',
  'The engine module drives the main event loop.',
  'The ui module renders panels and handles user input.',
  'The progress module persists session state to disk.',
  '',
  '## Data Flow',
  '',
  'Requests arrive at the router, which dispatches to handlers.',
  'Handlers validate input, call the service layer, and return responses.',
  'The service layer coordinates domain logic and persistence.',
  '',
  '## Testing Strategy',
  '',
  'Unit tests cover individual functions in isolation.',
  'Integration tests verify module boundaries.',
  'End-to-end tests run the full application stack.',
  '',
  '## Deployment',
  '',
  'The application ships as a single binary.',
  'Configuration is loaded from environment variables.',
  'Logs are written to stdout in JSON format.',
}

local numbered_lines = {
  'line  1: alpha   = 1',
  'line  2: beta    = 2',
  'line  3: gamma   = 3',
  'line  4: delta   = 4',
  'line  5: epsilon = 5',
  'line  6: zeta    = 6',
  'line  7: eta     = 7',
  'line  8: theta   = 8',
  'line  9: iota    = 9',
  'line 10: kappa   = 10',
  'line 11: lambda  = 11',
  'line 12: mu      = 12',
  'line 13: nu      = 13',
  'line 14: xi      = 14',
  'line 15: omicron = 15',
  'line 16: pi      = 16',
  'line 17: rho     = 17',
  'line 18: sigma   = 18',
  'line 19: tau     = 19',
  'line 20: upsilon = 20',
}

local para_lines = {
  'First paragraph opens with a strong thesis.',
  'It develops the argument over several sentences.',
  'The closing sentence ties back to the thesis.',
  '',
  'Second paragraph introduces supporting evidence.',
  'Data and citations strengthen the claim.',
  'A transition connects to the next idea.',
  '',
  'Third paragraph explores a counterargument.',
  'The author acknowledges opposing views fairly.',
  'A rebuttal restores the original position.',
  '',
  'Fourth paragraph summarises the key points.',
  'It reinforces why the thesis holds.',
  'The final sentence leaves a lasting impression.',
}

-- ─── Lesson 1 — Document Movements (gg, G, Ctrl-d, Ctrl-u) ───────────────────

local lesson1 = {
  title = 'Document Movements',
  explanation = {
    'gg          — jump to the very first line of the buffer.',
    'G           — jump to the very last line of the buffer.',
    'Ctrl-d      — scroll down half a screen (cursor moves with the view).',
    'Ctrl-u      — scroll up half a screen.',
    '',
    'These are your long-range navigation tools.',
    'Use gg/G to teleport to the top or bottom instantly.',
    'Use Ctrl-d / Ctrl-u to page through large files efficiently.',
  },
  challenges = {
    -- 1. G to last line
    h.movement({
      command = 'G',
      instruction = 'Jump to the last line of the document with G',
      lines = doc_lines,
      from = { 1, 0 },
      to   = { 28, 0 },
      optimal = 1,
      hint = 'G with no count always moves to the final line.',
    }),
    -- 2. gg to first line
    h.movement({
      command = 'gg',
      instruction = 'Jump to the first line with gg',
      lines = doc_lines,
      from = { 28, 0 },
      to   = { 1, 0 },
      optimal = 2,
      hint = 'gg is a two-key motion. Do not confuse it with G.',
    }),
    -- 3. Ctrl-d scrolls down (cursor moves mid-screen)
    h.movement({
      command = '<C-d>',
      instruction = 'Scroll down half a screen with Ctrl-d',
      lines = doc_lines,
      from = { 1, 0 },
      to   = { 15, 0 },
      optimal = 1,
      hint = 'Ctrl-d moves the cursor down by half the window height.',
    }),
    -- 4. Ctrl-u scrolls up
    h.movement({
      command = '<C-u>',
      instruction = 'Scroll up half a screen with Ctrl-u',
      lines = doc_lines,
      from = { 28, 0 },
      to   = { 14, 0 },
      optimal = 1,
      hint = 'Ctrl-u is the counterpart to Ctrl-d.',
    }),
    -- 5. Chain: G then gg
    h.movement({
      command = 'G',
      instruction = 'Jump to the bottom with G then back to the top with gg',
      lines = doc_lines,
      from = { 12, 0 },
      to   = { 1, 0 },
      optimal = 3,   -- G, gg
      hint = 'G jumps to the bottom (1 key), gg snaps you back to the top (2 keys). Three keystrokes total.',
    }),
  },
}

-- ─── Lesson 2 — Line Number Movement ({n}G, {n}gg) ───────────────────────────

local lesson2 = {
  title = 'Line Number Movement',
  explanation = {
    '{n}G   — jump to line number n  (e.g. 10G → line 10).',
    '{n}gg  — same as {n}G (works in most Vim distributions).',
    '',
    'These are precise teleport motions.',
    'Combine with :set number or :set relativenumber to see line numbers in the gutter.',
    '',
    'Example: 5G  → line 5,  20G → line 20.',
  },
  challenges = {
    -- 1. Jump to line 5
    h.movement({
      command = 'G',
      instruction = 'Jump to line 5 with 5G',
      lines = numbered_lines,
      from = { 1, 0 },
      to   = { 5, 0 },
      optimal = 2,   -- 5G
      hint = 'Type the count before G: 5G.',
    }),
    -- 2. Jump to line 13
    h.movement({
      command = 'G',
      instruction = 'Jump to line 13 with 13G',
      lines = numbered_lines,
      from = { 1, 0 },
      to   = { 13, 0 },
      optimal = 3,   -- 1, 3, G
      hint = '13G — type 1, 3, then G.',
    }),
    -- 3. Jump to line 20
    h.movement({
      command = 'G',
      instruction = 'Jump to the last line with 20G',
      lines = numbered_lines,
      from = { 1, 0 },
      to   = { 20, 0 },
      optimal = 3,   -- 2, 0, G
      hint = '20G — three keystrokes: 2, 0, G.',
    }),
    -- 4. Jump using gg with count
    h.movement({
      command = 'gg',
      instruction = 'Jump to line 7 with 7gg',
      lines = numbered_lines,
      from = { 20, 0 },
      to   = { 7, 0 },
      optimal = 3,   -- 7, g, g
      hint = '7gg is equivalent to 7G in most Vim builds.',
    }),
    -- 5. Relative jump: from middle to near top
    h.movement({
      command = 'G',
      instruction = 'Jump back to line 3 with 3G',
      lines = numbered_lines,
      from = { 15, 0 },
      to   = { 3, 0 },
      optimal = 2,
      hint = '3G — two keystrokes: 3, G.',
    }),
  },
}

-- ─── Lesson 3 — Paragraph Navigation ({, }) ──────────────────────────────────

local lesson3 = {
  title = 'Paragraph Navigation',
  explanation = {
    '}  — jump forward to the next empty line (next paragraph boundary).',
    '{  — jump backward to the previous empty line.',
    '',
    'A "paragraph" in Vim is any block of non-empty lines separated by blank lines.',
    'These motions work in code too: jump between function definitions or sections.',
    '',
    'Compose with verbs: d}  deletes from cursor to the next paragraph end.',
  },
  challenges = {
    -- 1. } forward one paragraph
    h.movement({
      command = '}',
      instruction = 'Jump to the blank line after the first paragraph with }',
      lines = para_lines,
      from = { 1, 0 },
      to   = { 4, 0 },   -- blank line between paragraph 1 and 2
      optimal = 1,
      hint = '} lands on the blank line that ends the paragraph.',
    }),
    -- 2. } forward two paragraphs
    h.movement({
      command = '}',
      instruction = 'Jump forward two paragraphs with }} to reach line 8',
      lines = para_lines,
      from = { 1, 0 },
      to   = { 8, 0 },
      optimal = 2,
      hint = 'Each } advances one paragraph. Press it twice.',
    }),
    -- 3. { backward
    h.movement({
      command = '{',
      instruction = 'Jump back to the blank line before this paragraph with {',
      lines = para_lines,
      from = { 13, 0 },
      to   = { 12, 0 },
      optimal = 1,
      hint = '{ moves to the blank line that precedes the current paragraph.',
    }),
    -- 4. { backward multiple
    h.movement({
      command = '{',
      instruction = 'Jump back to line 1 by pressing { four times',
      lines = para_lines,
      from = { 15, 0 },
      to   = { 1, 0 },
      optimal = 4,
      hint = '{ jumps to each blank line boundary, then to the start of the buffer. Four presses: line 12 → 8 → 4 → 1.',
    }),
    -- 5. d} to delete to next paragraph
    h.vim_language({
      command = 'd}',
      instruction = 'Delete the second paragraph with d}',
      lines = para_lines,
      start = { 5, 0 },
      expected = {
        'First paragraph opens with a strong thesis.',
        'It develops the argument over several sentences.',
        'The closing sentence ties back to the thesis.',
        '',
        '',
        'Third paragraph explores a counterargument.',
        'The author acknowledges opposing views fairly.',
        'A rebuttal restores the original position.',
        '',
        'Fourth paragraph summarises the key points.',
        'It reinforces why the thesis holds.',
        'The final sentence leaves a lasting impression.',
      },
      optimal = 2,
      hint = 'd} deletes from the cursor through the blank line that ends the next paragraph block.',
    }),
  },
}

-- ─── Lesson 4 — Local Marks (ma, 'a, `a) ────────────────────────────────────

local mark_lines = {
  'Section A: Introduction',
  'This section covers the basics of the system.',
  'Read this before proceeding to any other section.',
  '',
  'Section B: Configuration',
  'Set the options in config.lua before first run.',
  'Restart the server after any configuration change.',
  '',
  'Section C: Troubleshooting',
  'Check the logs at /var/log/app.log first.',
  'Common issues are listed in the FAQ document.',
}

local lesson4 = {
  title = 'Local Marks',
  description = 'Drop named pins in the buffer and teleport back to them instantly.',
  advanced = true,
  explanation = {
    'm{a-z}  — set a local mark at the current cursor position.',
    "'a      — jump to the first non-blank character on the line of mark a.",
    '`a      — jump to the exact line AND column of mark a.',
    '',
    'Marks persist for the lifetime of the buffer.',
    'Use lowercase letters (a–z) for marks within one file.',
    '',
    'Workflow: mark a reference point, navigate away, then snap back with `a.',
  },
  challenges = {
    -- 1. Set mark and jump to line
    h.movement({
      command = 'ma',
      instruction = "Set mark a on line 1, move to line 9, jump back with 'a",
      lines = mark_lines,
      from = { 9, 0 },
      to   = { 1, 0 },
      optimal = 5,   -- m a G ' a  (set at line 1 conceptually; test starts at 9)
      hint = "ma sets the mark. 'a jumps to the line where the mark was set.",
      optimal_solution = "'a",
    }),
    -- 2. Exact column jump with `a
    h.movement({
      command = '`a',
      instruction = 'Jump to the exact column of mark a with `a',
      lines = mark_lines,
      from = { 11, 0 },
      to   = { 6, 4 },   -- col 4: 'S' of 'Set'
      optimal = 2,
      hint = '`a (backtick-a) restores both line and column, unlike \'a which goes to first non-blank.',
      optimal_solution = '`a',
    }),
    -- 3. Set mark, navigate away, return
    h.movement({
      command = 'mb',
      instruction = "Mark line 5 with mb, go to line 11, return with 'b",
      lines = mark_lines,
      from = { 11, 0 },
      to   = { 5, 0 },
      optimal = 3,   -- ' b
      hint = "Any lowercase letter works as a mark name. 'b jumps to the line of mark b.",
      optimal_solution = "'b",
    }),
  },
}

-- ─── Lesson 5 — Global Marks (mA, 'A) ────────────────────────────────────────

local lesson5 = {
  title = 'Global Marks',
  description = 'Global marks persist across files — learn the concept with uppercase letters.',
  advanced = true,
  explanation = {
    'm{A-Z}  — set a global mark (uppercase letter).',
    "'A      — jump to the line of global mark A (even across files).",
    '`A      — jump to exact position of global mark A.',
    '',
    'Global marks persist between Vim sessions (stored in viminfo/shada).',
    'In this single-buffer tutorial we practise the same motions with uppercase marks.',
    '',
    'Use case: mark the entry-point of a file with mM, then jump back with `M',
    'from anywhere in your project.',
  },
  challenges = {
    -- 1. Set global mark and jump back
    h.movement({
      command = 'mA',
      instruction = "Set global mark A on line 1, navigate to line 9, jump back with 'A",
      lines = mark_lines,
      from = { 9, 0 },
      to   = { 1, 0 },
      optimal = 3,
      hint = "mA sets the global mark. 'A jumps back. In real use this works across files.",
      optimal_solution = "'A",
    }),
    -- 2. Exact position jump with `A
    h.movement({
      command = '`A',
      instruction = 'Jump to exact position of global mark A with `A',
      lines = mark_lines,
      from = { 11, 5 },
      to   = { 5, 0 },
      optimal = 2,
      hint = '`A restores both line and column — the precise cursor position.',
      optimal_solution = '`A',
    }),
    -- 3. Use global mark as a cross-section anchor
    h.movement({
      command = 'mB',
      instruction = "Mark Section B header with mB, scroll to line 11, return with 'B",
      lines = mark_lines,
      from = { 11, 0 },
      to   = { 5, 0 },
      optimal = 3,
      hint = "Global marks work identically to local marks inside one buffer. 'B returns to line 5.",
      optimal_solution = "'B",
    }),
  },
}

-- ─── Lesson 6 — Jump & Change Lists (Ctrl-o, Ctrl-i, g;, g,) ─────────────────

local jump_lines = {
  'function setup(config)',
  '  local opts = config or {}',
  '  opts.debug   = opts.debug or false',
  '  opts.timeout = opts.timeout or 30',
  '  return opts',
  'end',
  '',
  'function teardown(state)',
  '  state.active = false',
  '  state.data   = nil',
  '  return state',
  'end',
  '',
  'local cfg   = setup({ debug = true })',
  'local state = teardown({ active = true, data = {} })',
}

local lesson6 = {
  title = 'Jump & Change Lists',
  description = 'Navigate your editing history forward and back with Ctrl-o, Ctrl-i, g; and g,.',
  advanced = true,
  explanation = {
    'Ctrl-o  — jump back in the jump list (previous cursor location).',
    'Ctrl-i  — jump forward in the jump list.',
    'g;      — go to the previous change location.',
    'g,      — go to the next change location.',
    '',
    'The jump list records every time you teleport (G, /, *, marks, etc.).',
    'The change list records every position where the buffer was modified.',
    '',
    'Ctrl-o/Ctrl-i navigate WHERE you were.',
    'g; / g, navigate WHERE you edited.',
  },
  challenges = {
    -- 1. Ctrl-o to jump back
    h.movement({
      command = '<C-o>',
      instruction = 'After jumping to line 14 with G, press Ctrl-o to return to line 1',
      lines = jump_lines,
      from = { 14, 0 },
      to   = { 1, 0 },
      optimal = 1,
      hint = 'Ctrl-o pops the jump stack back one position. Here it returns you to line 1.',
      optimal_solution = '<C-o>',
    }),
    -- 2. Ctrl-i to jump forward
    h.movement({
      command = '<C-i>',
      instruction = 'After jumping back with Ctrl-o, press Ctrl-i to jump forward again',
      lines = jump_lines,
      from = { 1, 0 },
      to   = { 14, 0 },
      optimal = 1,
      hint = 'Ctrl-i moves forward through the jump list — the reverse of Ctrl-o.',
      optimal_solution = '<C-i>',
    }),
    -- 3. g; to previous change
    h.movement({
      command = 'g;',
      instruction = 'Press g; to jump to the most recent change location',
      lines = jump_lines,
      from = { 15, 0 },
      to   = { 3, 9 },   -- last-edited position: 'debug' on line 3
      optimal = 2,
      hint = 'g; takes you to where the buffer was last changed, regardless of where you navigated.',
      optimal_solution = 'g;',
    }),
  },
}

M.lessons = { lesson1, lesson2, lesson3, lesson4, lesson5, lesson6 }

return M
