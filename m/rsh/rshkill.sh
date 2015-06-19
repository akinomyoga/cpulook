#!/bin/bash

rsh_kill(){
  local pid="$1"
  if ! ps -p "$pid" -o command 2>/dev/null | awk '/^COMMAND/{next}/\yrshexec.sh --sub -c /{t=1}END{if(!t)exit 1}' 2>/dev/null; then
    echo "rshkill.sh: the specified process id '$pid' is not a valid cpujob id." >&2
    return 1
  fi

  kill $(ps xfo pid,ppid | awk '
    /^PID/{next}
    {
      pid=$1;
      ppid=$2;
      if(pid=="'"$pid"'"){
        dict[pid]=1;
        print pid;
      }else if(dict[ppid]){
        dict[pid]=1;
        print pid;
      }
    }
  ')
}

while test $# -gt 0; do
  rsh_kill "$1"
  shift
done
