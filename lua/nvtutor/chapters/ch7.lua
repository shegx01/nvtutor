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
      instruction = 'Search for "event" and then press n twice to reach the third occurrence on line 19.',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 19, 23 },  -- 'event' in 'emit(event, ...)'  line 19
      optimal = 9,         -- /event<CR> n n
      hint = '/event<CR> lands on the first match. Press n to advance to the next match.',
    }),
    -- 3. ? backward search
    h.search({
      command = '?',
      instruction = 'Cursor is on line 26. Search backward for "self" and land on its last occurrence above.',
      lines = pattern_lines,
      from = { 26, 0 },
      to   = { 20, 12 },  -- 'self.listeners[event]' on line 20
      optimal = 7,         -- ?self<CR>
      hint = '? searches upward (backward). The cursor lands on the nearest match above.',
    }),
    -- 4. N to reverse search direction
    h.search({
      command = 'N',
      instruction = 'Search forward for "EventEmitter", then press N to jump back to the previous occurrence.',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 4, 0 },    -- line 4: 'EventEmitter.__index = EventEmitter'
      optimal = 16,        -- /EventEmitter<CR> n N  (forward, advance, reverse)
      hint = 'After the initial search, n moves forward and N moves backward through matches.',
    }),
    -- 5. Combined / and n for multi-hop
    h.search({
      command = '/',
      instruction = 'Search for "callback" and press n to reach its second occurrence (line 16).',
      lines = pattern_lines,
      from = { 1, 0 },
      to   = { 16, 34 },  -- 'table.insert(self.listeners[event], callback)' — second 'callback'
      optimal = 12,        -- /callback<CR> n
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
      instruction = 'Cursor is on "config" in line 1. Press * to jump to the next occurrence of "config".',
      lines = word_lines,
      from = { 1, 6 },    -- cursor on 'c' of 'config' in 'local config = ...'
      to   = { 3, 8 },    -- 'local default_config' — next whole-word "config" match
      optimal = 1,
      hint = '* jumps forward to the next whole-word match. "config_path" is skipped (not a whole word).',
    }),
    -- 2. * then n to continue
    h.search({
      command = '*',
      instruction = 'Cursor is on "config" in line 1. Press * then n to reach the second forward match of "config" (line 7).',
      lines = word_lines,
      from = { 1, 6 },
      to   = { 7, 19 },   -- 'return default_config' — second whole-word "config" match forward
      optimal = 2,         -- *, n
      hint = '* jumps to the first next match, n advances to the next one.',
    }),
    -- 3. # to jump backward
    h.search({
      command = '#',
      instruction = 'Cursor is on "config" in line 17 ("local cfg = load_config(config_path)"). Press # to jump backward to the previous whole-word "config".',
      lines = word_lines,
      from = { 17, 16 },  -- 'config' inside 'load_config' — but load_config is one token; use col on 'config' that is whole word
      to   = { 14, 9 },   -- 'return default_config' on line 14
      optimal = 1,
      hint = '# searches backward. It stops only on whole-word matches of the token under your cursor.',
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
    -- 5. # then n to walk backward through all occurrences
    h.search({
      command = '#',
      instruction = 'Cursor is on "config_path" in line 17. Press # then n to reach the previous occurrence of "config_path" on line 2.',
      lines = word_lines,
      from = { 17, 21 },  -- 'config_path' in 'load_config(config_path)'
      to   = { 2, 6 },    -- 'local config_path = ...' on line 2
      optimal = 2,         -- #, n
      hint = '# goes to line 5 (function param). n continues backward and wraps to line 2.',
    }),
  },
}

M.lessons = { lesson1, lesson2 }

return M
