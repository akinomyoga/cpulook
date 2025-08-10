# -*- mode: sh; mode: sh-bash -*-

cpulook_system=rsh

#------------------------------------------------------------------------------
# submit

# 2012-04-24 version
function cpulook/system:rsh/submit/impl1 {
  local host=$1 cmd=$2
  if ((nice != 0)); then
    cmd='renice '$nice' "$$" &>/dev/null ; '$cmd
  fi
  cpulook/seeklog "host: $host"
  cpulook/seeklog "rsh $host $cmd &"
  rsh "$host" "$cmd" &
  cpulook/seeklog "disown"
  disown
}

# 2013/05/05 version
function cpulook/system:rsh/submit/impl5 {
  local host=$1 cmd=$2
  local fcmd=$cpudir/rshexec.$$.$(md5sum <<< "$cmd" | awk '{printf("%s",$1)}')
  cpulook/put "$cmd" > "$fcmd"
  if [[ ! -s $fcmd ]]; then
    cpulook/seeklog "rsh/submit/impl5: ERROR! failed to create a command file '$fcmd'!"
    return 1
  fi
  rsh "$host" "$cpudir/m/rsh/rshexec.sh -n$nice -f$fcmd"
  rm -rf "$fcmd"
}

# 2013/05/05 version2
function cpulook/system:rsh/.get-free-filename {
  local name=$1
  local ext=$2
  [[ $ext && $ext != .* ]] && ext=".$ext"

  local cand=$name$ext
  while [[ -e $cand ]]; do
    name=$name+
    cand=$name$ext
  done
  cpulook/print "$cand"
}

function cpulook/system:rsh/submit/impl6 {
  local host=$1 cmd=$2
  (
    id=${BASHPID:-$$.$RANDOM}

    # register command
    ftmp=$(cpulook/system:rsh/.get-free-filename "$cpulook_cache/rshsub.$host.$id" .tmp)
    fcmd=$(cpulook/system:rsh/.get-free-filename "$cpulook_cache/rshsub.$host.$id" .cmd)
    cpulook/print "$cmd" > "$ftmp"
    mv "$ftmp" "$fcmd"

    # try to get the right to execute rsh
    fown=$cpulook_cache/rshsub.$host.own
    cpulook/put "$id" > "$fown"
    sleep 5
    [[ $(< "$fown") != "$id" ]] && exit

    # collect registered commands
    dcmd=$(cpulook/system:rsh/.get-free-filename "$cpulook_cache/rshsub.$id")
    cpulook/mkdir "$dcmd"
    mv "$cpulook_cache/rshsub.$host".*.cmd "$dcmd/"

    # execute rsh
    rsh "$host" "$cpudir/m/rsh/rshexec.sh -n$nice -d$dcmd"
    rm -rf "$dcmd"
  ) &

  cpulook/seeklog "rsh/submit/impl6: host=$host cmd=($cmd) -> rshexec.sh"
}

## @fn cpulook/system:rsh/submit host cmd
##   @param[in] host
##     The hostname where the command is expected to be run.
##   @param[in] cmd
##     The command to run.
##   @var[in] nice
##     nice value
function cpulook/system:rsh/submit {
  cpulook/system:rsh/submit/impl6 "$@"
}

#------------------------------------------------------------------------------
# kill
#
# @import lib/echox.bash

function cpulook/system:rsh/kill.1 {
  if ! cpulook/string#match "$1" '^([^:]+):([0-9]+)$'; then
    echoe "the specified cpujob id '$1' is ill-formed."
    return 2
  fi
  local host=${BASH_REMATCH[1]} pid=${BASH_REMATCH[2]}

  local nice=0
  local cmd="$cpudir/m/rsh/rshkill.sh $pid"
  cpulook/system:rsh/submit "$host" "$cmd"
}

function cpulook/system:rsh/kill {
  if (($# == 0)); then
    echom "usage: cpukill HOST:PID"
    return
  fi

  local cpujob ext=0
  for cpujob; do
    cpulook/system:rsh/kill.1 "$cpujob" || ext=$?
  done
  return "$ext"
}

#------------------------------------------------------------------------------
# get-used

## @fn cpulook/system:SYSTEM/get-used host
##   This function should set the following shell variables to appropriate
##   values:
##
##   @var[out] uuse
##     the number of cores used by the user,
##   @var[out] guse
##     the number of cores used by the all user.
##
##   One may optionally set the following variables.
##
##   @var[out] upend
##   @var[out] gpend
##
##   The simplest implementation of cpulook/system:SYSTEM/get-used host may be
##   the following:
##
##     function cpulook/system:simple/get-used {
##       uuse=$(ps ux | awk '$0 ~ /\ybash -c/ && $1 == "'"$USER"'"' | wc -l)
##       guse=$(ps ux | awk '$0 ~ /\ybash -c/ | wc -l)
##     }
##

#
# ChangeLog
#
#   2025-08-10, Koichi Murase <myoga.murase@gmail.com>
#     * refactor the implementation
#     * do not leak variables
#   2013-05-18, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#     * change to use cpujobs.awk to get data `uuse' and `guse'.
#   2013-05-05, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#     * add a function to create the jobs list
#   2013-05-04, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#     * change the variable name `used' to `uuse'
#     * add the support for the variable `guse'
#   2012-04-24, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#     * separate the code out of `lib/cpugetdata.sh' into a new file
#

: ${cpudir?'$cpudir is not set. It should be set in lib/cpugetdata.sh.'}
: ${cpulook_cache:?'$cpulook_cache is empty. It should be set in lib/cpugetdata.sh.'}

## @fn cpulook/system:rsh/get-used host
##   @param[in,opt] host
##   @var[out] uuse guse
function cpulook/system:rsh/get-used {
  local host=${1:-${HOSTNAME%%.*}}

  local fjobs=$cpulook_cache/$host.jobs result
  result=($(ps uaxf | type="rsh.used" host="$host" fjobs="$fjobs" "$cpudir/lib/cpujobs.awk"))

  uuse=${result[0]:-0}
  guse=${result[1]:-0}
}
