# claude-panes

All your [Claude Code](https://claude.com/claude-code) sessions in one terminal window, built on tmux.

```
┌──────────────────────────────────────────┬───────────────────────────┐
│ 🟢 api-cb  ● working · high · Fix auth…   │ ◆ focus                    │
│                                          │ 🟢 api-cb  ctx 34%          │
│   the session you're typing in           │ ✻ Churning… (2m 31s)        │
│                                          │                            │
│                                          │ ACTIVITY  27 calls · 30m   │
│                                          │       ▂▃▇▅▁  ▃▇▂▃▄▇         │
│                                          │ TRAIL                      │
│                                          │ ✎ src/auth.ts          1m  │
│                                          │ ❯ npm test             2m  │
│                                          │ FILES CHANGED  3           │
│                                          │ GIT  main ↑1 · PR #42 ✓    │
├──────────────────────┬───────────────────┴───────────────────────────┤
│ ⌨️  shell             │ 1 🟢 api-cb    ● working   high · Fix auth…   │
│ ~/code/api ❯         │ 2 🔵 web-a1    ● needs you medium · Pricing…  │
└──────────────────────┴───────────────────────────────────────────────┘
```

- **Big pane (left)**: the one session you type in.
- **Focus column (right)**: what that session is doing right now: its spinner line, a sparkline of tool calls per minute, the trail of recent edits/commands/searches, the files it has changed, git status, and the branch's PR and checks.
- **Session list (bottom right)**: every session with a status dot (● needs you / working / done), its effort level, and what it's about. Click a row, or press its number, to swap that session into the big pane. The others keep running in hidden tmux windows.
- **Shell (bottom left)**: a plain shell. Typing `claude` here opens a new session in the big pane instead of taking over the shell.
- `/exit` in a session closes its pane.

## Requirements

macOS, zsh, [tmux](https://github.com/tmux/tmux) 3.2+, [jq](https://jqlang.github.io/jq/), Claude Code. [gh](https://cli.github.com/) is optional (for the PR line).

## Install

```sh
git clone https://github.com/TuckerWatts/claude-panes
cd claude-panes && ./install.sh
```

Then merge `settings.example.json` into `~/.claude/settings.json`. The hooks keep each pane's status, effort and topic up to date. The status line entry feeds context use to the focus column. If you already have a status line, pipe its JSON input into `~/.claude/hooks/panes-feed.sh` from your own script.

Projects are looked up under `~/code` by default; set `PANES_ROOT` to change it. Copy your projects into `~/.claude/hooks/tab-colors.zsh` to give each one an emoji and an alert sound.

## Use

```
panes                    open your 4 most recent projects
panes api web            open (or jump to) these projects
panes -k                 close everything (conversations are kept)

in the bottom shell:
  claude [args]          new session in the big pane
  panes / panes .        same, in the shell's directory

⌃b p   pick a project    ⌃b x   close a pane    ⌃b ?   guide
```

Each project pane runs `claude -c`, which resumes that project's last conversation. If the project is already open in another terminal tab, the pane waits and takes over when you `/exit` it there.

## Files

| File | Installs to | What it does |
|---|---|---|
| `bin/panes` | `~/.local/bin/` | Layout, session list, focus column |
| `hooks/pane-run.sh` | `~/.claude/hooks/` | What each Claude pane runs |
| `hooks/tab-state.sh` | `~/.claude/hooks/` | Hook: status, effort, topic → pane header |
| `hooks/panes-feed.sh` | `~/.claude/hooks/` | Status line: context and usage → tmux |
| `hooks/tab-colors.example.zsh` | `~/.claude/hooks/tab-colors.zsh` | Project emoji and sounds |
| `tmux/panes.tmux.conf` | `~/.claude/` | tmux config, on its own socket (`tmux -L claude`) |
| `shell/zshrc` | `~/.claude/panes-shell/.zshrc` | Bottom shell: compact prompt and `claude` wrapper |

panes runs on its own tmux socket and config, so it doesn't touch any other tmux you use.

## License

MIT
