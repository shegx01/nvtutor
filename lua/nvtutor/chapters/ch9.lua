local h = require('nvtutor.chapters.helpers')
local M = {}

-- NOTE: All lessons in Ch9 are advanced = true. This means all_basic_complete(9)
-- returns true unconditionally, so all lessons are selectable as soon as Ch9 is
-- unlocked. Adding a non-advanced lesson here would change the gating behavior.

M.title = 'Vim Tricks'
M.description = 'Level up with the cgn formula, surgical bulk edits, quick fixes, and config superpowers.'

-- ─── shared buffer content ────────────────────────────────────────────────────

local http_lines = {
  'The API endpoint is http not https.',
  'The fallback URL uses http as well.',
  'All internal calls also use http for now.',
  'We must update every http reference before launch.',
}

local typo_lines = {
  'Recieve the messaeg from teh sender.',
  'Teh quick brown fox jumps over teh dog.',
  'Do nto forget to chekc teh output.',
}

local number_block = {
  '1',
  '2',
  '3',
  '4',
  '5',
}

local debug_lines = {
  'INFO: server started on port 8080',
  'DEBUG: connecting to database',
  'ERROR: failed to authenticate user',
  'DEBUG: retrying connection attempt 1',
  'INFO: request received from 127.0.0.1',
  'DEBUG: parsing request body',
  'ERROR: invalid JSON payload',
  'INFO: sending response 200 OK',
}

local mixed_lines = {
  'apple',
  '',
  'banana',
  '',
  'cherry',
  '',
  'date',
}

local ordered_lines = {
  'first',
  'second',
  'third',
  'fourth',
  'fifth',
}

local config_lines = {
  'set noswapfile',
  'set number',
  'set relativenumber',
  'set expandtab',
  'set tabstop=2',
}

-- ─── Lesson 1 — The cgn Formula ───────────────────────────────────────────────

local lesson1 = {
  title = 'The cgn Formula',
  advanced = true,
  explanation = {
    '/word<CR>  — search for the word to highlight all occurrences.',
    'cgn        — change the next match (deletes it and enters Insert mode).',
    '<Esc>      — finish the replacement.',
    '.          — repeat cgn at the next match (change + move in one step).',
    'n          — skip the current match and move to the next one.',
    '',
    'The cgn formula: /word<CR>  cgn  <replacement><Esc>  then . to repeat.',
    'Use n to skip a match, . to apply the change at the next one.',
  },
  challenges = {
    -- 1. cgn to change the first match
    h.vim_language({
      command = 'cgn',
      instruction = 'Change the first "http" to "https" using /http then cgn',
      lines = http_lines,
      start = { 1, 0 },
      expected = {
        'The API endpoint is https not https.',
        'The fallback URL uses http as well.',
        'All internal calls also use http for now.',
        'We must update every http reference before launch.',
      },
      optimal = 11,  -- /http<CR> cgn https<Esc>
      hint = '/http<CR> sets the search. cgn deletes the match and enters Insert. Type "https" then Esc.',
    }),
    -- 2. . to repeat cgn at the next match
    h.vim_language({
      command = 'cgn',
      instruction = 'Change lines 1-2 "http" to "https": cgn on first, . on second',
      lines = http_lines,
      start = { 1, 0 },
      expected = {
        'The API endpoint is https not https.',
        'The fallback URL uses https as well.',
        'All internal calls also use http for now.',
        'We must update every http reference before launch.',
      },
      optimal = 12,  -- /http<CR> cgn https<Esc> .
      hint = 'After the first cgn + replacement + Esc, press . to repeat the change at the next match.',
    }),
    -- 3. n to skip a match, . to change the next
    h.vim_language({
      command = 'cgn',
      instruction = 'Change "http" on lines 1 and 3 only; skip line 2 with n',
      lines = http_lines,
      start = { 1, 0 },
      expected = {
        'The API endpoint is https not https.',
        'The fallback URL uses http as well.',
        'All internal calls also use https for now.',
        'We must update every http reference before launch.',
      },
      optimal = 13,  -- /http<CR> cgn https<Esc> n .
      hint = 'After changing line 1 with cgn, press n to skip line 2, then . to change line 3.',
    }),
    -- 4. Fix "teh" typo on all lines
    h.vim_language({
      command = 'cgn',
      instruction = 'Fix all "teh" typos to "the" using /teh then cgn + . repeat',
      lines = {
        'Teh quick brown fox jumps over teh lazy dog.',
        'Pack my box with five teh dozen liquor jugs.',
        'How vexingly quick daft teh zebras jump.',
      },
      start = { 1, 0 },
      expected = {
        'the quick brown fox jumps over the lazy dog.',
        'Pack my box with five the dozen liquor jugs.',
        'How vexingly quick daft the zebras jump.',
      },
      optimal = 13,  -- /teh<CR> cgn the<Esc> . . . .
      check_lines = { 1, 2, 3 },
      hint = '/teh<CR> highlights all matches. cgn the<Esc> fixes the first. . repeats at each.',
    }),
    -- 5. Selective replacement across a file
    h.vim_language({
      command = 'cgn',
      instruction = 'Change "http" only on lines 2 and 4; skip lines 1 and 3',
      lines = http_lines,
      start = { 1, 0 },
      expected = {
        'The API endpoint is http not https.',
        'The fallback URL uses https as well.',
        'All internal calls also use http for now.',
        'We must update every https reference before launch.',
      },
      optimal = 14,  -- /http<CR> n cgn https<Esc> n .
      hint = '/http<CR> then n skips line 1. cgn changes line 2. n skips line 3. . changes line 4.',
    }),
  },
}

