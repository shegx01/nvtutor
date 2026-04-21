# NVTutor Implementation Plan

**Date:** 2026-04-21
**Type:** Greenfield Neovim Plugin (Lua)
**Target:** Neovim 0.10+
**Ambiguity Score:** 9% (PASSED)

---

## 1. Requirements Summary

NVTutor is a zero-dependency interactive Neovim plugin that teaches Vim commands through 8 progressive chapters (~35 lessons). It uses a "teach then challenge" format: each lesson shows a brief explanation, then presents 3-5 interactive challenges where the user performs real Vim commands on highlighted targets in a scratch buffer. Scoring is based on keystroke count and time, awarding bronze/silver/gold mastery tiers per command. Chapters unlock sequentially; first-time users skip the menu and land directly in Ch1 L1. Each chapter ends with a review round mixing commands from prior chapters. After all 8 chapters, a final gauntlet tests everything, followed by a stats summary.

### Core Requirements

| Requirement | Detail |
|-------------|--------|
| Launch command | `:NVTutor` with subcommands: `menu`, `reset`, `stats` |
| First-run UX | Straight into Ch1 L1, no menu |
| Returning UX | Chapter menu with progress indicators + "Continue where you left off" |
| Lesson format | Explanation text -> 3-5 interactive challenges per lesson |
| Challenge detection | 6 distinct challenge types (movement, editing, visual, vim-language, search, power) |
| Scoring | Keystrokes + time -> bronze/silver/gold per command |
| Chapter unlock | Sequential; completing Ch(N) unlocks Ch(N+1) |
| Lesson access | All lessons freely accessible within unlocked chapters |
| Review rounds | End of each chapter; mixed commands from prior chapters |
| Gauntlet | Final challenge mixing all chapters; followed by stats summary |
| Persistence | JSON at `~/.local/share/nvim/tutor/progress.json` |
| Buffer management | Scratch buffers (`buftype=nofile`, `buflisted=false`) |
| Quit/resume | Save progress on `:q` or close; restore exact position on resume |
| Highlights | 7 user-overridable highlight groups with sensible defaults |
| Help | `:help nvtutor` via `doc/nvtutor.txt` |
| Health | `:checkhealth nvtutor` verifies version, data dir, plugin integrity |
| Installation | Compatible with lazy.nvim, packer, vim-plug, manual install; no `setup()` call |

---

## 2. RALPLAN-DR Summary

### Principles

1. **Real Vim, Real Muscle Memory** -- Challenges must use actual Vim commands in a real buffer, not simulated inputs. The user must perform `dw` to delete a word, not press a button labeled "delete word."

2. **Zero Friction Entry** -- No setup(), no configuration, no menu on first launch. Install the plugin, run `:NVTutor`, start learning immediately.

3. **Declarative Content, Imperative Engine** -- Chapter/lesson data is pure declarative Lua tables describing what to teach and how to score it. The engine interprets those declarations. This separation allows adding lessons without touching engine code.

4. **Graceful State Management** -- Progress persists reliably across sessions. Quitting mid-challenge never corrupts state. Buffer teardown never leaves artifacts.

5. **Progressive Disclosure** -- The plugin reveals complexity gradually: basic movement before editing, editing before composition, composition before power commands. The UI follows the same pattern.

### Decision Drivers

1. **Keystroke Interception Fidelity** -- The plugin must capture every keystroke during a challenge to count them for scoring, while still letting Vim process them normally. This is the single hardest technical problem and drives the architecture of the engine.

2. **Challenge Type Extensibility** -- Six distinct challenge detection strategies (movement, editing, visual, vim-language, search, power) must coexist without a monolithic if/else tree. The architecture must make adding a new challenge type straightforward.

3. **Content Authoring Velocity** -- With ~35 lessons each containing 3-5 challenges (100-175 total challenges), the data format for defining challenges must be concise and self-documenting. A verbose format would make authoring painful and error-prone.

### Viable Options

#### Option A: `vim.on_key()` + Autocmd Hybrid (RECOMMENDED)

Use `vim.on_key()` (available since Neovim 0.10) to count keystrokes globally during active challenges. Use autocmds (`CursorMoved`, `TextChanged`, `ModeChanged`) and post-command buffer snapshots to detect challenge completion. Each challenge type registers a specific "validator" function that checks whether the goal state has been reached.

**Pros:**
- `vim.on_key()` provides a non-intrusive keystroke counter that does not interfere with Vim's normal key processing
- Autocmds are the standard Neovim mechanism for reacting to state changes; well-documented and stable
- No remapping of user keys; the user's existing muscle memory and custom mappings work as-is
- Validators are isolated per challenge type, making the system extensible

**Cons:**
- `vim.on_key()` fires for ALL keys including internal/unmapped ones; need careful filtering
- Some challenge types (visual mode selection, macro recording) require multi-event detection that can be tricky to sequence
- Race conditions possible if autocmds fire before the buffer reaches its final state (mitigated by `vim.schedule()`)

#### Option B: Buffer-local Keymap Remapping

Remap every relevant key in the challenge buffer to a wrapper function that counts the keystroke, then executes the original command via `vim.api.nvim_feedkeys()`.

**Pros:**
- Precise control over exactly which keys are counted
- Can intercept keys before they execute, enabling "wrong key" feedback

**Cons:**
- Extremely fragile: must remap dozens of keys per challenge type and restore them afterward
- Breaks user custom mappings (a user who remapped `dd` to something else would get the wrong behavior)
- Composing multi-key commands (e.g., `d3w`, `ci"`) requires reimplementing Vim's operator-pending mode
- High maintenance burden; every new command taught requires new remappings
- Fundamentally fights against Vim's design rather than working with it

**Why Option B is invalidated:** Remapping keys during challenges would break the core principle ("Real Vim, Real Muscle Memory"). Users must practice with real Vim behavior, not a simulation. The maintenance burden of remapping every taught command is also prohibitive for 35+ lessons.

#### Option C: Terminal Keylogger via `jobstart`

Spawn a background job that captures raw terminal input and pipes keystroke data back to the plugin.

**Pros:**
- Captures every raw keystroke including Ctrl sequences

**Cons:**
- Platform-dependent (different on macOS, Linux, WSL)
- Requires external process management
- Violates the "zero dependencies" constraint if it needs a helper binary
- Cannot easily correlate raw terminal bytes with Vim's internal key processing

