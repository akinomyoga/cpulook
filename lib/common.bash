#!/usr/bin/env bash

cpulook_cache=${XDG_CACHE_HOME:-$HOME/.cache}/cpulook

function cpulook/print { printf '%s\n' "${1-}"; }
function cpulook/string#match { [[ $1 =~ $2 ]]; }
function cpulook/view {
  if [[ -t 1 ]] && type -P less &>/dev/null; then
    less -FS
  else
    cat
  fi
}

function rsh.dispatch {
  local host=$1; shift
  local command="$*"

  local handler=$cpudir/hosts/$host.sh
  if [[ -s $handler ]]; then
    source "$handler" rsh "bash" <<< "$command" && return
  fi

  case $host in
  (localhost|127.0.0.1|::1|"${HOSTNAME%%.*}")
    handler=$cpudir/hosts/sh
    source "$handler" rsh "bash" <<< "$command" && return
  esac

  rsh "$host" "cd $cpudir; bash" <<< "$command"
}
