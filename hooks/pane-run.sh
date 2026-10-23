#!/bin/zsh
# What each `panes` Claude pane runs:
#   - this project's Claude is running in the background (you /exit'ed its
#     tab while it worked, or started it with --bg) → attach to it here
#   - it's open in a Terminal tab → wait; take over when it leaves that tab
#   - otherwise → resume its last conversation with `claude -c`
#   - PANE_FRESH=1 (`panes` typed in the shell strip) → a new conversation
# When Claude exits (/exit), the pane closes. If it fails, a shell stays so
# you can read the error.

me=$(tty)

if [[ $PANE_FRESH == 1 ]]; then
  # PANE_ARGS: claude's arguments, already shell-quoted by `panes --new`.
  exec zsh -i -c "claude $PANE_ARGS || exec zsh -i"
fi

# where: "bg <id>" if this dir's Claude runs in the background, "tab <tty>"
# if it's open in another terminal, nothing if neither.
where() {
  command claude agents --json 2>/dev/null |
    jq -r --arg d $PWD '.[] | select(.cwd == $d) | "\(.kind) \(.id // "-") \(.pid)"' |
    while read kind id pid; do
      [[ $kind == background ]] && { print "bg $id"; return; }
      t=$(ps -o tty= -p $pid 2>/dev/null | tr -d ' ')
      [[ -n $t && /dev/$t != $me ]] && { print "tab $t"; return; }
    done
}

w=($(where))
if [[ $w[1] == tab ]]; then
  print "\e[2m${PWD/#$HOME/~} — waiting\e[0m\n"
  print "Still open in another tab. \e[1m/exit\e[0m it there and the"
  print "conversation moves here. Don't need it? \e[1m⌃b x\e[0m closes this pane."
  while w=($(where)); [[ $w[1] == tab ]]; do sleep 2; done
  clear
fi

if [[ $w[1] == bg ]]; then
  exec zsh -i -c "command claude attach $w[2] || exec zsh -i"
fi

# Interactive zsh so the claude() wrapper (tab emoji, recap card) applies.
# Resume only if this dir has a past conversation (Claude stores them under
# ~/.claude/projects/<cwd with / _ . turned into ->).
past=(~/.claude/projects/${PWD//[\/_.]/-}/*.jsonl(N[1]))
if (( $#past )); then
  exec zsh -i -c 'claude -c || exec zsh -i'
else
  # PANE_ARGS: claude's arguments, already shell-quoted by `panes --new`.
  exec zsh -i -c "claude $PANE_ARGS || exec zsh -i"
fi