-- ─── Lesson 2 — Transpose & Quick Fixes ──────────────────────────────────────

local lesson2 = {
  title = 'Transpose & Quick Fixes',
  advanced = true,
  explanation = {
    'xp        — delete the character under the cursor (x) then paste it (p).',
    '          This effectively swaps the character with the one after it.',
    '',
    'ddp       — delete the current line (dd) then paste it below (p).',
    '          This swaps the current line with the line below it.',
    '',
    'g<C-a>    — on a visual block of numbers, increment each by a step.',
    '          First number gets +1, second +2, third +3, and so on.',
  },
  challenges = {
    -- 1. xp to fix a transposed pair of characters
    h.editing({
      command = 'xp',
      instruction = 'Fix "teh" to "the" by swapping the transposed chars with xp',
      lines = { 'Fix teh typo here.' },
      start = { 1, 4 },  -- cursor on 'e' in 'teh' (t=4, e=5, h=6 — 0-indexed: t=4)
      expected = { 'Fix the typo here.' },
      optimal = 2,
      hint = 'xp: x deletes the char under the cursor and p puts it after the next char.',
    }),
    -- 2. ddp to swap two lines
    h.power({
      command = 'ddp',
      instruction = 'Swap lines 2 and 3 by pressing ddp on line 2',
      lines = {
        'alpha = 1',
        'gamma = 3',
        'beta  = 2',
        'delta = 4',
      },
      start = { 2, 0 },
      expected = {
        'alpha = 1',
        'beta  = 2',
        'gamma = 3',
        'delta = 4',
      },
      optimal = 3,
      hint = 'ddp: dd yanks the current line into the default register, p pastes it below.',
    }),
    -- 3. xp to fix a second transposed pair
    h.editing({
      command = 'xp',
      instruction = 'Fix "recieve" to "receive" — swap the "ie" to "ei" with xp',
      lines = { 'Please recieve the package.' },
      start = { 1, 11 },  -- cursor on 'i' in 'recieve'
      expected = { 'Please receive the package.' },
      optimal = 2,
      hint = 'xp on the "i" swaps it with the "e" that follows, correcting the order.',
    }),
    -- 4. g<C-a> to create a sequential number list
    h.power({
      command = 'g<C-a>',
      instruction = 'Turn five "0"s into 1-5 using visual block g<C-a>',
      lines = {
        '0',
        '0',
        '0',
        '0',
        '0',
      },
      start = { 1, 0 },
      expected = {
        '1',
        '2',
        '3',
        '4',
        '5',
      },
      optimal = 8,  -- <C-v> 4j g<C-a>
      hint = 'Select all five lines with Ctrl-v 4j, then g Ctrl-a increments each by its position.',
    }),
  },
}

