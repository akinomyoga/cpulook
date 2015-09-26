#!/bin/bash

function rsh.dispatch {
  local host="$1"; shift
  local command="$*"

  local handler="$cpudir/hosts/$host.sh"
  if [[ -s $handler ]]; then
    source "$handler" rsh "bash" <<< "$command" && return
  fi

  rsh "$host" "cd $cpudir; bash" <<< "$command"
}
