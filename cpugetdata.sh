#!/usr/bin/env bash

function cpulook/initialize-cpudir {
  unset -f "$FUNCNAME"

  local script=$0
  if [[ -h $script ]]; then
    local path=$(realpath "$0" || readlink -f "$0" || /bin/readlink -f "$script") 2>/dev/null
    [[ $path ]] && script=$path
  fi

  local script_dir=${script%/*}
  [[ $script_dir == "$script" ]] && script_dir=.
  if [[ -d ${script_dir:=/} ]]; then
    cpudir=$script_dir
  elif local dir=${XDG_DATA_HOME:-$HOME/.local/share}/cpulook; [[ -d $dir ]]; then
    cpudir=$dir
  else
    cpudir=$script_dir
  fi

  if [[ ! -f $cpudir/cpudefs.sh ]]; then
    printf '%s\n' "$0: failed to detect the cpulook directory." >&2
    exit 2
  elif [[ ! -r $cpudir/cpudefs.sh ]]; then
    printf '%s\n' "$0: permission denied for the cpulook directory." >&2
    exit 2
  fi
}
cpulook/initialize-cpudir
##----CPULOOK_COMMON_HEADER_END----

tmpdir=$HOME/.local/share/cpulook/tmp
[[ -d $tmpdir ]] || mkdir -p "$tmpdir"


arg_cascade=
function cpugetdata.read-options {
  while (($#)); do
    local arg=$1; shift
    case "$arg" in
    (--cascade=*)
      arg_cascade=${arg#*=} ;;
    esac
  done
}
cpugetdata.read-options "$@"

SUBTYPE=$cpudir/m/switch

if [[ $arg_cascade ]]; then
  "$cpudir/cpulook" 3 --cpugetdata --host-pattern="$arg_cascade"
  exit 0
elif [[ ! $1 ]]; then
  exit 0
fi

host=$1

# cpuinfo
#   read cpulist.cfg
function cpuinfo.load {
  if (($#>=5)); then
    cpuinfo=("$@")
    return
  fi

  local cpuline=$(awk '$1 == "'"$host"'"' "$cpudir/cpulist.cfg" 2>/dev/null)
  if [[ $cpuline ]]; then
    cpuinfo=($cpuline)
    return
  fi

  local ncor=$(grep -c processor /proc/cpuinfo)
  cpuinfo=("$host" "$ncor" "$ncor" 20 "$ncor")
  echo "${cpuinfo[*]}" >> "$cpudir/cpulist.cfg"
}

cpuinfo.load "$@"
ncor=${cpuinfo[1]}
gmax=${cpuinfo[2]}
nice=${cpuinfo[3]}
umax=${cpuinfo[4]}
[[ $ncor ]] || ncor=0
[[ $gmax ]] || gmax=0
[[ $nice ]] || nice=0
[[ $umax ]] || umax=$gmax

# status
util=$(top -b -n 1 | awk '/^ *[[:digit:]]/{a+=$9;}END{print a;}')
load=$(awk '{print int($1*100);exit}' /proc/loadavg)
source "$SUBTYPE/get_used.src"

# getline
echo ==cpulook.stat==
echo "$host:$ncor:$gmax:$umax:$nice:$util:$load:$guse:$uuse"| gawk -F':' \
  -v upend="${upend:-0}" \
  -v gpend="${gpend:-0}" '
  function min(a,b){return a<b?a:b;}
  function max(a,b){return a>b?a:b;}
  function ceil(a, _t){
    if(a<=0){
      return int(a);
    }else{
      _t=int(1+a);
      return int(a-_t)+_t;
    }
  }

  BEGIN{
    WIDTH=64;
  }

  {
    name=$1;
    ncor=$2;
    gmax=$3;
    umax=$4;
    nice=$5;if(nice=="")nice=0;
    util=$6*0.01;
    load=$7*0.01;
    guse=$8;
    uuse=$9;

    idle=int(gmax - ceil(max(max(util,load),uuse)-0.1));
    idle=min(idle,umax-uuse);
    idle=min(idle,gmax-guse);
    if(idle<0)idle=0;
    if(int((load+util)*0.5)<uuse-1)idle=0; # 20111123
    if(upend>=1)idle=0; # 20141017
    #idle=max(idle-gpend,0); # 20141030 -m で投げている人がいると詰まる。

    w=(util+load)*0.5;

    printf("%-12s %2d %2d %2d : %6.1f %6.1f %2d %s\n",name,gmax,idle,nice,util*100,load*100,uuse,ncor);
  }
'

exit 0
