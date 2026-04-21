# Open Questions

## NVTutor Implementation - 2026-04-21

- [ ] Should `vim.on_key()` count Escape key presses as keystrokes? Pressing Escape to exit insert mode is part of the command (e.g., `i` + typing + `<Esc>` for insert challenges) but may feel unfair if counted. -- Affects scoring fairness for insert/change commands in Ch4.

- [ ] For visual mode challenges, should the user be required to yank/delete after selecting, or is the selection itself the success condition? -- Determines whether visual challenges are "select only" or "select and act." The spec says "select matching region" which implies selection alone.

- [ ] How should the review round handle commands the user has never attempted (skipped lessons within an unlocked chapter)? -- Within an unlocked chapter, lessons are freely accessible but not mandatory. Should review only include attempted commands, or should it include all commands from completed chapters?

- [ ] For macro challenges (Ch8), what exactly counts as "optimal keystrokes"? Recording the macro counts keystrokes, but the efficiency gain is in replay. -- Need to define whether optimal = record + one replay, or record + N replays for N target lines.

- [ ] Should `:NVTutor reset` require confirmation (e.g., "Type YES to confirm")? -- Accidental reset would lose all progress. The spec lists the subcommand but doesn't specify confirmation UX.

- [ ] What buffer content should the practice area show between challenges (while feedback is displayed)? -- Keep the completed challenge buffer visible, show a blank buffer, or show a transition screen?

- [ ] Should the plugin support `vim.g.nvtutor_data_dir` as an override for the progress file location? -- Power users or Neovim distributions may want a custom path. The spec says `~/.local/share/nvim/tutor/` but doesn't mention overrides. Since there is no `setup()`, a global variable would be the mechanism.
