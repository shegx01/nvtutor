# Deep Interview Spec: NVTutor — Interactive Vim Tutorial Plugin for Neovim

## Metadata
- Interview ID: vim-tutor-2026-04-21
- Rounds: 10
- Final Ambiguity Score: 9%
- Type: greenfield
- Generated: 2026-04-21
- Threshold: 0.2
- Status: PASSED

## Clarity Breakdown
| Dimension | Score | Weight | Weighted |
|-----------|-------|--------|----------|
| Goal Clarity | 0.95 | 0.40 | 0.380 |
| Constraint Clarity | 0.88 | 0.30 | 0.264 |
| Success Criteria | 0.90 | 0.30 | 0.270 |
| **Total Clarity** | | | **0.914** |
| **Ambiguity** | | | **0.086** |

## Goal
Build **NVTutor**, an interactive Neovim plugin written in Lua that teaches Vim commands through a hybrid "teach then challenge" format across 8 progressive chapters. Each lesson starts with a brief explanation, then presents 3-5 interactive challenges where the user performs real Vim commands on highlighted targets in the buffer. The plugin scores users on keystrokes and time, awards mastery tiers (bronze/silver/gold) per command, and includes review rounds at the end of each chapter that mix commands from prior chapters. First-time users are immersed directly into Chapter 1 with zero menu friction; returning users see a chapter menu with progress indicators and "Continue where you left off."

## Constraints
- **Platform:** Neovim only (no classic Vim support)
- **Language:** Lua
- **Minimum version:** Neovim 0.10+
- **Launch command:** `:NVTutor`
- **Data persistence:** JSON file at `~/.local/share/nvim/tutor/progress.json`
- **Dependencies:** None — zero external dependencies
- **Plugin structure:** Standard Lua plugin layout (`lua/nvtutor/`) compatible with lazy.nvim, packer, vim-plug, and manual install
- **No formal SRS/scheduling system** — reinforcement is via mastery tiers and chapter review rounds

## Non-Goals
- Classic Vim (VimScript) support
- Web app or browser-based version
- Full spaced repetition system with scheduled reviews
- SQLite or complex database storage
- Multiplayer or leaderboards
- Plugin for other editors (VS Code, Emacs, etc.)

## Acceptance Criteria
- [ ] `:NVTutor` command launches the plugin
- [ ] First-time users are dropped directly into Chapter 1, Lesson 1 with no menu
- [ ] Each lesson displays a brief explanation followed by 3-5 interactive challenges
- [ ] Challenges show highlighted target text in the buffer; plugin detects correct Vim action
- [ ] Scoring is based on keystrokes used (fewer = better) and time taken
- [ ] Each command earns a mastery tier: bronze, silver, or gold based on performance
- [ ] Chapters unlock sequentially (must complete Ch1 to access Ch2)
- [ ] Within an unlocked chapter, all lessons are freely accessible
- [ ] After completing Chapter 1, a chapter menu appears showing progress and mastery tiers
- [ ] "Continue where you left off" option at the top of the chapter menu
- [ ] Review round at the end of each chapter mixes commands from prior chapters
- [ ] Progress (mastery tiers, chapter completion) persists between sessions via JSON file
- [ ] Plugin works with lazy.nvim, packer, vim-plug, and manual install
- [ ] No external dependencies required
- [ ] Works on Neovim 0.10+
- [ ] Final gauntlet challenge after completing all 8 chapters, mixing commands from every chapter
- [ ] Stats summary screen after gauntlet showing total mastery breakdown, time, commands learned
- [ ] Challenge formats vary by command type (see Challenge Design section)
- [ ] `:help nvtutor` opens vimdoc documentation (`doc/nvtutor.txt`)
- [ ] `:checkhealth nvtutor` verifies Neovim version, data dir writability, plugin integrity
- [ ] Highlight groups (`NVTutorTarget`, `NVTutorSuccess`, `NVTutorHint`, `NVTutorError`, `NVTutorBronze`, `NVTutorSilver`, `NVTutorGold`) are user-overridable and link to sensible built-in defaults
- [ ] Practice buffers are scratch/unlisted (`buftype=nofile`, `buflisted=false`), not saved by session plugins
- [ ] Quitting mid-lesson (`:q`, closing Neovim) saves progress; resuming restores exact position
- [ ] Subcommands: `:NVTutor` (launch/resume), `:NVTutor menu` (chapter list), `:NVTutor reset` (clear progress), `:NVTutor stats` (view mastery)

## Challenge Design by Command Type

| Chapter Type | Challenge Format | Scoring Criteria |
|-------------|-----------------|-----------------|
| **Movement (Ch1, 5, 6)** | Highlighted target position; navigate there | Keystrokes (e.g., 3j vs jjj = gold) |
| **Editing (Ch2, 4)** | Highlighted target word/line; perform action | Buffer changed correctly + keystrokes + time |
| **Visual modes (Ch2)** | Region to select; enter visual mode and match | Exact selection match + keystrokes |
| **Vim language (Ch3)** | Transformation goal shown; compose verb+modifier+object | Fewest keystrokes for correct result |
| **Search/Find (Ch5, 7)** | Target word/char in buffer; reach it via f/t// | Precision (direct hit vs. multiple attempts) |
| **Power commands (Ch8)** | Varies: macros on 5 lines, dot on 3 places, increment to value | Task-specific: efficiency + correctness |

