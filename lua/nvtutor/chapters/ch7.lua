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
      instruction = 'Cursor is on line 1. Search forward for "listeners" and land on its first occurrence.',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 8, 7 },    -- 'self.listeners = {}' — col 7 is 'l'
      optimal = 11,        -- /listeners<CR>
      hint = 'Type /listeners then press Enter. The cursor lands on the first "l" of the match.',
    }),
    -- 2. n to advance to next match
    h.search({
      command = 'n',
      instruction = 'Search for "self" then press n to reach the second occurrence (line 8).',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 8, 2 },    -- 'self' in 'self.listeners = {}' on line 8
      optimal = 7,         -- /self<CR>n  = 1+4+1+1 = 7
      hint = '/self<CR> lands on line 7 (first match). Press n for the next.',
    }),
    -- 3. ? backward search
    h.search({
      command = '?',
      instruction = 'Cursor is on line 26. Search backward for "self" and land on its last occurrence above.',
      lines = pattern_lines,
      from = { 26, 0 },
      to   = { 20, 14 },  -- 'self' in 'self.listeners[event]' on line 20
      optimal = 6,         -- ?self<CR> = 6 keystrokes
      hint = '? searches upward (backward). The cursor lands on the nearest match above.',
    }),
    -- 4. N to reverse search direction
    h.search({
      command = 'N',
      instruction = 'Search forward for "EventEmitter", then press N to jump back to the previous occurrence.',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 3, 6 },    -- line 3: 'local EventEmitter = {}' — N reverses back here
      optimal = 16,        -- /EventEmitter<CR>nN = 1+12+1+1+1 = 16
      hint = 'After the initial search, n moves forward and N moves backward through matches.',
    }),
    -- 5. Combined / and n for multi-hop
    h.search({
      command = '/',
      instruction = 'Search for "callback" and press n to reach its second occurrence (line 16).',
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
      instruction = 'Cursor is on "local" at line 1. Press * to jump to the next "local".',
      lines = word_lines,
      from = { 1, 0 },    -- 'local' at start of line 1
      to   = { 2, 0 },    -- 'local' at start of line 2
      optimal = 1,
      hint = '* searches forward for the exact whole word under the cursor.',
    }),
    -- 2. * then n to continue
    h.search({
      command = '*',
      instruction = 'Cursor is on "local" at line 1. Press * then n to reach the third "local" (line 3).',
      lines = word_lines,
      from = { 1, 0 },    -- 'local' at start of line 1
      to   = { 3, 0 },    -- 'local' at start of line 3
      optimal = 2,         -- *, n
      hint = '* jumps to the first match, n advances to the next.',
    }),
    -- 3. # to jump backward
    h.search({
      command = '#',
      instruction = 'Cursor is on "load_config" in line 17. Press # to jump backward to its definition on line 5.',
      lines = word_lines,
      from = { 17, 12 },  -- 'load_config' in 'load_config(config_path)'
      to   = { 5, 15 },   -- 'local function load_config(path)' on line 5
      optimal = 1,
      hint = '# searches backward for the whole word under the cursor.',
    }),
    -- 4. * on a function name
    h.search({
      command = '*',
      instruction = 'Cursor is on "load_config" in line 5 (the definition). Press * to jump to its next call on line 17.',
      lines = word_lines,
      from = { 5, 15 },   -- 'load_config' in 'local function load_config(path)'
      to   = { 17, 12 },  -- 'local cfg = load_config(config_path)'
      optimal = 1,
      hint = '* treats the entire word under the cursor. "load_config" is one token.',
    }),
    -- 5. # then n to walk backward through occurrences
    h.search({
      command = '#',
      instruction = 'Cursor is on "config_path" in line 17. Press # to jump backward to line 2.',
      lines = word_lines,
      from = { 17, 24 },  -- 'config_path' starts at col 24
      to   = { 2, 6 },    -- 'local config_path = ...' on line 2
      optimal = 1,         -- # directly reaches line 2 (only other occurrence)
      hint = '# searches backward for the exact word under the cursor.',
    }),
  },
}

M.lessons = { lesson1, lesson2 }

return M