-- ─── Lesson 3 — Navigate Without Thinking ────────────────────────────────────

local lesson3 = {
  title = 'Navigate Without Thinking',
  advanced = true,
  explanation = {
    'gf         — go to the file whose name is under the cursor.',
    'gx         — open the URL under the cursor in the default browser.',
    'Ctrl-o     — jump back to the previous cursor position in the jump list.',
    '',
    'Every / search, G jump, or gf/gx adds an entry to the jump list.',
    'Ctrl-o walks backward through that list; Ctrl-i walks forward.',
    '',
    'Practice: search for a word, then Ctrl-o to return to where you were.',
  },
  challenges = {
    -- 1. Ctrl-o to jump back after a forward search
    h.search({
      command = '<C-o>',
      instruction = 'Search for "cherry" then Ctrl-o to return to line 1',
      lines = {
        'apple',
        'banana',
        'cherry',
        'date',
        'elderberry',
      },
      from = { 1, 0 },
      to   = { 1, 0 },
      optimal = 10,  -- /cherry<CR> <C-o>
      hint = '/cherry<CR> jumps to line 3. Ctrl-o returns to your starting position.',
      optimal_solution = '<C-o> — jump back in the jump list',
    }),
    -- 2. Ctrl-o after a G jump
    h.movement({
      command = '<C-o>',
      instruction = 'Jump to the last line with G, then Ctrl-o to return to line 1',
      lines = {
        'start here',
        'line two',
        'line three',
        'line four',
        'end here',
      },
      from = { 1, 0 },
      to   = { 1, 0 },
      optimal = 2,  -- G <C-o>
      hint = 'G jumps to the last line and adds to the jump list. Ctrl-o takes you back.',
      optimal_solution = 'G then <C-o> — jump to end then return',
    }),
    -- 3. Ctrl-o twice to walk back through two jumps
    h.movement({
      command = '<C-o>',
      instruction = 'Search "cherry" then "elderberry", then Ctrl-o twice back to line 1',
      lines = {
        'apple',
        'banana',
        'cherry',
        'date',
        'elderberry',
      },
      from = { 1, 0 },
      to   = { 1, 0 },
      optimal = 22,  -- /cherry<CR> /elderberry<CR> <C-o><C-o>
      hint = 'Each search adds a jump entry. Two Ctrl-o presses walk back through both.',
      optimal_solution = '<C-o><C-o> — walk back two jumps',
    }),
  },
}

-- ─── Lesson 4 — Surgical Bulk Edits ──────────────────────────────────────────