**Why Option C is invalidated:** Platform dependency and external process requirement directly violate the zero-dependency constraint. Correlating raw terminal input with Vim's semantic actions is an unsolved hard problem.

### ADR: Architecture Decision Record

**Decision:** Use `vim.on_key()` for keystroke counting + autocmd-based validators for challenge completion detection (Option A).

**Drivers:** (1) Must not interfere with normal Vim behavior, (2) must work with user's existing mappings, (3) must be extensible across 6 challenge types without per-key remapping.

**Alternatives Considered:** Buffer-local keymap remapping (Option B), terminal keylogger (Option C).

**Why Chosen:** Option A is the only approach that counts keystrokes without intercepting or modifying them. It lets Vim process keys normally while the plugin observes from the side. The autocmd-based validators are the idiomatic Neovim pattern for reacting to editor state changes.

**Consequences:** Need careful filtering in `vim.on_key()` callback to exclude non-user keys. Some challenge types (visual selection, macro recording) will need multi-event state machines in their validators. Must use `vim.schedule()` to defer validation checks until after Vim has finished processing the key.

**Follow-ups:** Performance-test `vim.on_key()` with rapid typing to ensure no lag. Investigate whether `vim.on_key()` fires during macro playback (relevant for Ch8 macro challenges).

---

## 3. Implementation Steps

### Step 1: Project Skeleton and Plugin Bootstrap

**Objective:** Create the full directory structure, the autoload registration, the `:NVTutor` command with subcommand routing, and the highlight group definitions. After this step, `:NVTutor` should be a runnable command that prints a placeholder message.

**Files to create:**

```
nvtutor/
├── lua/nvtutor/
│   ├── init.lua
│   ├── highlights.lua
│   └── health.lua
├── plugin/
│   └── nvtutor.lua
├── doc/
│   └── nvtutor.txt
```

**Details:**

`plugin/nvtutor.lua` -- Autoload entry point:
- Guard against double-load (`if vim.g.loaded_nvtutor then return end`)
- Register the user command: `vim.api.nvim_create_user_command('NVTutor', function(opts) require('nvtutor').command(opts) end, { nargs = '?', complete = function() return {'menu', 'reset', 'stats'} end })`
- Set `vim.g.loaded_nvtutor = true`

`lua/nvtutor/init.lua` -- Plugin entry point:
- `M.command(opts)` -- Parse `opts.args` and route to: no args -> launch/resume, "menu" -> show chapter menu, "reset" -> clear progress with confirmation, "stats" -> show stats view
- `M.launch()` -- Check progress file: if new user -> start Ch1 L1; if returning -> show menu with "Continue where you left off"
- Module-level state table: `M._state = { active = false, chapter = nil, lesson = nil, challenge_idx = nil, buf = nil, win = nil, keystroke_count = 0, start_time = nil, on_key_ns = nil }`

