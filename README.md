# NVTutor

An interactive Neovim plugin that teaches Vim commands through hands-on challenges.

## Features

- **8 progressive chapters** covering movement, editing, visual modes, the Vim language, search, and power commands
- **Hybrid "teach then challenge" format** — each lesson explains a concept, then presents 3-5 interactive challenges
- **Mastery tiers** (bronze/silver/gold) based on keystroke efficiency and speed
- **Chapter review rounds** that mix commands from prior chapters for reinforcement
- **Final gauntlet** that tests all commands across every chapter
- **Progress persistence** across sessions via JSON
- **Zero configuration** — install and run `:NVTutor`

## Requirements

- Neovim 0.10+

## Installation

### lazy.nvim

```lua
{ 'yourusername/nvtutor' }
```

### vim-plug

```vim
Plug 'yourusername/nvtutor'
```

### packer

```lua
use 'yourusername/nvtutor'
```

### Manual

Clone into your Neovim packages directory:

```sh
git clone https://github.com/yourusername/nvtutor \
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
- `Ctrl-L` — Retry the current challenge
- `Ctrl-N` — Skip to the next challenge

## Chapters

1. **First Steps** — j/k, h/l, modes, text objects, word movement
2. **Editing Essentials** — yank/put, deletion, visual modes, indentation
3. **The Vim Language** — verb + text object, verb + modifier + text object
4. **Insert & Change Mastery** — o/O, paste, replace, substitute, i/a, I/A, D/C
5. **Precision Movement** — f/F/t/T, find+verb combos, 0/^/$
6. **Document Navigation** — gg/G, Ctrl-d/u, line numbers, paragraph nav
7. **Search** — /, ?, n, N, *, #
8. **Power Commands** — Ctrl-a/x, macros, %, dot command, J, case changes

## Scoring

| Tier   | Criteria |
|--------|----------|
| Gold   | Keystrokes <= optimal AND time <= optimal x 1.5 |
| Silver | Keystrokes <= optimal x 1.5 AND time <= optimal x 2.5 |
| Bronze | Challenge completed |

## License

MIT
# nvtutor
