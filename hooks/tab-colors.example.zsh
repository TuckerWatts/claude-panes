# Project → emoji and alert sound, used by `panes` and tab-state.sh.
# Copy to ~/.claude/hooks/tab-colors.zsh and add your projects.

# tab_project <dir>: the $PANES_ROOT/<project> a path belongs to, else its basename.
tab_project() {
  local d=${1:-$PWD} root=${PANES_ROOT:-$HOME/code}
  if [[ $d == $root/* ]]; then print -r -- ${${d#$root/}%%/*}
  else print -r -- ${d:t}; fi
}

tab_emoji() {
  case $1 in
    api) print 🟢 ;;
    web) print 🔵 ;;
    *)   print 🟣 ;;
  esac
}

# tab_sound <project>: the /System/Library/Sounds name played when that
# project's Claude needs you, so you can tell which one by ear.
tab_sound() {
  case $1 in
    api) print Glass ;;
    web) print Submarine ;;
    *)   print Tink ;;
  esac
}
