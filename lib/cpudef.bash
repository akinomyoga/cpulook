#!/usr/bin/env bash

cpulook_prog=${0##*/}
cpulook_cache=${XDG_CACHE_HOME:-$HOME/.cache}/cpulook
cpulook_cpulist=$cpudir/cpulist.cfg

cpulook_bash=$((BASH_VERSINFO[0] * 10000 + BASH_VERSINFO[1] * 100 + BASH_VERSINFO[2]))

function cpulook/put { printf '%s' "${1-}"; }
function cpulook/print { printf '%s\n' "${1-}"; }
function cpulook/string#match { [[ $1 =~ $2 ]]; }
if ((cpulook_bash >= 30200)); then
  function cpulook/is-function { declare -F "$1" &>/dev/null; }
else
  # Note: bash <= 3.1 has a bug that a function name with special characters
  # cannot be tested with declare -F.
  function cpulook/is-function { [[ $(type -t "$1" 2>/dev/null) == 'function' ]]; }
fi
if ((cpulook_bash >= 30100)); then
  function cpulook/array#push { builtin eval -- "$1"'+=("${@:2}")'; }
else
  function cpulook/array#push {
    local _script='ARR=("${ARR[@]}"); while (($#)); do ARR[${#ARR[@]}]=$1; shift; done'
    _script=${_script//ARR/$1}; shift
    builtin eval -- "$_script"
  }
fi

function cpulook/mkdir {
  local -a new=()
  local dir
  for dir; do
    [[ -d $dir ]] || cpulook/array#push new "$dir"
  done
  if ((${#new[@]})); then
    mkdir -p "${new[@]}"
  fi
}

function cpulook/view {
  if [[ -t 1 ]] && type -P less &>/dev/null; then
    less -FS
  else
    cat
  fi
}

cpulook_seeklog_file=$cpudir/cpuseekd.log
if ((cpulook_bash >= 40200)); then
  function cpulook/seeklog {
    local line
    printf -v line '[%(%F %T)T] %s' -1 "$1"
    cpulook/print "$line" >> "$cpulook_seeklog_file"
    cpulook/is-function echom && echom "$line"
  }
else
  function cpulook/seeklog {
    local line
    printf -v line '[%s] %s' "$(date +'%F %T')" "$1"
    cpulook/print "$line" >> "$cpulook_seeklog_file"
    cpulook/is-function echom && echom "$line"
  }
fi

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
