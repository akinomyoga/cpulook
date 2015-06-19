#!/bin/bash

function cpudir.initialize {
  local _scr="$(test -h "$0" && { readlink -f "$0" || /bin/readlink -f "$0"; } || echo "$0")"
  local _dir="${_scr%/*}"
  test "x$_dir" = "x$_scr" && _dir=.
  test -z "$_dir" && _dir=/
  cpudir="$_dir"
}
cpudir.initialize

CPUDIR="$cpudir"
CPULST="$CPUDIR/cpulist.cfg"

declare key="$1"

declare r="$(awk '$0~/^[[:space:]]*#|^[[:space:]]*$/{next} $1=="'"$key"'"{print $1}' "$CPULST")"
declare c="$(echo "$r"|wc -l)"
if test -n "$r" -a "$c" -eq 1; then
  echo $r
  exit
elif test "$c" -gt 1; then
  echo "cpugethost.sh! ambiguous hostname $key" >/dev/stderr
  exit 1
fi

declare r="$(awk '$0~/^[[:space:]]*#|^[[:space:]]*$/{next} $1~/'"$key"'/{print $1}' "$CPULST")"
declare c="$(echo "$r"|wc -l)"
if test -n "$r" -a "$c" -eq 1; then
  echo cpugethost.sh: host=$r >/dev/stderr
  echo $r
  exit
elif test "$c" -gt 1; then
  echo "cpugethost.sh! ambiguous hostname $key" >/dev/stderr
  exit 1
fi

declare pattern="$(echo $key | sed 's/\b\|\B/.*/g')"
declare r="$(awk '$0~/^[[:space:]]*#|^[[:space:]]*$/{next} $1~/'"$pattern"'/{print $1}' "$CPULST")"
declare c="$(echo "$r"|wc -l)"
if test -n "$r" -a "$c" -eq 1; then
  echo cpugethost.sh: host=$r >/dev/stderr
  echo $r
  exit
fi

echo "cpugethost.sh! unknown hostname $key" >/dev/stderr
exit 1
