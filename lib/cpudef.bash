#!/usr/bin/env bash

cpulook_prog=${0##*/}
cpulook_cache=${XDG_CACHE_HOME:-$HOME/.cache}/cpulook
cpulook_cpulist=$cpudir/cpulist.cfg

function cpulook/put { printf '%s' "${1-}"; }
function cpulook/print { printf '%s\n' "${1-}"; }
function cpulook/string#match { [[ $1 =~ $2 ]]; }
function cpulook/view {
  if [[ -t 1 ]] && type -P less &>/dev/null; then
    less -FS
  else
    cat
  fi
}

## @fn cpulook/parse-host key
##   @var[out] host
##   @exit
function cpulook/parse-host {
  host=
  local key=$1

  local r=$(awk -v key="$key" '$0 ~ /^[[:space:]]*#|^[[:space:]]*$/ { next; } $1 == key { print $1; }' "$cpulook_cpulist")
  local c=$(wc -l <<< "$r")
  if [[ $r ]]; then
    if [[ $r == *$'\n'* ]]; then
      cpulook/print "$cpulook_prog! ambiguous hostname '$key'" >&2
      return 1
    fi

    host=$r
    return 0
  fi

  local r=$(awk -v key="$key" '$0 ~ /^[[:space:]]*#|^[[:space:]]*$/ { next; } $1 ~ key { print $1; }' "$cpulook_cpulist" 2>/dev/null)
  if [[ $r ]]; then
    if [[ $r == *$'\n'* ]]; then
      cpulook/print "$cpulook_prog! ambiguous hostname '$key'" >&2
      return 1
    fi

    cpulook/print "$cpulook_prog: host=$r" >&2
    host=$r
    return 0
  fi

  local pattern=$(sed -E 's/\b|\B/.*/g' <<< "$key")
  local r=$(awk -v pattern="$pattern" '$0 ~ /^[[:space:]]*#|^[[:space:]]*$/ { next; } $1 ~ pattern { print $1; }' "$cpulook_cpulist" 2>/dev/null)
  if [[ $r && $r != *$'\n'* ]]; then
    cpulook/print "$cpulook_prog: host=$r" >&2
    host=$r
    return 0
  fi

  cpulook/print "$cpulook_prog! unknown hostname: '$key'" >&2
  return 1
}

## @fn rsh.dispatch host command
function rsh.dispatch {
  local host=$1 command=$2

  local handler=$cpudir/hosts/$host.sh
  if [[ -s $handler ]]; then
    source "$handler" rsh "bash" <<< "$command" && return
  fi

  case $host in
  (localhost|127.0.0.1|::1|"${HOSTNAME%%.*}")
    handler=$cpudir/hosts/sh
    source "$handler" rsh "bash" <<< "$command" && return
  esac

  rsh "$host" "cd '${cpudir:-/}'; bash" <<< "$command"
}
