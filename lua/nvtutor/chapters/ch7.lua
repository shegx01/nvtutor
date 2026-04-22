local h = require('nvtutor.chapters.helpers')
local M = {}

M.title = 'Search'
M.description = 'Navigate any file at the speed of thought using pattern search and word-under-cursor jumps.'

-- ─── shared buffer content ────────────────────────────────────────────────────

local pattern_lines = {
  '-- NVTutor: event-driven plugin architecture',
  '',
  'local EventEmitter = {}',
  'EventEmitter.__index = EventEmitter',
  '',
  'function EventEmitter.new()',
  '  local self = setmetatable({}, EventEmitter)',
  '  self.listeners = {}',
  '  return self',
  'end',
  '',
  'function EventEmitter:on(event, callback)',
  '  if not self.listeners[event] then',
  '    self.listeners[event] = {}',
  '  end',
  '  table.insert(self.listeners[event], callback)',
  'end',
  '',
  'function EventEmitter:emit(event, ...)',
  '  local cbs = self.listeners[event] or {}',
  '  for _, cb in ipairs(cbs) do',
  '    cb(...)',
  '  end',
  'end',
  '',
  'return EventEmitter',
}

local word_lines = {
  'local config = require("config")',
  'local config_path = vim.fn.stdpath("config")',
  'local default_config = { timeout = 30, retries = 3 }',
  '',
  'local function load_config(path)',
  '  local f = io.open(path, "r")',
  '  if not f then return default_config end',
  '  local data = f:read("*a")',
  '  f:close()',
  '  local ok, parsed = pcall(vim.json.decode, data)',
  '  if ok then',
  '    return parsed',
  '  end',
  '  return default_config',
  'end',
  '',
  'local cfg = load_config(config_path)',
  'vim.notify("Config loaded: " .. config_path)',
}

-- ─── Lesson 1 — Patterns (/, ?, n, N) ────────────────────────────────────────

local lesson1 = {
  title = 'Patterns',
  explanation = {
    '/{pattern}<CR>  — search forward for pattern.',
    '?{pattern}<CR>  — search backward for pattern.',
    'n               — repeat the last search in the same direction.',
    'N               — repeat the last search in the opposite direction.',
    '',
    'Search is case-sensitive by default.',
    'Prefix with \\c for case-insensitive: /\\ceventemitter<CR>',
    '',
    'The search wraps around when it reaches the end (or start) of the file.',
  },
  challenges = {
    -- 1. / forward search to land on a word
    h.search({
      command = '/',
      instruction = 'Search for "listeners" using /listeners to reach its first occurrence',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 8, 7 },    -- 'self.listeners = {}' — col 7 is 'l'
      optimal = 11,        -- /listeners<CR>
      hint = 'Type /listeners then press Enter. The cursor lands on the first "l" of the match.',
    }),
    -- 2. n to advance to next match
    h.search({
      command = 'n',
      instruction = 'Search for "self" then press n to reach line 8',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 8, 2 },    -- 'self' in 'self.listeners = {}' on line 8
      optimal = 7,         -- /self<CR>n  = 1+4+1+1 = 7
      hint = '/self<CR> lands on line 7 (first match). Press n for the next.',
    }),
    -- 3. ? backward search
    h.search({
      command = '?',
      instruction = 'Search backward for "self" using ?self to reach line 20',
      lines = pattern_lines,
      from = { 26, 0 },
      to   = { 20, 14 },  -- 'self' in 'self.listeners[event]' on line 20
      optimal = 6,         -- ?self<CR> = 6 keystrokes
      hint = '? searches upward (backward). The cursor lands on the nearest match above.',
    }),
    -- 4. N to reverse search direction
    h.search({
      command = 'N',
      instruction = 'Search for "EventEmitter" then press N to jump back to line 3',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 3, 6 },    -- line 3: 'local EventEmitter = {}' — N reverses back here
      optimal = 16,        -- /EventEmitter<CR>nN = 1+12+1+1+1 = 16
      hint = 'After the initial search, n moves forward and N moves backward through matches.',
    }),
    -- 5. Combined / and n for multi-hop
    h.search({
      command = '/',
      instruction = 'Search for "callback" then press n to reach line 16',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 16, 38 },  -- 'callback' in 'table.insert(self.listeners[event], callback)'
      optimal = 11,        -- /callback<CR>n = 1+8+1+1 = 11
      hint = '/callback<CR> finds the first match. One n brings you to the second.',
    }),
  },
}

