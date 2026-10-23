#!/bin/zsh
# Live Claude status for `panes` pane headers and Terminal.app tab titles.
# Called from hooks in ~/.claude/settings.json with one arg:
#   working | waiting | done | end
# Title becomes "<project emoji><state glyph> <project>", e.g. "🟢🔔 api".
# Also records state in ~/.claude/tab-state/<tty>.

setopt extendedglob
state=$1
input=$(cat)
source ~/.claude/hooks/tab-colors.zsh

# Hooks have no controlling tty; walk up to the claude process that does.
pid=$$ tty=
while [[ $pid -gt 1 ]]; do
  tty=$(ps -o tty= -p $pid | tr -d ' ')
  [[ -n $tty && $tty != '??' ]] && break
  pid=$(ps -o ppid= -p $pid | tr -d ' ')
done
[[ -n $tty && $tty != '??' ]] || exit 0

# Session start dir from the hook JSON, so already-running sessions (which
# never got CLAUDE_TAB_* from claude()) still get their colour.
cwd=$(print -r -- $input | jq -r '.cwd // empty' 2>/dev/null)
proj=${CLAUDE_TAB_PROJ:-$(tab_project ${cwd:-$PWD})}
emoji=$(tab_emoji $proj)
# Session name (e.g. "api-f3", or whatever /rename set), so two sessions
# in one project get different titles. Found by session id in
# ~/.claude/sessions/<pid>.json.
label=$proj
sid=$(print -r -- $input | jq -r '.session_id // empty' 2>/dev/null)
if [[ -n $sid ]]; then
  name=$(jq -r --arg s $sid 'select(.sessionId==$s) | .name // empty' ~/.claude/sessions/*.json 2>/dev/null | head -1)
  if [[ -n $name ]]; then
    [[ $name == ${proj}* ]] && label=$name || label="$proj · $name"
  fi
fi
dir=~/.claude/tab-state
mkdir -p $dir

case $state in
  working) glyph=⏳ ;;
  waiting) glyph=🔔 ;;
  done)    glyph=✅ ;;
  end)
    rm -f $dir/$tty
    # A `panes` Claude pane closes when its session ends, even one whose
    # Claude was started from a shell that would otherwise stay behind.
    # Not on /clear or /resume (same pane, new session). Watched from the
    # tmux server, since this hook dies with Claude: once the pane is back
    # at a shell prompt, close it. (## because run-shell expands formats.)
    reason=$(print -r -- $input | jq -r '.reason // empty' 2>/dev/null)
    if [[ $TMUX == */claude,* && -n $TMUX_PANE && $reason != (clear|resume) &&
          -n $(tmux display -p -t $TMUX_PANE '#{@dir}' 2>/dev/null) ]]; then
      tmux run-shell -b "i=0; while [ \$i -lt 120 ]; do
        c=\$(tmux display -p -t $TMUX_PANE '##{pane_current_command}' 2>/dev/null) || exit 0
        case \$c in zsh|bash|sh|-zsh) tmux kill-pane -t $TMUX_PANE; exit 0 ;; esac
        i=\$((i + 1)); sleep 0.5
      done"
    fi
    exit 0 ;;
  *)       exit 0 ;;
esac

# What this session is about, for the pane header (two sessions in one
# project need more than the project name): your /rename title, else
# Claude's auto title — unless it's a generic "where did we leave off" —
# else your latest prompt. Plus the effort level of the last API request.
tp=$(print -r -- $input | jq -r '.transcript_path // empty' 2>/dev/null)
topic= effort=
if [[ -f $tp ]]; then
  topic=$(grep '"type":"custom-title"' $tp | tail -1 | jq -r '.customTitle // empty' 2>/dev/null)
  if [[ -z $topic ]]; then
    topic=$(grep '"type":"ai-title"' $tp | tail -1 | jq -r '.aiTitle // empty' 2>/dev/null)
    [[ -z $topic || $topic == (#i)*(where did we|where are we|left off)* ]] &&
      topic=$(grep '"type":"last-prompt"' $tp | tail -1 | jq -r '.lastPrompt // empty' 2>/dev/null)
  fi
  topic=${topic//$'\n'/ }
  effort=$(grep '"type":"api-request"' $tp | tail -1 | grep -o '"effort":"[a-z]*"' | tail -1 | cut -d'"' -f4)
fi

# paint <tmux cmd> <pane>: the pane header (format in ~/.claude/panes.tmux.conf)
# reads these pane options; the title is just "<emoji> <label>".
paint() {
  ${=1} set -p -t $2 @state $state \; set -p -t $2 @topic "$topic" \; \
    set -p -t $2 @effort "$effort" \; set -p -t $2 @tp "$tp" \; select-pane -t $2 -T "${emoji} ${label}" 2>/dev/null
}

prev=
[[ -f $dir/$tty ]] && read prev _ < $dir/$tty

# PostToolUse fires on every tool call; nothing to do if already working.
[[ $state == working && $prev == working ]] && exit 0

# The ~60s-idle reminder after a finished turn isn't a new ask — stay ✅.
if [[ $state == waiting && $prev == done ]] &&
   [[ $(print -r -- $input | jq -r '.notification_type // empty' 2>/dev/null) == idle_prompt ]]; then
  exit 0
fi

# In a `panes` pane, set its title bar directly (panes ignores OSC titles so
# shells can't clobber it); else the Terminal tab's title.
if [[ -n $TMUX && -n $TMUX_PANE ]]; then
  paint tmux $TMUX_PANE
else
  print -n "\e]1;${emoji}${glyph} ${proj}\a" > /dev/$tty
  # A background session (the daemon's "claude bg-spare", found as $pid
  # above) attached in a `panes` pane runs outside tmux: find its pane by
  # directory instead. Only for those — a normal tab that happens to share
  # a directory with a pane must not retitle it.
  if ps -o args= -p $pid 2>/dev/null | grep -q -e '--bg-spare'; then
    pane=$(tmux -L claude list-panes -s -t panes -F '#{@dir} #{pane_id}' 2>/dev/null |
      awk -v d="${cwd:-$PWD}" '$1==d{print $2; exit}')
    [[ -n $pane ]] && paint "tmux -L claude" $pane
  fi
fi
print "$state $(date +%s) $proj" > $dir/$tty

# Per-project chime when a tab starts needing you — unless you're already
# looking at it. `touch ~/.claude/tab-sounds-off` to mute.
if [[ $state != working && $state != $prev && ! -e ~/.claude/tab-sounds-off ]]; then
  front=$(osascript -e 'tell application "System Events" to set f to name of first process whose frontmost is true' \
    -e 'if f is "Terminal" then tell application "Terminal" to return tty of selected tab of front window' 2>/dev/null)
  looking=0
  if [[ -n $TMUX && -n $TMUX_PANE ]]; then
    # In panes: you're looking if Terminal's front tab holds the tmux client
    # and this is the focused pane.
    [[ $front == $(tmux display -p '#{client_tty}' 2>/dev/null) &&
       $(tmux display -p -t $TMUX_PANE '#{&&:#{pane_active},#{window_active}}' 2>/dev/null) == 1 ]] && looking=1
  else
    [[ $front == /dev/$tty ]] && looking=1
  fi
  if (( ! looking )); then
    vol=1; [[ $state == done ]] && vol=0.4   # a question/permission ask is louder than "finished"
    afplay -v $vol /System/Library/Sounds/$(tab_sound $proj).aiff &!
  fi
fi
exit 0
