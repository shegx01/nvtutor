# NVTutor

An interactive Neovim plugin that teaches Vim commands through hands-on challenges. Practice real Vim commands in a real editor -- no simulations, no browser, just muscle memory.

## Features

- **9 progressive chapters** (61 lessons, ~200+ challenges) covering movement, editing, visual modes, the Vim language, search, power commands, and curated tricks
- **Basic + Advanced tiers** -- each chapter has foundational lessons, then advanced lessons that unlock after mastering the basics
- **Hybrid "teach then challenge" format** -- each lesson explains a concept, then presents 3-5 interactive challenges
- **Mastery tiers** (bronze/silver/gold) based on keystroke efficiency and speed
- **Optimal solution display** -- after completing a challenge, see the most efficient approach
- **Chapter review rounds** that mix commands from prior chapters for reinforcement
- **Final gauntlet** that tests all commands across every chapter
- **Progress persistence** across sessions
- **Zero configuration** -- install and run `:NVTutor`
- **No dependencies** -- pure Lua, works with any colorscheme

## Requirements

- Neovim >= 0.10

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'shegx01/nvtutor',
  cmd = 'NVTutor',
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'shegx01/nvtutor',
  cmd = 'NVTutor',
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'shegx01/nvtutor', { 'on': 'NVTutor' }
```

### [mini.deps](https://github.com/echasnovski/mini.deps)

```lua
MiniDeps.add({ source = 'shegx01/nvtutor' })
```

### Manual

```sh
git clone https://github.com/shegx01/nvtutor.git \
  ~/.local/share/nvim/site/pack/plugins/start/nvtutor
```

## Usage

```vim
:NVTutor          " Launch (first-time: starts Ch1; returning: shows menu)
:NVTutor menu     " Show chapter selection menu
:NVTutor stats    " View mastery statistics
:NVTutor reset    " Reset all progress
```

During challenges:

| Key      | Action                                      |
|----------|---------------------------------------------|
| `Ctrl-L` | Retry the current challenge                 |
| `Ctrl-H` | Toggle hint (when available for a challenge)|
| `Ctrl-N` | Skip to the next challenge                  |

No `setup()` call needed. Install the plugin and run `:NVTutor`.

## Chapters

| #  | Chapter                    | Topics                                           |
|----|----------------------------|--------------------------------------------------|
| 1  | **First Steps**            | `j` `k` `h` `l`, modes, text objects, `w` `b` `e` `ge` |
| 2  | **Editing Essentials**     | `y` `p`, `d` `dd` `x`, `v` `V` `Ctrl-v`, `>` `<` `=`  |
| 3  | **The Vim Language**       | `diw` `ciw` `daw`, `di(` `ci"` `da[`            |
| 4  | **Insert & Change Mastery**| `o` `O`, `r`, `s` `S`, `i` `a`, `I` `A`, `D` `C` `cc` |
| 5  | **Precision Movement**     | `f` `F` `t` `T`, `df` `ct`, `0` `^` `$`         |
| 6  | **Document Navigation**    | `gg` `G` `Ctrl-d` `Ctrl-u`, `{n}G`, `{` `}`     |
| 7  | **Search**                 | `/` `?` `n` `N`, `*` `#`                         |
| 8  | **Power Commands**         | `Ctrl-a` `Ctrl-x`, macros, `%`, `.`, `J`, `~` `gu` `gU` |
| 9  | **Vim Tricks**             | `cgn` formula, `xp`/`ddp`, `gf`/`gx`, `:g`/`:v`, config tips |

Chapters unlock sequentially. Each chapter has **basic** and **advanced** (★) lessons. Advanced lessons unlock after completing all basic lessons in that chapter.

## How It Works

1. **First launch** drops you directly into Chapter 1, Lesson 1 -- no menu, no friction
2. Each lesson starts with a **brief explanation**, then presents **3-5 interactive challenges**
3. Challenges show **highlighted targets** in the buffer -- perform the correct Vim command to complete them
4. You're scored on **keystrokes** (fewer = better) and **time**, earning bronze/silver/gold mastery
5. After completion, advanced challenges show the **optimal solution** so you learn the best approach
6. Each chapter ends with a **review round** mixing commands from all prior chapters
7. After all 9 chapters, a **final gauntlet** tests everything you've learned

## Scoring

| Tier   | Criteria                                               |
|--------|--------------------------------------------------------|
| Gold   | Keystrokes <= optimal **and** time <= optimal x 1.5    |
| Silver | Keystrokes <= optimal x 1.5 **and** time <= optimal x 2.5 |
| Bronze | Challenge completed                                    |

Mastery tiers are tracked per command and persist between sessions.

## Progress

Progress is saved to `~/.local/share/nvim/tutor/progress.json` and includes:

- Current chapter/lesson position
- Per-command mastery tiers and best scores
- Chapter completion status
- Total practice time

Run `:NVTutor reset` to start fresh. Run `:checkhealth nvtutor` to verify your setup.

## Customization

NVTutor defines highlight groups with sensible defaults that respect your colorscheme. Override them in your config:

```lua
vim.api.nvim_set_hl(0, 'NVTutorTarget', { bg = '#3B3820', fg = '#E0D060', bold = true })
vim.api.nvim_set_hl(0, 'NVTutorSuccess', { bg = '#1E3A1E', fg = '#60E060', bold = true })
vim.api.nvim_set_hl(0, 'NVTutorHint', { fg = '#888888', italic = true })
vim.api.nvim_set_hl(0, 'NVTutorError', { bg = '#3A1E1E', fg = '#E06060', bold = true })
vim.api.nvim_set_hl(0, 'NVTutorBronze', { fg = '#CD7F32', bold = true })
vim.api.nvim_set_hl(0, 'NVTutorSilver', { fg = '#C0C0C0', bold = true })
vim.api.nvim_set_hl(0, 'NVTutorGold', { fg = '#FFD700', bold = true })
```

## Inspired By

- [vimtutor](https://vimhelp.org/usr_01.txt.html#vimtutor) -- the original Vim tutorial
- [vim-be-good](https://github.com/ThePrimeagen/vim-be-good) -- gamified Vim practice

## License

MIT
