#!/bin/bash

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