## Assumptions Exposed & Resolved
| Assumption | Challenge | Resolution |
|------------|-----------|------------|
| Spaced repetition is needed | vimtutor taught millions without SRS — real repetition happens when editing files daily | Gamified mastery tiers + chapter review rounds instead of formal SRS |
| Should support classic Vim | Neovim's Lua API + floating windows enable far richer interactivity | Neovim-only for best UX |
| Complex persistence (SQLite) needed | Only ~40 commands across 8 chapters to track | Simple JSON file — zero dependencies, human-readable, portable |
| All chapters should be open from start | New users don't know basic movement yet — Ch5 without Ch1 would be confusing | Guided first-run into Ch1, then semi-linear unlock |
| Need Neovim 0.9 for broader compat | 0.9 approaching EOL; 0.10 has stabilized APIs we need with no workarounds | Target 0.10+ for modern APIs and future-proofing |
| Need setup() function | Tutorial plugin has almost nothing to configure — keybinding customization defeats the purpose | No setup() — zero-config, install and run :NVTutor |

## Technical Context
- **Neovim APIs to use:** Floating windows (instructions/hints), extmarks (highlighting targets), virtual text (inline feedback), autocmds (detecting user actions), keymaps (capturing input during challenges)
- **Plugin structure:**
  ```
  nvtutor/
  ├── lua/nvtutor/
  │   ├── init.lua          -- Plugin entry point, :NVTutor command + subcommands
  │   ├── chapters/         -- Chapter definitions and lesson content
  │   ├── engine.lua        -- Challenge engine (detection, scoring)
  │   ├── ui.lua            -- Floating windows, highlights, menu
  │   ├── progress.lua      -- JSON read/write for mastery/progress
  │   ├── review.lua        -- Review round logic
  │   ├── health.lua        -- :checkhealth nvtutor
  │   └── highlights.lua    -- Highlight group definitions (NVTutor*)
  ├── plugin/
  │   └── nvtutor.lua       -- Autoload: registers :NVTutor command
  ├── doc/
  │   └── nvtutor.txt       -- Vimdoc help (:help nvtutor)
  └── README.md
  ```

## Curriculum

### Chapter 1: First Steps
1. Vertical Movement — j/k basics
2. Horizontal Movement — h/l basics
3. Introduction to Modes — Normal, Insert, Visual, Command
4. Text Objects in Vim — words, sentences, paragraphs
5. Word Based Movement — w, b, e, ge

### Chapter 2: Editing Essentials
1. Yanking and Putting — y, p, P
2. Deletion — d, dd, x
3. Visual Character Mode — v
4. Visual Line Mode — V
5. Blockwise Visual Mode — Ctrl-v
6. Indentation — >, <, =

