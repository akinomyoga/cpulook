# -*- mode: sh; mode: sh-bash -*-

# This implements an adapter to the "bsub" command.  This was tested with
# OpenLava.

cpulook_system=bsub

## @fn cpulook/system:bsub/submit host cmd
##   @param[in] host
##   @param[in] cmd
function cpulook/system:bsub/submit {
  local host=$1 cmd=$2
  local title=$(
    sed '
      s#^\. ~/\.bashrc \{0,1\}; \{0,1\}cd [^;[:space:]]\{1,\} \{0,1\}; \{0,1\}##
      s# \{0,1\}[&[:digit:]]\{0,1\}>[^>&;|]\+$##
    ' <<< "$cmd"
  )
  cpulook/seeklog "host: $host  title: $title"
  cpulook/seeklog "bsub -e /dev/null -o /dev/null -m \"$host\" -J \"$title\" \"$cmd\""
  bsub -e /dev/null -o /dev/null -m "$host" -J "$title" "$cmd"
}

function cpulook/system:bsub/kill {
  bkill "$@"
}

#------------------------------------------------------------------------------
# get-used
#
# requirement:
#   set shell variables `uuse' and `guse'

#
# ChangeLog
#
# 2025-08-10, Koichi Murase <myoga.murase@gmail.com>
#   * refactor the implementation
#   * do not leak variables
#   * do not leave the redirection 5>&1
# 2013-05-06, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#   * change to output results to standard output
# 2013-05-06, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#   * add a call of cpujobs.awk to generate jobslist
# 2013-05-06, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#   * re-implement using the bjobs command in localhost
# 2013-05-04, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#   * change the variable name `used' to `uuse'
#   * add the support for the variable `guse'
# 2013-04-24, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#   * change to count the command `sbatchd' as well as the `.lsbatch/*'
# 2013-03-15, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#   * change implementation to use the `ps' commnad because the `bsub' command
#     seems not necessarily available in the all hosts.
# 2012-04-24, Koichi Murase <murase@nt.phys.s.u-tokyo.ac.jp>
#   * implementation using the `bjobs' command
#

: ${cpudir?'$cpudir is not set. It should be set in lib/cpugetdata.sh.'}
: ${cpulook_cache:?'$cpulook_cache is empty. It should be set in lib/cpugetdata.sh.'}

function cpulook/system:bsub/get-used/.local-bjobs {
  local fdat=$cpulook_cache/bsub.used.dat
  local -a result
  result=(
    $(
      local -x user=$USER host=$host
      awk '
        BEGIN {
          c_user = ENVIRON["user"];
          c_host = ENVIRON["host"];
          uuse = guse = 0;
          upend = gpend = 0;
        }
        $2 == c_host {
          if ($1 == c_user) uuse++;
          guse++;
        }
        $2 == "PEND" {
          if ($1 == c_user) upend++;
          gpend++;
        }
        END {
          print uuse, guse, upend, gpend
        }
      ' "$fdat"
    )
  )
  uuse=${result[0]}
  guse=${result[1]}
  upend=${result[2]}
  gpend=${result[3]}

  # cpulook/print "user=$USER host=$host uuse=$uuse guse=$guse" >"$cpulook_cache/bsub.$host.used"
}

## @fn cpulook/system:bsub/get-used host
##   @param[in,opt] host
##   @var[out] uuse guse upend gpend
function cpulook/system:bsub/get-used {
  local host=${1:-${HOSTNAME%%.*}}

  cpulook/system:bsub/get-used/.local-bjobs # -> uuse guse upend gpend

  cpulook/print '==cpulook.jobs=='
  ps uaxf | type="lava.used" host="$host" fjobs=/dev/fd/5 "$cpudir/lib/cpujobs.awk" 5>&1 1>/dev/null

  # # v20130504
  # uuse=$(ps ux | grep -E '/bin/sh '"$HOME"'/\.lsbatch/[[:digit:]]|/usr/share/lava/.+/sbatchd$' | awk '$1=="'"$USER"'"' | wc -l)
  # # get_guse
  # local fdat=$cpulook_cache/used@local.dat
  # if [[ -s $fdat ]]; then
  #   guse=$(awk '$2=="'"$host"'"{print $1;}' "$fdat")
  # else
  #   guse=$uuse
  # fi

  # # v20130311
  # used=$(ps ux | grep "$HOME/\.lsbatch/[[:digit:]]" | awk '$0~/\/bin\/sh \/home\/'"$USER"'\/\.[l]sbatch\/[[:digit:]]/&&$1=="'"$USER"'"' | wc -l)

  # # v20120424
  # used=$(($(bjobs -m $HOSTNAME 2>&1  | wc -l) - 1))
}

#------------------------------------------------------------------------------
# get-used-local

## @fn cpulook/system:bsub/get-used-local
##   @file[out] $cpulook_cache/bsub.used.dat
function cpulook/system:bsub/get-used-local {
  local ftmp=$cpulook_cache/bsub.used.part
  local fdat=$cpulook_cache/bsub.used.dat

  bjobs -u all 2>/dev/null | awk '
    BEGIN {
      beg = -1;
    }
    /EXEC_HOST/ {
      beg = index($0, "EXEC_HOST");
      next;
    }
    {
      user = $2;
      if ($3 == "RUN") {
        if (beg < 0) next;
        host = substr($0, beg);
        sub(/[\. ].*$/, "", host);
        if (host != "")
          print user, host;
      } else if ($3 == "PEND") {
        print user, "PEND";
      }
    }
  ' > "$ftmp"

  #[[ -s $ftmp ]] && mv "$ftmp" "$fdat"
  mv "$ftmp" "$fdat"
}