local lesson4 = {
  title = 'Surgical Bulk Edits',
  advanced = true,
  explanation = {
    ':g/pattern/d   — delete every line matching pattern.',
    ':v/pattern/d   — delete every line NOT matching pattern (keep matches).',
    ':g/^$/d        — delete all blank lines (^ = start, $ = end, nothing between).',
    ':g/^/m 0       — move every line to line 0 (before line 1), reversing the file.',
    '',
    'These Ex commands operate on the whole buffer by default.',
    'They are composable: :g/DEBUG/d removes debug lines in one shot.',
  },
  challenges = {
    -- 1. :g/DEBUG/d to delete all debug lines
    h.power({
      command = ':g',
      instruction = 'Delete all DEBUG lines with :g/DEBUG/d',
      lines = debug_lines,
      start = { 1, 0 },
      expected = {
        'INFO: server started on port 8080',
        'ERROR: failed to authenticate user',
        'INFO: request received from 127.0.0.1',
        'ERROR: invalid JSON payload',
        'INFO: sending response 200 OK',
      },
      optimal = 11,  -- :g/DEBUG/d<CR>
      hint = ':g/DEBUG/d matches every line containing "DEBUG" and deletes it.',
    }),
    -- 2. :v/ERROR/d to keep only ERROR lines
    h.power({
      command = ':v',
      instruction = 'Keep only ERROR lines with :v/ERROR/d',
      lines = debug_lines,
      start = { 1, 0 },
      expected = {
        'ERROR: failed to authenticate user',
        'ERROR: invalid JSON payload',
      },
      optimal = 12,  -- :v/ERROR/d<CR>
      hint = ':v/ERROR/d deletes every line that does NOT match "ERROR", leaving only errors.',
    }),
    -- 3. :g/^$/d to delete blank lines
    h.power({
      command = ':g',
      instruction = 'Remove all blank lines with :g/^$/d',
      lines = mixed_lines,
      start = { 1, 0 },
      expected = {
        'apple',
        'banana',
        'cherry',
        'date',
      },
      optimal = 9,  -- :g/^$/d<CR>
      hint = ':g/^$/d matches lines where start (^) immediately meets end ($) — blank lines.',
    }),
    -- 4. :g/^/m 0 to reverse the file
    h.power({
      command = ':g',
      instruction = 'Reverse the file order with :g/^/m 0',
      lines = ordered_lines,
      start = { 1, 0 },
      expected = {
        'fifth',
        'fourth',
        'third',
        'second',
        'first',
      },
      optimal = 9,  -- :g/^/m 0<CR>
      hint = ':g/^/m 0 matches every line (^ always matches) and moves each to before line 1.',
    }),
    -- 5. :g/INFO/d then :g/^$/d — chained cleanup
    h.power({
      command = ':g',
      instruction = 'Delete INFO lines then blank lines; keep only ERROR and DEBUG',
      lines = {
        'INFO: startup complete',
        '',
        'DEBUG: cache warmed',
        'ERROR: disk full',
        '',
        'INFO: shutdown initiated',
      },
      start = { 1, 0 },
      expected = {
        'DEBUG: cache warmed',
        'ERROR: disk full',
      },
      optimal = 19,  -- :g/INFO/d<CR> :g/^$/d<CR>
      hint = 'Run :g/INFO/d first to remove INFO lines, then :g/^$/d to clean up blank lines.',
    }),
  },
}

-- ─── Lesson 5 — Config Superpowers ───────────────────────────────────────────

local lesson5 = {
  title = 'Config Superpowers',
  advanced = true,
  explanation = {
    ':set undofile        — persist undo history across sessions.',
    '                       Vim writes an undo file alongside each edited file.',
    '',
    ':set inccommand=nosplit  — preview :s substitutions live as you type.',
    '                           See what changes before pressing Enter.',
    '',
    ':set scrolloff=8     — keep at least 8 lines above/below the cursor.',
    '                       The cursor stays near the center as you scroll.',
    '',
    'These settings are typically placed in init.lua or init.vim.',
  },
  challenges = {
    -- 1. :set scrolloff= to change the scroll margin
    h.power({
      command = ':set',
      instruction = 'Set scrolloff to 8 with :set scrolloff=8',
      lines = config_lines,
      start = { 1, 0 },
      expected = {
        'set noswapfile',
        'set number',
        'set relativenumber',
        'set expandtab',
        'set tabstop=2',
        'set scrolloff=8',
      },
      optimal = 17,  -- :set scrolloff=8<CR> (appended as new line via o)
      hint = ':set scrolloff=8 takes effect immediately. You can also append it to the buffer.',
    }),
    -- 2. :set inccommand= to enable live preview
    h.power({
      command = ':set',
      instruction = 'Enable live substitution preview with :set inccommand=nosplit',
      lines = config_lines,
      start = { 1, 0 },
      expected = {
        'set noswapfile',
        'set number',
        'set relativenumber',
        'set expandtab',
        'set tabstop=2',
        'set inccommand=nosplit',
      },
      optimal = 23,  -- :set inccommand=nosplit<CR>
      hint = ':set inccommand=nosplit makes :s/old/new show matches highlighted before you confirm.',
    }),
    -- 3. :set undofile to enable persistent undo
    h.power({
      command = ':set',
      instruction = 'Enable persistent undo with :set undofile',
      lines = config_lines,
      start = { 1, 0 },
      expected = {
        'set noswapfile',
        'set number',
        'set relativenumber',
        'set expandtab',
        'set tabstop=2',
        'set undofile',
      },
      optimal = 13,  -- :set undofile<CR>
      hint = ':set undofile saves undo history to disk so u works even after closing the file.',
    }),
  },
}

M.lessons = { lesson1, lesson2, lesson3, lesson4, lesson5 }

return M
