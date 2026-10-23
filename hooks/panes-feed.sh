#!/bin/zsh
# Feeds the `panes` dashboard from Claude Code's status line JSON.
# Call it from your status line script with the JSON on stdin:
#   printf '%s' "$input" | ~/.claude/hooks/panes-feed.sh
# or use it as the whole status line (it prints nothing).
# Sets, on the panes tmux server:
#   @lim_raw  "5h% 5h-reset 7d% 7d-reset" (account limits, for the dashboard)
#   @limits   the same, formatted for the tmux status bar
#   @ctx      this session's context use, on its own pane

[[ $TMUX == */claude,* && -n $TMUX_PANE ]] || { cat >/dev/null; exit 0; }
local -a f
f=(${(f)"$(jq -r '.rate_limits.five_hour.used_percentage // "-", .rate_limits.five_hour.resets_at // "-",
  .rate_limits.seven_day.used_percentage // "-", .rate_limits.seven_day.resets_at // "-",
  .context_window.used_percentage // "-"' 2>/dev/null)"})
(( $#f == 5 )) || exit 0

[[ $f[1] != - || $f[3] != - ]] && tmux set -gq @lim_raw "$f[1] $f[2] $f[3] $f[4]"
[[ $f[5] != - ]] && tmux set -pq -t $TMUX_PANE @ctx "$f[5]"

# "5h 26% · 7d 41%" for the status bar, coloured by how close to the limit.
lim() {
  [[ $2 == - ]] && return
  local c=colour71 p=${2%.*}
  (( p >= 50 )) && c=colour178; (( p >= 80 )) && c=colour167
  print -rn -- "$1 #[fg=$c]${p}%%#[fg=colour246]"
}
local s5=$(lim 5h $f[1]) s7=$(lim 7d $f[3])
tmux set -gq @limits "${s5}${s5:+${s7:+ · }}${s7}"