`lua/nvtutor/highlights.lua` -- Highlight definitions:
- Define 7 highlight groups using `vim.api.nvim_set_hl(0, name, { default = true, ... })` so users can override them:
  - `NVTutorTarget` -- the thing to navigate to / act on (yellow bg or similar)
  - `NVTutorSuccess` -- correct action feedback (green)
  - `NVTutorHint` -- explanation/hint text (grey/dim)
  - `NVTutorError` -- wrong action feedback (red)
  - `NVTutorBronze` -- bronze tier indicator (#CD7F32)
  - `NVTutorSilver` -- silver tier indicator (#C0C0C0)
  - `NVTutorGold` -- gold tier indicator (#FFD700)
- Using `default = true` means these only apply if the user hasn't already defined them

`lua/nvtutor/health.lua` -- Checkhealth:
- Export `check()` function (Neovim 0.10+ health check convention)
- Check 1: Neovim version >= 0.10 (`vim.fn.has('nvim-0.10')`)
- Check 2: Data directory writable (`vim.fn.isdirectory(data_dir)` or can create it)
- Check 3: Progress file parseable (if exists)
- Use `vim.health.ok()`, `vim.health.warn()`, `vim.health.error()`

`doc/nvtutor.txt` -- Vimdoc:
- Standard vimdoc format with tags: `*nvtutor.txt*`, `*:NVTutor*`, `*nvtutor-chapters*`, `*nvtutor-scoring*`, `*nvtutor-highlights*`
- Document all subcommands, highlight groups, progress file location, and chapter overview

**Acceptance Criteria:**
- [ ] `:NVTutor` command is registered and callable without errors
- [ ] `:NVTutor menu`, `:NVTutor reset`, `:NVTutor stats` each route to distinct code paths (can be stubs)
- [ ] `:checkhealth nvtutor` runs and reports Neovim version check
- [ ] `:help nvtutor` opens the help file
- [ ] All 7 highlight groups are defined with `default = true`
- [ ] Plugin loads correctly via `require('nvtutor')` with no errors
- [ ] Double-sourcing `plugin/nvtutor.lua` does not error or create duplicate commands

---

### Step 2: Progress Persistence and UI Foundation

**Objective:** Implement the JSON-based progress system and the UI primitives (floating windows, menu rendering, buffer management). After this step, the plugin can read/write progress, create scratch buffers, and display floating windows.

**Files to create:**

```
lua/nvtutor/
├── progress.lua
└── ui.lua
```

**Details:**

`lua/nvtutor/progress.lua` -- Progress persistence:
- Data path: `vim.fn.stdpath('data') .. '/tutor/progress.json'`
- `M.load()` -- Read and decode JSON. Return default state if file missing or corrupt. Handle: file not found (return fresh state), JSON parse error (warn user, return fresh state), directory not existing (create it).
- `M.save(state)` -- Encode to JSON, write atomically (write to `.tmp` then rename to avoid corruption on crash)
- `M.reset()` -- Delete progress file, return fresh state
- Progress data schema:
  ```lua
  {
    version = 1,                    -- schema version for future migration
    current_chapter = 1,
    current_lesson = 1,
    current_challenge = 1,
    chapters_unlocked = 1,          -- highest unlocked chapter number
    chapters_completed = {},        -- set of completed chapter numbers: {[1] = true, [2] = true}
    lessons_completed = {},         -- keyed by "ch:lesson": {["1:1"] = true, ["1:2"] = true}
    mastery = {},                   -- keyed by command: {["j"] = "gold", ["k"] = "silver", ["dd"] = "bronze"}
    command_stats = {},             -- keyed by command: {["j"] = {best_keystrokes = 1, best_time = 0.8, attempts = 5}}
    total_time = 0,                 -- cumulative seconds spent in challenges
    gauntlet_completed = false,
    gauntlet_stats = nil,           -- {score = N, time = N, mastery_breakdown = {...}}
    review_state = nil,             -- nil when not in review; during review/gauntlet:
                                    -- { active = true, type = "review"|"gauntlet", chapter = N,
                                    --   challenges = [{challenge_def}, ...], current_idx = 1 }
                                    -- Enables quit/resume during review rounds and gauntlet
  }
  ```
- `M.is_new_user()` -- Returns true if no progress file exists or `current_chapter == 1` and `current_lesson == 1` and `current_challenge == 1`
- `M.mark_challenge_complete(chapter, lesson, challenge_idx, command, keystrokes, time)` -- Update mastery tier for the command, update `command_stats`, advance `current_challenge`
- `M.mark_lesson_complete(chapter, lesson)` -- Add to `lessons_completed`, advance `current_lesson`
- `M.mark_chapter_complete(chapter)` -- Add to `chapters_completed`, unlock next chapter, set `current_chapter` and reset `current_lesson`
- `M.get_mastery_tier(keystrokes, optimal_keystrokes, time, optimal_time)` -- Calculate tier:
  - Gold: keystrokes <= optimal AND time <= optimal * 1.5
  - Silver: keystrokes <= optimal * 1.5 AND time <= optimal * 2.5
  - Bronze: challenge completed (any keystroke/time)

`lua/nvtutor/ui.lua` -- UI primitives:
- `M.create_scratch_buffer(content_lines)` -- Create unlisted scratch buffer:
  - `vim.api.nvim_create_buf(false, true)` (not listed, scratch)
  - Set `buftype=nofile`, `buflisted=false`, `bufhidden=wipe`, `swapfile=false`
  - Set buffer lines from `content_lines`
  - Return buf handle
- `M.create_lesson_window(buf)` -- Open buffer in a centered floating window or take over the current window (spec doesn't mandate floating for the main practice area -- use current window for practice buffer so the user can use real Vim motions; use floating for instructions/hints/feedback):
  - Practice buffer: displayed in the current window via `vim.api.nvim_set_current_buf(buf)`
  - Set buffer-local options: `modifiable` as needed (lock during explanation, unlock during editing challenges)
- `M.show_floating(lines, opts)` -- Show a floating window for instructions, hints, or feedback:
  - Position options: `top` (above buffer for lesson explanation), `bottom` (below for hints/feedback), `center` (for menu)
  - Auto-size based on content
  - Return `{buf, win}` handles for later closing
- `M.show_menu(chapters_data, progress)` -- Render the chapter menu:
  - "Continue where you left off" at top if returning user
  - Each chapter: number, title, lock/unlock icon, mastery progress (e.g., "3/5 gold, 2/5 silver")
  - Keybindings: number keys to select chapter, `q` to quit
  - Locked chapters shown but greyed out and non-selectable
- `M.show_lesson_menu(chapter_n, lessons_data, progress)` -- Render lesson selection within a chapter:
  - Show all lessons in the chapter with completion indicators and mastery progress
  - Completed lessons show earned mastery tiers per command
  - All lessons are selectable (freely accessible within unlocked chapters per spec)
  - Keybindings: number keys to select lesson, `q` to return to chapter menu
  - This fulfills the spec requirement "Within an unlocked chapter, all lessons are freely accessible"
- `M.show_lesson_intro(explanation_lines)` -- Display the lesson explanation in a floating window at the top of the screen. Include "[Press any key to start challenges]" prompt.
- `M.show_challenge_prompt(challenge_num, total, instruction)` -- Show "Challenge 2/5: Delete the highlighted word" in a floating window
- `M.show_feedback(success, tier, keystrokes, optimal, time)` -- Flash success/error, show tier badge, show keystroke comparison
- `M.show_stats(progress)` -- Full stats screen: commands learned, mastery breakdown by tier, total time, chapter completion
- `M.teardown()` -- Close all floating windows, wipe scratch buffers, restore previous window layout. Track all created bufs/wins in a module-level list for reliable cleanup.
- `M.set_target_highlight(buf, line, col_start, col_end)` -- Apply `NVTutorTarget` extmark to the target region
- `M.set_success_highlight(buf, line, col_start, col_end)` -- Replace target highlight with `NVTutorSuccess`
- `M.clear_highlights(buf)` -- Remove all NVTutor extmarks from buffer

**Acceptance Criteria:**
- [ ] `progress.load()` returns a valid state table even when no file exists
- [ ] `progress.save()` writes valid JSON; `progress.load()` reads it back identically
- [ ] `progress.save()` uses atomic write (write to temp file, then rename)
- [ ] `progress.reset()` clears the file and returns fresh state
- [ ] `progress.get_mastery_tier()` returns correct tiers for edge cases (exact optimal, 1.5x, 2.5x boundaries)
- [ ] `ui.create_scratch_buffer()` returns a buffer with `buftype=nofile` and `buflisted=false`
- [ ] `ui.show_menu()` renders chapter list with lock indicators and progress
- [ ] `ui.teardown()` closes all floating windows and wipes scratch buffers without errors
- [ ] Highlight extmarks are visible on the target region and removable

---

### Step 3: Challenge Engine Core

**Objective:** Build the challenge engine that manages the lifecycle of a challenge: setup buffer state, start keystroke counting, detect completion via validators, compute score, and transition to the next challenge. This is the technical heart of the plugin.

**Files to create:**

```
lua/nvtutor/
└── engine.lua
```

**Details:**

`lua/nvtutor/engine.lua` -- Challenge engine:

**Keystroke Counting:**
- `M.start_counting(challenge_def)` -- Register a `vim.on_key(function(key, typed) ... end)` callback that increments `state.keystroke_count`. Filtering strategy uses the `typed` parameter (NOT `vim.fn.state()` which is unreliable inside callbacks):
  - Count the key if and only if `typed ~= nil` and `#typed > 0` (user-typed keys)
  - For Ch8 macro challenges where `challenge_def.count_macro_keys` is true, also count keys where `vim.fn.reg_executing() ~= ""` (macro playback)
  - Do NOT return anything from the callback (returning `""` would discard the key)
  - Store the namespace handle in `state.on_key_ns` for removal
- `M.stop_counting()` -- Remove the `vim.on_key()` callback via the namespace handle
- **Note on Escape key:** `<Esc>` counts as a keystroke. For insert-mode commands (Ch4), `optimal_keystrokes` must include the `<Esc>` to return to normal mode (e.g., `ciw` + "new" + `<Esc>` = 3 + len("new") + 1 keystrokes)

**Challenge Lifecycle:**
- `M.start_challenge(challenge_def)` -- The main entry point for each challenge:
  1. Set up the practice buffer content from `challenge_def.buffer_lines`
  2. Position cursor at `challenge_def.start_pos`
  3. Apply `NVTutorTarget` highlight to `challenge_def.target` region
  4. Show challenge prompt via `ui.show_challenge_prompt()`
  5. Make buffer modifiable if this is an editing challenge, read-only if movement
  6. Reset `keystroke_count = 0`, record `start_time = vim.loop.hrtime()`
  7. Call `M.start_counting()`
  8. Register the appropriate validator for this challenge type
  9. Set up autocmds for the validator to hook into

- `M.complete_challenge(keystrokes, elapsed_time, challenge_def)` -- Called by a validator when the challenge is detected as complete:
  1. Call `M.stop_counting()`
  2. Remove challenge-specific autocmds
  3. Calculate mastery tier via `progress.get_mastery_tier(keystrokes, challenge_def.optimal_keystrokes, elapsed_time, challenge_def.optimal_time)`
  4. Show success feedback via `ui.show_feedback()`
  5. Update progress via `progress.mark_challenge_complete()`
  6. After a brief pause (1-2 seconds or keypress to continue), advance to next challenge or end lesson

- `M.fail_challenge(reason)` -- Called when the user makes the buffer unsalvageable for the challenge:
  1. Flash error highlight
  2. Offer "Try again" (reset buffer to challenge start state) or "Skip"
- **Retry/Skip keybindings** -- During every challenge, set buffer-local keymaps:
  - `<C-r>` -- Retry: call `M.reset_buffer(challenge_def)` and restart the challenge
  - `<C-n>` -- Skip: mark challenge as attempted but not scored, advance to next
  - These keybindings are shown in the challenge prompt: "Ctrl-R: retry | Ctrl-N: skip"
  - Remove these keymaps on challenge completion or lesson exit

**Validator System:**

Each challenge type has a validator factory that returns a function. The validator is called after relevant autocmds fire. Validators are registered per-challenge, not globally.

```lua
M.validators = {
  movement = function(challenge_def)
    -- Returns a function that checks if cursor is at target position
    -- Hooks into: CursorMoved autocmd
    return function()
      local pos = vim.api.nvim_win_get_cursor(0)
      if pos[1] == challenge_def.target.line and pos[2] == challenge_def.target.col then
        M.complete_challenge(...)
      end
    end
  end,

  editing = function(challenge_def)
    -- Returns a function that checks if buffer matches expected state
    -- Hooks into: TextChanged, TextChangedI autocmds
    return function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      if M.lines_match(lines, challenge_def.expected_lines) then
        M.complete_challenge(...)
      end
    end
  end,

  visual = function(challenge_def)
    -- Returns a function that checks if the visual selection matches the target
    -- Hooks into: ModeChanged autocmd (specifically v/V/^V -> n transition)
    -- On mode change FROM visual TO normal, capture the last visual selection
    -- via vim.fn.getpos("'<") and vim.fn.getpos("'>")
    -- IMPORTANT: Only validate when buffer is UNCHANGED from initial state
    -- (guards against user exiting visual with an operator like 'vd' which
    -- would change the buffer AND fire ModeChanged v:n with stale marks)
    return function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      if not M.lines_match(lines, challenge_def.buffer_lines) then
        return -- buffer was modified (operator applied), skip visual check
      end
      local vstart = vim.fn.getpos("'<")
      local vend = vim.fn.getpos("'>")
      if M.selection_matches(vstart, vend, challenge_def.target) then
        M.complete_challenge(...)
      end
    end
  end,

  vim_language = function(challenge_def)
    -- Same as editing but scores more aggressively on keystrokes
    -- The "optimal" is the composed command (e.g., "di(" = 3 keystrokes)
    -- Hooks into: TextChanged
    return function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      if M.lines_match(lines, challenge_def.expected_lines) then
        M.complete_challenge(...)
      end
    end
  end,

  search = function(challenge_def)
    -- Check if cursor reached target position via search commands
    -- Hooks into: CursorMoved
    -- Same as movement but the target may be a word, not just a position
    return function()
      local pos = vim.api.nvim_win_get_cursor(0)
      if pos[1] == challenge_def.target.line and pos[2] == challenge_def.target.col then
        M.complete_challenge(...)
      end
    end
  end,

  power = function(challenge_def)
    -- Task-specific: check buffer state matches expected output
    -- For macros: expected_lines after macro application to all target lines
    -- For dot: expected_lines after dot repetition
    -- For increment: specific number values in buffer
    -- Hooks into: TextChanged
    return function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      if M.lines_match(lines, challenge_def.expected_lines) then
        M.complete_challenge(...)
      end
    end
  end,
}
```

**Buffer State Management:**
- `M.lines_match(actual, expected)` -- Compare buffer lines, trimming trailing whitespace. For editing challenges, only compare the lines that should change (challenge_def can specify `check_lines` as a range or list of line indices).
- `M.setup_buffer(challenge_def)` -- Write `buffer_lines` into the scratch buffer, position cursor, apply highlights, set modifiable flag.
- `M.reset_buffer(challenge_def)` -- Restore buffer to initial state for "try again" functionality.

**Autocmd Management:**
- Use `vim.api.nvim_create_augroup('NVTutorChallenge', { clear = true })` as a dedicated group
- Clear the group between challenges to prevent stale autocmds
- All challenge autocmds are buffer-local (`buffer = buf`)

**Timeout / Stuck Detection:**
- If no keystrokes for 30 seconds, show a hint (if available in `challenge_def.hint`)
- No hard timeout -- users can take as long as they want

**Acceptance Criteria:**
- [ ] `vim.on_key()` callback correctly counts user keystrokes during a challenge
- [ ] `vim.on_key()` callback does NOT count keys from `nvim_feedkeys()` or autocmd-triggered actions
- [ ] Movement validator detects cursor reaching target position
- [ ] Editing validator detects buffer matching expected state
- [ ] Visual validator detects correct visual selection (character, line, and block modes)
- [ ] Vim-language validator detects correct buffer transformation and scores on keystroke count
- [ ] Search validator detects cursor reaching target via search
- [ ] Power validator detects task-specific completion (buffer state match)
- [ ] Challenge autocmds are cleaned up between challenges (no stale handlers)
- [ ] `reset_buffer()` restores the buffer to exact initial state
- [ ] Mastery tier calculation matches spec (gold/silver/bronze thresholds)
- [ ] Hint appears after 30 seconds of inactivity

---

### Step 4: Chapter and Lesson Content System

**Objective:** Define the data format for chapters and lessons, then author all 8 chapters (~35 lessons, ~100-175 challenges). This is the highest-volume step but should be largely mechanical given a well-designed data format.

**Files to create:**

```
lua/nvtutor/chapters/
├── init.lua       -- Chapter registry, lesson loader, validate()
├── helpers.lua    -- Challenge builder factories (reduce authoring boilerplate)
├── ch1.lua        -- Chapter 1: First Steps (5 lessons)
├── ch2.lua        -- Chapter 2: Editing Essentials (6 lessons)
├── ch3.lua        -- Chapter 3: The Vim Language (2 lessons)
├── ch4.lua        -- Chapter 4: Insert & Change Mastery (7 lessons)
├── ch5.lua        -- Chapter 5: Precision Movement (3 lessons)
├── ch6.lua        -- Chapter 6: Document Navigation (3 lessons)
├── ch7.lua        -- Chapter 7: Search (2 lessons)
└── ch8.lua        -- Chapter 8: Power Commands (6 lessons)
```

**Details:**

`lua/nvtutor/chapters/init.lua` -- Chapter registry:
- `M.chapters` -- Ordered list of chapter metadata: `{ {id=1, title="First Steps", file="ch1"}, ... }`
- `M.get_chapter(n)` -- `return require('nvtutor.chapters.ch' .. n)`
- `M.get_lesson(chapter_n, lesson_n)` -- Return the specific lesson table
- `M.get_chapter_count()` -- Returns 8
- `M.get_lesson_count(chapter_n)` -- Returns lesson count for that chapter
- `M.validate()` -- Validate all challenge definitions across all chapters. Returns a list of errors/warnings. Checks:
  - All chapters load without error
  - All lessons have 3-5 challenges
  - All required fields present: `type`, `command`, `instruction`, `buffer_lines`, `start_pos`, `target` or `expected_lines`, `optimal_keystrokes`, `optimal_time`
  - `command` field is a non-empty string
  - `optimal_keystrokes > 0`
  - Target positions within buffer bounds
  - Expected lines differ from initial lines for editing challenges
  - No duplicate lesson IDs within a chapter
  - Called from `health.lua`'s `check()` function for `:checkhealth nvtutor`

`lua/nvtutor/chapters/helpers.lua` -- Challenge builder factories:
- `M.movement(opts)` -- Returns a movement challenge table from concise opts: `{instruction, lines, from, to, optimal, time, hint, command}`
- `M.editing(opts)` -- Returns an editing challenge: `{instruction, lines, start, expected, optimal, time, hint, command}`
- `M.visual(opts)` -- Returns a visual challenge: `{instruction, lines, start, target_region, optimal, time, hint, command}`
- `M.search(opts)` -- Returns a search challenge
- `M.power(opts)` -- Returns a power challenge
- `M.default_prose_lines` -- Reusable default buffer content (prose paragraphs) for movement challenges
- These return plain Lua tables (preserving the "Declarative Content" principle) but reduce authoring boilerplate by ~40%

**Chapter file format** (each `chN.lua` follows this pattern):

```lua
-- lua/nvtutor/chapters/ch1.lua
local M = {}

M.title = "First Steps"
M.description = "Learn the fundamental movements that make Vim efficient."

M.lessons = {
  {
    id = 1,
    title = "Vertical Movement",
    commands = { "j", "k" },
    explanation = {
      "In Vim, you navigate using the home row keys.",
      "  j - move down one line",
      "  k - move up one line",
      "",
      "This keeps your fingers on the home row instead of reaching for arrow keys.",
      "The mnemonic: j hangs down below the line, like a hook pulling you down.",
    },
    challenges = {
      {
        type = "movement",
        instruction = "Move the cursor to the highlighted line using j",
        buffer_lines = {
          "The quick brown fox jumps over the lazy dog.",
          "Pack my box with five dozen liquor jugs.",
          "How vexingly quick daft zebras jump.",
          "The five boxing wizards jump quickly.",
          "Jinxed wizards pluck ivy from the big quilt.",
        },
        start_pos = { 1, 0 },          -- line 1, col 0 (0-indexed col)
        target = { line = 4, col = 0 }, -- line 4, col 0
        command = "j",
        optimal_keystrokes = 2,          -- 3j = 2 keystrokes (digit + motion)
        optimal_time = 3.0,              -- seconds
        hint = "Try using a count: 3j moves down 3 lines at once",
      },
      -- ... 2-4 more challenges for j/k
    },
  },
  -- ... lessons 2-5
}

return M
```

**Challenge definition schema:**

```lua
{
  type = "movement" | "editing" | "visual" | "vim_language" | "search" | "power",
  command = "j",                                     -- REQUIRED: the specific command this challenge tests
                                                     -- used for per-command mastery tracking in progress
  instruction = "Human-readable instruction shown during the challenge",
  buffer_lines = { "line 1", "line 2", ... },     -- initial buffer content
  start_pos = { line, col },                        -- 1-indexed line, 0-indexed col
  target = {                                        -- varies by type
    line = N, col = N,                              -- for movement/search: target cursor position
    -- OR --
    start_line = N, start_col = N,                  -- for visual/editing: target region
    end_line = N, end_col = N,
  },
  expected_lines = { "line 1", ... },               -- for editing/vim_language/power: expected buffer after
  optimal_keystrokes = N,                            -- gold-tier keystroke count
                                                     -- NOTE: for insert-mode commands, include <Esc> in count
  optimal_time = N,                                  -- gold-tier time in seconds
  hint = "Optional hint text shown after inactivity",
  check_lines = { 2, 3 },                           -- optional: only check these line numbers for editing
  count_macro_keys = false,                          -- optional: for Ch8 macro challenges, count replayed keys
}
```

**Content authoring guidelines (to document in the chapter files):**
- Movement challenges: provide a multi-line buffer with a clear target position. Optimal keystrokes = count + motion (e.g., `3j` = 2 keystrokes, `w` = 1 keystroke, `5w` = 2 keystrokes).
- Editing challenges: provide initial buffer + expected buffer after the edit. Optimal keystrokes = the ideal command sequence (e.g., `dd` = 2, `dw` = 2, `d3w` = 3).
- Visual challenges: provide buffer + target region. The validator checks `'<` and `'>` marks after exiting visual mode.
- Vim-language challenges: same as editing but the optimal is the composed command (e.g., `di(` = 3 keystrokes, `ca"` = 3 keystrokes).
- Search challenges: same as movement but the optimal is the search command (e.g., `/word<CR>` = 5+ keystrokes for the word length + 2).
- Power challenges: task-specific. For macros: provide 5+ similar lines, expected output after macro application. For dot: provide initial state + 3 locations, expected state after dot repetitions. For increment: provide numbers, expected values after Ctrl-a/x.

**Acceptance Criteria:**
- [ ] All 8 chapter files load without errors via `require()`
- [ ] Each chapter has the correct number of lessons per the curriculum
- [ ] Each lesson has 3-5 challenges
- [ ] Every challenge has all required fields: `type`, `instruction`, `buffer_lines`, `start_pos`, `target` or `expected_lines`, `optimal_keystrokes`, `optimal_time`
- [ ] Challenge types match the spec mapping: Ch1/5/6 = movement, Ch2/4 = editing, Ch2 = visual, Ch3 = vim_language, Ch5/7 = search, Ch8 = power
- [ ] `chapters.get_lesson(N, M)` returns the correct lesson for any valid N, M
- [ ] Optimal keystroke counts are accurate for each challenge (manually verified)

---

### Step 5: Lesson Flow Orchestrator and Review Rounds

**Objective:** Wire together the engine, chapters, UI, and progress modules into a complete lesson flow: launch -> explanation -> challenges (1 through N) -> lesson complete -> next lesson or chapter review -> chapter complete -> next chapter or gauntlet. Also implement review rounds and the final gauntlet.

**Files to create/modify:**

```
lua/nvtutor/
├── init.lua       (MODIFY -- add lesson flow orchestration)
└── review.lua     (CREATE -- review round and gauntlet logic)
```

**Details:**

`lua/nvtutor/init.lua` -- Add orchestration methods:

- `M.launch()` -- Entry point from `:NVTutor`:
  1. Load progress via `progress.load()`
  2. Initialize highlights via `require('nvtutor.highlights').setup()`
  3. If `progress.review_state` is active -> resume review/gauntlet
  4. If `progress.is_new_user()` -> call `M.start_lesson(1, 1)`
  5. Else -> call `ui.show_menu()` with "Continue where you left off" pointing to `(current_chapter, current_lesson)`
  6. When user selects a chapter from menu -> call `ui.show_lesson_menu(chapter_n, lessons, progress)` to show lesson selection within that chapter

- `M.start_lesson(chapter_n, lesson_n)` -- Begin a lesson:
  1. Load lesson data via `chapters.get_lesson(chapter_n, lesson_n)`
  2. Create scratch buffer via `ui.create_scratch_buffer({})`
  3. Show lesson explanation via `ui.show_lesson_intro(lesson.explanation)`
  4. Wait for keypress to dismiss explanation
  5. Start first challenge via `M.start_challenge_sequence(chapter_n, lesson_n, 1)`

- `M.start_challenge_sequence(chapter_n, lesson_n, challenge_idx)` -- Run challenge N of the current lesson:
  1. Load challenge def from lesson data
  2. Call `engine.start_challenge(challenge_def)` with a completion callback
  3. On completion callback: show feedback, then after dismiss:
     - If more challenges in lesson -> `M.start_challenge_sequence(chapter_n, lesson_n, challenge_idx + 1)`
     - If last challenge -> call `M.complete_lesson(chapter_n, lesson_n)`

- `M.complete_lesson(chapter_n, lesson_n)` -- Handle lesson completion:
  1. Mark lesson complete in progress
  2. Show lesson summary (commands mastered, tiers earned)
  3. Determine next step:
     - If more lessons in chapter -> offer "Next Lesson" / "Back to Menu"
     - If last lesson in chapter -> start review round via `review.start_review(chapter_n)`
  4. Save progress

- `M.complete_chapter(chapter_n)` -- Handle chapter completion:
  1. Mark chapter complete, unlock next chapter
  2. Show chapter completion screen
  3. If chapter < 8 -> offer "Next Chapter" / "Back to Menu"
  4. If chapter == 8 -> start gauntlet via `review.start_gauntlet()`
  5. Save progress

**Quit/Resume handling:**
- Register `BufWinLeave` and `VimLeavePre` autocmds on the practice buffer
- On quit: save current position `(chapter, lesson, challenge_idx)` to progress, call `ui.teardown()`
- Check `vim.api.nvim_buf_is_valid(buf)` before cleanup operations (handles `:bdelete`/`:bwipeout` edge case)
- On resume (`:NVTutor` when `state.active` is false but progress has a partial lesson):
  - If `progress.review_state` is active: resume the review/gauntlet from `review_state.current_idx`
  - Otherwise: restore to the exact challenge within the lesson
- **Concurrency guard:** If `state.active` is true when `:NVTutor` is called, show a message "NVTutor is already active" and focus the existing practice buffer instead of creating a new one

`lua/nvtutor/review.lua` -- Review rounds and gauntlet:

- `M.start_review(chapter_n)` -- Generate a review round for chapter N:
  1. Check `progress.review_state` -- if active and matching this chapter, RESUME from `current_idx`
  2. Otherwise: collect all commands taught in chapters 1 through N
  3. Select 5-8 commands randomly (weighted toward commands with lower mastery tiers)
  4. For each selected command, pick one challenge from the command's lesson (or generate a variation)
  5. Save the selected challenges to `progress.review_state = { active=true, type="review", chapter=chapter_n, challenges=[...], current_idx=1 }`
  6. Run challenges in sequence using `engine.start_challenge()`
  7. After each challenge, update `review_state.current_idx` and save progress
  8. On completion -> clear `review_state`, call `init.complete_chapter(chapter_n)`

- `M.start_gauntlet()` -- Final gauntlet:
  1. Check `progress.review_state` -- if active with type="gauntlet", RESUME from `current_idx`
  2. Otherwise: collect ALL commands from all 8 chapters
  3. Select 10-15 challenges, at least one from each chapter, weighted toward lower mastery
  4. Save to `progress.review_state = { active=true, type="gauntlet", challenges=[...], current_idx=1 }`
  5. Run in sequence, updating `current_idx` after each challenge
  6. On completion -> clear `review_state`, show stats summary via `ui.show_stats()`, mark gauntlet complete

- `M.select_review_challenges(chapters_range, count)` -- Challenge selection logic:
  1. Get all commands from `chapters_range`
  2. Weight selection: commands with bronze mastery appear 3x, silver 2x, gold 1x, unmastered 4x
  3. Select `count` unique commands
  4. For each command, return a challenge definition (either from the original lesson or a generated variant with different buffer content but same mechanics)

**Acceptance Criteria:**
- [ ] First-time user flow: `:NVTutor` -> Ch1 L1 explanation -> challenges -> lesson complete -> next lesson
- [ ] Returning user flow: `:NVTutor` -> menu with progress -> select chapter -> lesson
- [ ] "Continue where you left off" correctly resumes at the exact challenge
- [ ] Quitting mid-lesson (`:q`) saves progress; re-running `:NVTutor` offers to resume
- [ ] Completing all lessons in a chapter triggers the review round
- [ ] Review round selects commands from prior chapters with mastery-weighted probability
- [ ] Completing chapter 8 review triggers the gauntlet
- [ ] Gauntlet includes challenges from all 8 chapters
- [ ] Stats summary displays after gauntlet completion
- [ ] Progress is saved after every challenge completion, lesson completion, and chapter completion
- [ ] All floating windows and scratch buffers are cleaned up on quit

---

### Step 6: Integration Testing and Polish

**Objective:** End-to-end verification of all flows, edge case handling, performance testing, and final polish. This step ensures the plugin is robust for real-world use.

**Activities:**

1. **End-to-end flow testing** -- Manually test these complete flows:
   - Fresh install: `:NVTutor` -> Ch1 L1 -> complete all Ch1 lessons -> review round -> menu appears
   - Resume: quit mid-Ch2 L3 challenge 2 -> `:NVTutor` -> resume at Ch2 L3 challenge 2
   - Reset: `:NVTutor reset` -> confirm -> `:NVTutor` -> starts at Ch1 L1 again
   - Stats: `:NVTutor stats` -> shows mastery breakdown
   - Menu navigation: `:NVTutor menu` -> locked chapters are non-selectable

2. **Challenge type verification** -- Test each of the 6 challenge types:
   - Movement: cursor navigation with counts (e.g., `3j` scores better than `jjj`)
   - Editing: delete, yank, change operations on highlighted targets
   - Visual: character, line, block selection matching
   - Vim-language: composed commands (`di(`, `ca"`, etc.)
   - Search: `/pattern`, `f`/`t` navigation to targets
   - Power: macros on multiple lines, dot repetition, increment/decrement

3. **Edge cases to test:**
   - Progress file corruption (invalid JSON) -> graceful recovery
   - Very fast typing (keystroke counter accuracy under rapid input)
   - Undo during editing challenges (`u` should be counted as keystrokes; if it undoes the target edit, challenge is not complete)
   - Macro recording during Ch8 challenges (`vim.fn.reg_executing()` interaction)
   - Multiple `:NVTutor` calls while already active (should not stack buffers/windows)
   - Window resize during floating windows (reposition or close gracefully)
   - `:NVTutor` in a non-empty buffer (should create new scratch buffer, not modify existing)

4. **Performance testing:**
   - `vim.on_key()` latency during rapid typing (> 100 WPM equivalent)
   - Progress file I/O for large progress states (all commands mastered)
   - Floating window creation/teardown speed

5. **Polish:**
   - Verify all highlight groups render correctly with popular colorschemes (catppuccin, tokyonight, gruvbox)
   - Ensure help tags generate correctly (`:helptags` on `doc/`)
   - Verify `:checkhealth nvtutor` output formatting
   - Test installation via lazy.nvim config: `{ 'user/nvtutor' }` (no setup call needed)

**Acceptance Criteria:**
- [ ] All acceptance criteria from the spec (lines 43-66 of the deep interview) pass
- [ ] No Lua errors in `:messages` during any normal flow
- [ ] `vim.on_key()` adds no perceptible latency during normal typing
- [ ] Progress survives: quit mid-challenge -> resume, Neovim crash simulation (kill -9) -> progress.json is valid
- [ ] Plugin loads in < 5ms (measure with `vim.loop.hrtime()` around `require('nvtutor')`)
- [ ] All 7 highlight groups visible and user-overridable (test by defining them before plugin load)
- [ ] `:checkhealth nvtutor` reports all-OK on a valid Neovim 0.10+ install
- [ ] `:help nvtutor` renders correctly with all tags navigable

---

## 4. Acceptance Criteria (Master Checklist)

These map directly to the spec's acceptance criteria:

- [ ] `:NVTutor` command launches the plugin
- [ ] First-time users dropped directly into Chapter 1, Lesson 1 with no menu
- [ ] Each lesson displays a brief explanation followed by 3-5 interactive challenges
- [ ] Challenges show highlighted target text; plugin detects correct Vim action
- [ ] Scoring based on keystrokes + time
- [ ] Each command earns bronze, silver, or gold mastery tier
- [ ] Chapters unlock sequentially (Ch1 required for Ch2, etc.)
- [ ] Within an unlocked chapter, all lessons freely accessible
- [ ] After Ch1, chapter menu shows progress and mastery tiers
- [ ] "Continue where you left off" option on menu
- [ ] Review round at end of each chapter mixes prior commands
- [ ] Progress persists between sessions via JSON
- [ ] Works with lazy.nvim, packer, vim-plug, manual install
- [ ] No external dependencies
- [ ] Works on Neovim 0.10+
- [ ] Final gauntlet after all 8 chapters
- [ ] Stats summary after gauntlet
- [ ] Challenge formats vary by command type (6 types)
- [ ] `:help nvtutor` opens vimdoc
- [ ] `:checkhealth nvtutor` verifies version, data dir, integrity
- [ ] 7 highlight groups are user-overridable with sensible defaults
- [ ] Practice buffers are scratch/unlisted, not saved by session plugins
- [ ] Quitting mid-lesson saves progress; resuming restores exact position
- [ ] Subcommands: `:NVTutor`, `:NVTutor menu`, `:NVTutor reset`, `:NVTutor stats`

---

## 5. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `vim.on_key()` counts internal/non-user keys, inflating keystroke scores | HIGH | MEDIUM | Filter by the `typed` parameter of the `vim.on_key()` callback: count only when `typed ~= nil` and `#typed > 0`. Use `vim.fn.reg_executing()` additionally for Ch8 macro challenges. Build a test harness that feeds known key sequences via `nvim_feedkeys` and verifies they are NOT counted. |
| Visual mode selection detection is unreliable across character/line/block modes | MEDIUM | HIGH | Use `ModeChanged` autocmd to detect exit from visual mode, then read `'<` and `'>` marks. Test all three visual modes explicitly. For block mode, also check `visualmode()` return value. |
| Editing challenge validator triggers too early (TextChanged fires mid-command) | MEDIUM | MEDIUM | Wrap validator in `vim.schedule()` to defer until after the full command completes. For multi-key commands, add a debounce of ~50ms before checking buffer state. |
| Macro recording (Ch8) interferes with `vim.on_key()` counting | MEDIUM | MEDIUM | During macro challenges, switch counting strategy: count the `q{reg}` start, then the `@{reg}` playback, but score based on how many times the macro was applied vs. expected. Define per-challenge scoring override in the power validator. |
| Content authoring errors (wrong optimal keystrokes, impossible challenges) | HIGH | LOW | Add a validation function `chapters.validate()` callable from checkhealth that verifies all challenges have valid fields, optimal_keystrokes > 0, target positions within buffer bounds, and expected_lines differ from buffer_lines for editing challenges. |
| Progress file corruption on crash | LOW | MEDIUM | Atomic write (write to .tmp, rename). On load failure, warn user and offer fresh start. Schema version field allows future migration. |
| User has conflicting buffer-local keymaps that interfere | LOW | LOW | The plugin does not set any buffer-local keymaps for challenge interaction (that is the whole point of Option A). The only keymaps are for UI elements (menu navigation, dismiss prompts). |

---

## 6. Verification Steps

### Automated Verification

1. **Challenge data validation:** Run `require('nvtutor.chapters').validate()` (to be implemented in Step 4) which checks:
   - All chapters load without error
   - All lessons have 3-5 challenges
   - All required fields present in every challenge
   - Optimal keystrokes > 0
   - Target positions within buffer bounds
   - Expected lines differ from initial lines for editing challenges
   - No duplicate lesson IDs within a chapter

2. **Progress round-trip test:** `progress.save(state); assert(vim.deep_equal(state, progress.load()))`

3. **Mastery tier calculation test:**
   - `get_mastery_tier(3, 3, 2.0, 3.0)` == "gold" (exact optimal keystrokes, under time)
   - `get_mastery_tier(4, 3, 5.0, 3.0)` == "silver" (1.33x keystrokes, 1.67x time)
   - `get_mastery_tier(10, 3, 15.0, 3.0)` == "bronze" (over both thresholds)

### Manual Verification

4. **Fresh install test:**
   - Clone repo into `~/.local/share/nvim/site/pack/test/start/nvtutor/`
   - Launch Neovim, run `:NVTutor`
   - Verify: lands in Ch1 L1, explanation shown, challenges work, scoring shown

5. **Complete flow test:**
   - Complete Ch1 entirely
   - Verify: review round triggers, chapter menu appears, Ch2 unlocked, Ch3+ locked
   - Open Ch2, complete one lesson, quit
   - Re-launch: "Continue where you left off" points to Ch2 L2

6. **Keystroke accuracy test:**
   - Start a movement challenge where optimal = 3 (e.g., `3j`)
   - Type `jjj` (3 keystrokes) and verify count = 3
   - Reset and type `3j` (2 keystrokes) and verify count = 2
   - Verify tier difference (2 keystrokes on a 3-optimal -> gold; 3 keystrokes -> silver or gold depending on time)

7. **Health check verification:**
   - Run `:checkhealth nvtutor` on Neovim 0.10+
   - Run on Neovim 0.9 if available -- verify version warning

8. **Colorscheme compatibility:**
   - Load with `:colorscheme default`, `:colorscheme habamax`
   - Verify all 7 highlight groups are visible and readable
   - Override one (`vim.api.nvim_set_hl(0, 'NVTutorTarget', {bg='#FF0000'})`) before loading plugin; verify override takes effect

---

## Dependency Graph

```
Step 1 (Skeleton)
  |
  v
Step 2 (Progress + UI)
  |
  v
Step 3 (Engine) -----> Step 4 (Content)
  |                       |
  v                       v
Step 5 (Orchestration + Review)
  |
  v
Step 6 (Testing + Polish)
```

Steps 3 and 4 can be worked on in parallel once Step 2 is complete. Step 3 defines the challenge interface that Step 4 populates. Step 5 wires everything together and depends on both 3 and 4. Step 6 is the final integration pass.

---

## Estimated Complexity

- **Total files:** 17 Lua files + 1 vimdoc + 1 README (added helpers.lua, updated counts)
- **Total lines (estimate):** ~3,500-4,500 LOC
  - Engine + validators: ~400-500
  - UI: ~350-450
  - Progress: ~150-200
  - Review/gauntlet: ~200-250
  - Chapter content (8 files): ~2,000-2,500 (bulk of the code is challenge data)
  - Init/orchestration: ~250-350
  - Health/highlights/plugin: ~100-150
  - Vimdoc: ~200-300
- **Complexity rating:** MEDIUM-HIGH (the engine/validator system is the hard part; content is high volume but low complexity)

---

## Revision History

### Revision 1 (Architect + Critic Review)
Applied 10 improvements from consensus review:
1. **CRITICAL FIX:** Replaced `vim.fn.state()` keystroke filtering with `typed` parameter in `vim.on_key()` — old strategy was empirically broken
2. Added `command` field to challenge definition schema for per-command mastery tracking
3. Added `review_state` to progress schema for quit/resume during review rounds and gauntlet
4. Added lesson selection sub-menu (`ui.show_lesson_menu()`) for free navigation within chapters
5. Added retry/skip keybindings (`<C-r>`/`<C-n>`) during challenges to prevent stuck states
6. Added `chapters.validate()` function with call from `health.lua`
7. Added `chapters/helpers.lua` with challenge builder factories (~40% authoring boilerplate reduction)
8. Fixed `optimal_keystrokes` example: `3j` = 2 keystrokes (was incorrectly 3)
9. Added visual challenge operator-exit guard (buffer-unchanged check before mark validation)
10. Clarified Escape key counting policy for insert-mode commands
11. Added concurrency guard for multiple `:NVTutor` calls
12. Added `vim.api.nvim_buf_is_valid()` check before buffer cleanup
13. Added review/gauntlet resume logic with `review_state` persistence
