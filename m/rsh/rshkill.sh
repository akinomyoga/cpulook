#!/usr/bin/env bash

function rsh_kill {
  local pid=$1
  if ! ps -p "$pid" -o command 2>/dev/null | awk '/^COMMAND/ { next; } /\yrshexec.sh --sub -c / { t = 1; } END { if (!t) exit 1; }' 2>/dev/null; then
    printf '%s\n' "rshkill.sh: the specified process id '$pid' is not a valid cpujob id." >&2
    return 1
  fi

  # XXX---This assumes the support for "ps f" to sort the processes so that the
  # parent processes come first.
  kill $(ps xfo pid,ppid | awk -v pid="$pid" '
    /^PID/ { next; }
    {
      proc_pid = $1;
      proc_ppid = $2;
      if (proc_pid == pid) {
        dict[proc_pid] = 1;
        print proc_pid;
      } else if (dict[proc_ppid]) {
        dict[proc_pid] = 1;
        print proc_pid;
      }
    }
  ')
}

for pid; do
  rsh_kill "$pid"
done