-- ─── Lesson 2 — Search Word (* and #) ────────────────────────────────────────

local lesson2 = {
  title = 'Search Word',
  explanation = {
    '*  — search forward for the exact word under the cursor.',
    '#  — search backward for the exact word under the cursor.',
    '',
    'Both wrap around the file and highlight all occurrences.',
    'The search is whole-word: searching on "config" will NOT match "config_path".',
    '',
    'Use n / N after * or # to continue navigating matches.',
    'Tip: position the cursor on an identifier, press *, then use n to hop between uses.',
  },
  challenges = {
    -- 1. * to jump to next occurrence of word
    h.search({
      command = '*',
      instruction = 'Jump to the next "local" with *',
      lines = word_lines,
      from = { 1, 0 },    -- 'local' at start of line 1
      to   = { 2, 0 },    -- 'local' at start of line 2
      optimal = 1,
      hint = '* searches forward for the exact whole word under the cursor.',
    }),
    -- 2. * then n to continue
    h.search({
      command = '*',
      instruction = 'Jump to the third "local" using * then n',
      lines = word_lines,
      from = { 1, 0 },    -- 'local' at start of line 1
      to   = { 3, 0 },    -- 'local' at start of line 3
      optimal = 2,         -- *, n
      hint = '* jumps to the first match, n advances to the next.',
    }),
    -- 3. # to jump backward
    h.search({
      command = '#',
      instruction = 'Jump back to the definition of "load_config" on line 5 with #',
      lines = word_lines,
      from = { 17, 12 },  -- 'load_config' in 'load_config(config_path)'
      to   = { 5, 15 },   -- 'local function load_config(path)' on line 5
      optimal = 1,
      hint = '# searches backward for the whole word under the cursor.',
    }),
    -- 4. * on a function name
    h.search({
      command = '*',
      instruction = 'Jump to the call of "load_config" on line 17 with *',
      lines = word_lines,
      from = { 5, 15 },   -- 'load_config' in 'local function load_config(path)'
      to   = { 17, 12 },  -- 'local cfg = load_config(config_path)'
      optimal = 1,
      hint = '* treats the entire word under the cursor. "load_config" is one token.',
    }),
    -- 5. # then n to walk backward through occurrences
    h.search({
      command = '#',
      instruction = 'Jump backward to "config_path" on line 2 with #',
      lines = word_lines,
      from = { 17, 24 },  -- 'config_path' starts at col 24
      to   = { 2, 6 },    -- 'local config_path = ...' on line 2
      optimal = 1,         -- # directly reaches line 2 (only other occurrence)
      hint = '# searches backward for the exact word under the cursor.',
    }),
  },
}

-- ─── Lesson 3 — Regex Patterns ───────────────────────────────────────────────

local regex_lines = {
  'user123 logged in at 09:45:30',
  'error404: resource not found',
  'item_price = 19.99',
  'valid tokens: foo bar baz42',
  'ratio = 3/4 and offset = -7',
  'tags: <div> <span> <p>',
}

local lesson3 = {
  title = 'Regex Patterns',
  description = 'Match digits, word chars, and repeated sequences with Vim regex atoms.',
  advanced = true,
  explanation = {
    '\\d    — match a digit character (0–9).',
    '\\w    — match a word character (letter, digit, or underscore).',
    '.     — match any single character.',
    '\\+    — one or more of the preceding atom.',
    '*     — zero or more of the preceding atom.',
    '',
    'In Vim these atoms use backslash notation (not PCRE).',
    'Example: /\\d\\+ finds the first run of digits.',
    '',
    'Use n/N to walk through all matches after the initial search.',
  },
  challenges = {
    -- 1. \d+ to find first run of digits
    h.search({
      command = '/',
      instruction = 'Find the first digit sequence using /\\d\\+',
      lines = regex_lines,
      from = { 1, 0 },
      to   = { 1, 4 },   -- '123' starting at col 4
      optimal = 5,         -- /\d\+<CR>
      hint = '\\d matches one digit, \\+ means one or more. The cursor lands on the first digit.',
      optimal_solution = '/\\d\\+\r',
    }),
    -- 2. \w+ to find first word token
    h.search({
      command = '/',
      instruction = 'Jump to "foo" on line 4 by searching /foo',
      lines = regex_lines,
      from = { 1, 0 },
      to   = { 4, 15 },  -- 'foo' starts at col 15 on line 4
      optimal = 5,
      hint = '/foo is a literal search. \\w\\+ would match any word — try both to compare.',
      optimal_solution = '/foo\r',
    }),
    -- 3. . wildcard match
    h.search({
      command = '/',
      instruction = 'Search for a 3-char pattern "3/4" using /3.4',
      lines = regex_lines,
      from = { 1, 0 },
      to   = { 5, 9 },   -- '3/4' on line 5
      optimal = 5,
      hint = '. in Vim regex matches any character. /3.4 matches "3" + any char + "4".',
      optimal_solution = '/3.4\r',
    }),
    -- 4. Digit run with n to advance
    h.search({
      command = 'n',
      instruction = 'Find all digit sequences with /\\d\\+ then press n to reach line 3',
      lines = regex_lines,
      from = { 1, 0 },
      to   = { 3, 14 },  -- digits in 'item_price = 19.99' -> '19' at col 14
      optimal = 6,         -- /\d\+<CR> n
      hint = '/\\d\\+<CR> lands on "123" on line 1. Press n to advance to the next match.',
      optimal_solution = '/\\d\\+\rn',
    }),
  },
}

-- ─── Lesson 4 — Very Magic Mode (\v) ─────────────────────────────────────────

local vmagic_lines = {
  'status: ok or warn or error',
  'mode: read or write or append',
  'color: red or blue or green',
}

local lesson4 = {
  title = 'Very Magic Mode',
  description = 'Use \\v to write cleaner regex without escaping every metacharacter.',
  advanced = true,
  explanation = {
    '\\v  — very magic prefix: all special chars act as regex without backslashes.',
    '',
    'Without \\v:  /\\(foo\\|bar\\)  — verbose, hard to read.',
    'With \\v:     /\\v(foo|bar)   — cleaner, PCRE-like syntax.',
    '',
    'With \\v:',
    '  +   means one or more  (no backslash needed)',
    '  |   means alternation',
    '  ()  means grouping',
    '',
    'Use \\V for "very nomagic" (everything literal except \\n and \\\\).',
  },
  challenges = {
    -- 1. Alternation with \v
    h.search({
      command = '/',
      instruction = 'Find "ok" or "warn" using /\\v(ok|warn)',
      lines = vmagic_lines,
      from = { 1, 0 },
      to   = { 1, 8 },   -- 'ok' on line 1 col 8
      optimal = 12,        -- /\v(ok|warn)<CR>
      hint = '\\v makes | and () work without backslashes. The cursor lands on the first match.',
      optimal_solution = '/\\v(ok|warn)\r',
    }),
    -- 2. n to advance through alternation matches
    h.search({
      command = 'n',
      instruction = 'After /\\v(ok|warn), press n to reach "warn" on line 1',
      lines = vmagic_lines,
      from = { 1, 0 },
      to   = { 1, 12 },  -- 'warn' on line 1 col 12
      optimal = 13,
      hint = 'n advances to the next alternation match — "warn" follows "ok".',
      optimal_solution = '/\\v(ok|warn)\rn',
    }),
    -- 3. Three-way alternation
    h.search({
      command = '/',
      instruction = 'Find "read", "write", or "append" on line 2 with /\\v(read|write|append)',
      lines = vmagic_lines,
      from = { 3, 0 },
      to   = { 2, 6 },   -- 'read' on line 2 col 6
      optimal = 21,
      hint = '\\v(read|write|append) — no extra backslashes needed with very magic mode.',
      optimal_solution = '/\\v(read|write|append)\r',
    }),
  },
}

-- ─── Lesson 5 — Substitute Command (:s) ──────────────────────────────────────

local sub_lines = {
  'The colour of the sky is colour blue.',
  'The colour of the sea is colour teal.',
  'Colour is everywhere in nature.',
}

local lesson5 = {
  title = 'Substitute Command',
  description = 'Replace text across lines and ranges with :s — the Swiss Army knife.',
  advanced = true,
  explanation = {
    ':%s/old/new/g        — replace every occurrence in the whole file.',
    ':%s/old/new/gc       — same, but confirm each substitution.',
    ':1,3s/old/new/g      — replace only on lines 1–3.',
    ":'<,'>s/old/new/g    — replace within the visual selection.",
    '',
    'Flags:',
    '  g — replace ALL occurrences on each line (not just the first).',
    '  c — confirm before each replacement.',
    '  i — case-insensitive match.',
    '',
    'The pattern supports full Vim regex: :%s/\\d\\+/NUM/g replaces all numbers.',
  },
  challenges = {
    -- 1. Global substitute across whole file
    h.power({
      command = ':%s',
      instruction = 'Replace all "colour" with "color" using :%s/colour/color/g',
      lines = sub_lines,
      start = { 1, 0 },
      expected = {
        'The color of the sky is color blue.',
        'The color of the sea is color teal.',
        'Color is everywhere in nature.',
      },
      optimal = 20,   -- :%s/colour/color/g<CR>
      hint = ':%s applies to every line. The /g flag replaces all matches per line.',
      optimal_solution = ':%s/colour/color/g\r',
    }),
    -- 2. Range substitute on specific lines
    h.power({
      command = ':1,2s',
      instruction = 'Replace "color" with "hue" on lines 1-2 only with :1,2s/color/hue/g',
      lines = {
        'The color of the sky is color blue.',
        'The color of the sea is color teal.',
        'Color is everywhere in nature.',
      },
      start = { 1, 0 },
      expected = {
        'The hue of the sky is hue blue.',
        'The hue of the sea is hue teal.',
        'Color is everywhere in nature.',
      },
      optimal = 20,
      hint = ':1,2s limits the substitution to lines 1 and 2. Line 3 is untouched.',
      optimal_solution = ':1,2s/color/hue/g\r',
    }),
    -- 3. Substitute with regex pattern
    h.power({
      command = ':%s',
      instruction = 'Replace the colour word on line 3 using :%s/Color/Hue/g',
      lines = {
        'The hue of the sky is hue blue.',
        'The hue of the sea is hue teal.',
        'Color is everywhere in nature.',
      },
      start = { 3, 0 },
      expected = {
        'The hue of the sky is hue blue.',
        'The hue of the sea is hue teal.',
        'Hue is everywhere in nature.',
      },
      optimal = 16,
      hint = ':%s/Color/Hue/g — exact case match replaces only "Color" (capital C).',
      optimal_solution = ':%s/Color/Hue/g\r',
    }),
    -- 4. Case-insensitive substitute with /i flag
    h.power({
      command = ':%s',
      instruction = 'Replace every "hue" (any case) with "tone" using :%s/hue/tone/gi',
      lines = {
        'The hue of the sky is hue blue.',
        'The hue of the sea is hue teal.',
        'Hue is everywhere in nature.',
      },
      start = { 1, 0 },
      expected = {
        'The tone of the sky is tone blue.',
        'The tone of the sea is tone teal.',
        'tone is everywhere in nature.',
      },
      optimal = 17,
      hint = 'The i flag makes the match case-insensitive, so "Hue" and "hue" are both replaced.',
      optimal_solution = ':%s/hue/tone/gi\r',
    }),
  },
}

-- ─── Lesson 6 — Global Command (:g) ──────────────────────────────────────────

local global_lines = {
  'DEBUG: initialising engine',
  'INFO:  engine started',
  'DEBUG: loading config file',
  'INFO:  config loaded',
  'DEBUG: connecting to database',
  'ERROR: connection refused',
  'INFO:  retrying connection',
  'DEBUG: retry attempt 1',
}

local lesson6 = {
  title = 'Global Command',
  description = 'Run ex commands on every line that matches (or does not match) a pattern.',
  advanced = true,
  explanation = {
    ':g/pattern/cmd   — run cmd on every line matching pattern.',
    ':v/pattern/cmd   — run cmd on every line NOT matching pattern.',
    '',
    'Common uses:',
    '  :g/DEBUG/d          — delete all DEBUG lines.',
    '  :v/ERROR/d          — keep only ERROR lines (delete the rest).',
    '  :g/TODO/norm A DONE — append " DONE" to every TODO line.',
    '',
    ':v is shorthand for :g! (inverse match).',
    'The cmd after the last / can be any ex command: d, s, norm, p, etc.',
  },
  challenges = {
    -- 1. :g to delete matching lines
    h.power({
      command = ':g',
      instruction = 'Delete all DEBUG lines with :g/DEBUG/d',
      lines = global_lines,
      start = { 1, 0 },
      expected = {
        'INFO:  engine started',
        'INFO:  config loaded',
        'ERROR: connection refused',
        'INFO:  retrying connection',
      },
      optimal = 12,   -- :g/DEBUG/d<CR>
      hint = ':g/DEBUG/d runs d (delete) on every line containing "DEBUG".',
      optimal_solution = ':g/DEBUG/d\r',
    }),
    -- 2. :v to keep only matching lines
    h.power({
      command = ':v',
      instruction = 'Keep only INFO lines by deleting non-INFO lines with :v/INFO/d',
      lines = {
        'INFO:  engine started',
        'INFO:  config loaded',
        'ERROR: connection refused',
        'INFO:  retrying connection',
      },
      start = { 1, 0 },
      expected = {
        'INFO:  engine started',
        'INFO:  config loaded',
        'INFO:  retrying connection',
      },
      optimal = 11,
      hint = ':v/INFO/d deletes every line that does NOT contain "INFO".',
      optimal_solution = ':v/INFO/d\r',
    }),
    -- 3. :g with norm to append text
    h.power({
      command = ':g',
      instruction = 'Append " [logged]" to every INFO line using :g/INFO/norm A [logged]',
      lines = {
        'INFO:  engine started',
        'INFO:  config loaded',
        'INFO:  retrying connection',
      },
      start = { 1, 0 },
      expected = {
        'INFO:  engine started [logged]',
        'INFO:  config loaded [logged]',
        'INFO:  retrying connection [logged]',
      },
      optimal = 22,
      hint = ':g/INFO/norm runs a Normal-mode command on each match. A enters Insert at end of line.',
      optimal_solution = ':g/INFO/norm A [logged]\r',
    }),
    -- 4. :g with substitution
    h.power({
      command = ':g',
      instruction = 'Uppercase INFO to INFO: on matched lines using :g/INFO/s/INFO/INFO:/g',
      lines = {
        'INFO engine started',
        'INFO config loaded',
        'ERROR connection refused',
      },
      start = { 1, 0 },
      expected = {
        'INFO: engine started',
        'INFO: config loaded',
        'ERROR connection refused',
      },
      optimal = 22,
      hint = ':g/INFO/s runs a substitute only on INFO lines. Non-matching lines are untouched.',
      optimal_solution = ':g/INFO/s/INFO/INFO:/g\r',
    }),
  },
}

M.lessons = { lesson1, lesson2, lesson3, lesson4, lesson5, lesson6 }

return M