### Chapter 3: The Vim Language
1. Verb + Text Object — d + iw, c + ap, etc.
2. Verb + Modifier + Text Object — d + i + (, c + a + ", etc.

### Chapter 4: Insert & Change Mastery
1. Insert Lines — o, O
2. Paste Precisely — p, P, gp, gP
3. Replace Character — r
4. Substitute — s, S
5. Insert and Append — i, a
6. Line Based Insert and Append — I, A
7. Delete and Change Lines — D, C, cc

### Chapter 5: Precision Movement
1. Find and Till — f, F, t, T
2. Vim Language with Find and Till — df, ct, etc.
3. Start and End of Line — 0, ^, $

### Chapter 6: Document Navigation
1. Document Movements — gg, G, Ctrl-d, Ctrl-u
2. Line Number Movement — :{n}, {n}G, {n}gg
3. Paragraph Navigation — {, }

### Chapter 7: Search
1. Patterns — /, ?, n, N
2. Search Word — *, #

### Chapter 8: Power Commands
1. Dealing With Numbers — Ctrl-a, Ctrl-x
2. Macros — q, @, @@
3. Matching Brackets — %
4. Dot Command — .
5. Join Lines — J
6. Lowercase and Uppercase — ~, gu, gU

## Ontology (Key Entities)

| Entity | Type | Fields | Relationships |
|--------|------|--------|---------------|
| Plugin | core domain | name="NVTutor", platform=Neovim, lang=Lua, cmd=:NVTutor | contains Chapters |
| Chapter | core domain | number (1-8), title, topics, locked/unlocked | contains Lessons, ends with ReviewRound |
| Lesson | core domain | topic, explanation text, command(s) taught | contains Challenges |
| Challenge | core domain | target text, expected action, scoring (keystrokes, time) | earns MasteryTier |
| Learner | supporting | current chapter, current lesson, progress | completes Challenges, has MasteryTiers |
| MasteryTier | supporting | levels=bronze/silver/gold, per-command | awarded per command based on Challenge performance |
| ReviewRound | core domain | mixed commands from prior chapters | belongs to Chapter end |
| ProgressFile | supporting | path=~/.local/share/nvim/tutor/progress.json, format=JSON | stores Learner progress |
| ChapterMenu | supporting | progress indicators, mastery display, continue button | shown after Ch1 completion |
| Gauntlet | core domain | mixed commands from all chapters, graduation test | unlocked after all 8 chapters complete |
| StatsSummary | supporting | total mastery breakdown, time, commands learned | shown after Gauntlet completion |
| ChallengeType | supporting | movement, editing, visual, vim-language, search, power | determines Challenge format per Chapter |

## Ontology Convergence

| Round | Entity Count | New | Changed | Stable | Stability Ratio |
|-------|-------------|-----|---------|--------|----------------|
| 1 | 4 | 4 | - | - | N/A |
| 2 | 5 | 1 | 0 | 4 | 80% |
| 3 | 5 | 0 | 0 | 5 | 100% |
| 4 | 7 | 2 | 0 | 5 | 71% |
| 5 | 7 | 0 | 0 | 7 | 100% |
| 6 | 8 | 1 | 0 | 7 | 88% |
| 7 | 9 | 1 | 0 | 8 | 89% |
| 8 | 9 | 0 | 0 | 9 | 100% |
| 9 | 11 | 2 | 0 | 9 | 82% |
| 10 | 12 | 1 | 0 | 11 | 92% |

## Interview Transcript
<details>
<summary>Full Q&A (10 rounds)</summary>

### Round 1
**Q:** You asked 'can we make a vim tutorial interactive or make it a web app?' — Vim plugin vs web app vs Neovim-only?
**A:** Vim plugin (Recommended) — runs inside Vim/Neovim, users practice real commands in a real editor.
**Ambiguity:** 65% (Goal: 0.50, Constraints: 0.30, Criteria: 0.20)

### Round 2
**Q:** What should the lesson experience look like? Guided exercises, game challenges, hybrid, or sandbox?
**A:** Hybrid: teach then challenge — each lesson starts with a brief explanation, then presents 3-5 interactive challenges with scoring.
**Ambiguity:** 55% (Goal: 0.60, Constraints: 0.30, Criteria: 0.40)

### Round 3
**Q:** Should this target classic Vim, Neovim only, or both?
**A:** Neovim only (Recommended) — Lua + richer API for floating windows, virtual text, highlights.
**Ambiguity:** 45% (Goal: 0.65, Constraints: 0.55, Criteria: 0.40)

### Round 4 (Contrarian Mode)
**Q:** What if spaced repetition ISN'T needed? vimtutor has none and taught millions.
**A:** Yes, mastery tiers + review rounds — gamified mastery per command (bronze/silver/gold) plus chapter-end review rounds. No formal SRS.
**Ambiguity:** 39% (Goal: 0.70, Constraints: 0.55, Criteria: 0.55)

### Round 5
**Q:** What should a challenge concretely look like in the buffer?
**A:** Highlighted target + detect action — show text with highlighted targets, detect correct action, score on keystrokes + time.
**Ambiguity:** 34% (Goal: 0.75, Constraints: 0.55, Criteria: 0.65)

### Round 6 (Simplifier Mode)
**Q:** Where should mastery scores be persisted?
**A:** Simple JSON file at ~/.local/share/nvim/tutor/progress.json — zero dependencies, human-readable, portable.
**Ambiguity:** 29% (Goal: 0.75, Constraints: 0.70, Criteria: 0.65)

### Round 7
**Q:** How should users navigate — linear progression, fully open, semi-linear, or guided first-run?
**A:** Guided first-run then semi-linear — first launch goes straight into Ch1 (no menu). After Ch1, chapter menu with sequential unlocking. Within unlocked chapters, all lessons freely accessible.
**Ambiguity:** 22% (Goal: 0.85, Constraints: 0.72, Criteria: 0.75)

### Round 8
**Q:** Launch command and minimum Neovim version?
**A:** :NVTutor command, Neovim 0.10+ for modern stable APIs with no workarounds.
**Ambiguity:** 16% (Goal: 0.88, Constraints: 0.85, Criteria: 0.78)

### Round 9
**Q:** What happens when a user completes all 8 chapters? Congratulations screen, final gauntlet, both, or no fanfare?
**A:** Both: gauntlet then stats — a final mixed-command gauntlet as the graduation exam, followed by a full stats summary.
**Ambiguity:** 12% (Goal: 0.92, Constraints: 0.85, Criteria: 0.85)

### Round 10
**Q:** How should challenges differ per chapter type? Movement vs editing vs visual vs search vs power commands.
**A:** Yes, mapping works — each chapter type gets a tailored challenge format (movement=navigate to target, editing=transform buffer, visual=match selection, vim language=compose command, search=find target, power=task-specific).
**Ambiguity:** 9% (Goal: 0.95, Constraints: 0.88, Criteria: 0.90)

</details>
