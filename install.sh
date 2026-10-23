#!/bin/zsh
# Installs panes into ~/.local/bin and ~/.claude. Safe to re-run: it never
# overwrites your tab-colors.zsh, and it doesn't touch settings.json (merge
# settings.example.json into it yourself).
set -e
cd ${0:A:h}
for c in tmux jq; do command -v $c >/dev/null || { print "panes needs $c (brew install $c)"; exit 1; }; done

mkdir -p ~/.local/bin ~/.claude/hooks ~/.claude/panes-shell
install -m 755 bin/panes ~/.local/bin/panes
install -m 755 hooks/pane-run.sh hooks/tab-state.sh hooks/panes-feed.sh ~/.claude/hooks/
install -m 644 tmux/panes.tmux.conf panes-guide.txt ~/.claude/
install -m 644 shell/zshrc ~/.claude/panes-shell/.zshrc
[[ -e ~/.claude/hooks/tab-colors.zsh ]] || install -m 644 hooks/tab-colors.example.zsh ~/.claude/hooks/tab-colors.zsh

print "Installed. Next:"
print "  1. Merge settings.example.json into ~/.claude/settings.json (hooks + status line)."
print "  2. Make sure ~/.local/bin is on your PATH."
print "  3. Run: panes"
