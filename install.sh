#!/usr/bin/env bash

cpulook_prefix=${PREFIX-}
if [[ ! $cpulook_prefix ]]; then
  if [[ ${XDG_DATA_HOME-} &&${XDG_DATA_HOME%/} == */share ]]; then
    cpulook_prefix=${XDG_DATA_HOME%/}
    cpulook_prefix=${cpulook_prefix%/share}
  elif [[ ${MWGDIR-} ]]; then
    cpulook_prefix=$MWGDIR
  elif [[ -d ~/.local ]]; then
    cpulook_prefix=~/.local
  elif [[ -d ~/.mwg ]]; then
    cpulook_prefix=~/.mwg
  else
    cpulook_prefix=~/.local
  fi
fi

CPUDIR=$cpulook_prefix/share/cpulook

function create-dir {
  if [[ ! -d $1 ]]; then
    echo "cpulook-install: creating directory '$1'"
    mkdir -p "$1"
  fi
}

function update {
  local src=$1
  local dst=${2:-$CPUDIR/$src}
  if [[ $src -nt $dst ]]; then
    echo "cpulook-install: updating '$dst'..."
    cp -p "$src" "$dst"
  fi

  # cpudir 算出を書き換える場合
  # sed '
  #   /^function cpudir\.initialize/i cpudir="$cpulook_prefix/share/cpulook"
  #   /^function cpudir\.initialize/,/^cpudir\.initialize/d
  # ' cputop
}

function update-script {
  update "$@"
}

#------------------------------------------------------------------------------
# <cpudir>/lib

create-dir "$CPUDIR/lib"
update lib/echox.bash "$CPUDIR/lib/echox.bash"

#------------------------------------------------------------------------------
# <cpudir>

if [[ ${CPUDIR%/} != ${PWD%/} ]]; then
  create-dir "$CPUDIR"

  # update m/
  create-dir "$CPUDIR/m"
  for d in m/*; do
    if [[ -d $d ]]; then
      cp -rfp "$d" "$CPUDIR/m/"
    fi
  done

  # update hosts/
  create-dir "$CPUDIR/hosts"
  update-script hosts/sh
  update-script hosts/ssh

  # create m/switch
  if [[ ! -e $CPUDIR/m/switch ]]; then
    if type bsub &>/dev/null; then
      ln -fs bsub "$CPUDIR/m/switch"
    else
      ln -fs rsh  "$CPUDIR/m/switch"
    fi
  fi

  # update scripts
  update cpulist-default.cfg
  update cpujobs.awk
  update-script cpugetdata.sh
  update-script cpugethost.sh
  update-script cpudefs.sh
  update-script cpukill
  update-script cpulast
  update-script cpulook
  update-script cpups
  update-script cpuseekd
  update-script cpusub
  update-script cputop

  # create configuration
  if [[ ! -s $CPUDIR/cpulist.cfg ]]; then
    echo "cpulook-install: creating default '$CPUDIR/cpulist.cfg'."
    cp -f "$CPUDIR/cpulist-default.cfg" "$CPUDIR/cpulist.cfg"
    local nproc=$(
      if type nproc &>/dev/null; then
        nproc 2>/dev/null
      elif [[ -f /proc/cpuinfo ]]; then
        grep -c ^processor /proc/cpuinfo
      else
        echo 1
      fi)
    ((nproc=nproc<=0?1:nproc))
    echo "${HOSTNAME##*.} $nproc $nproc 20 $nproc" >> "$CPUDIR/cpulist.cfg"
    echo "cpulook-install: [1mplease edit '$CPUDIR/cpulist.cfg'.[m"
  fi
fi

#------------------------------------------------------------------------------
# <cpulook_prefix>/bin

if [[ ! -d $cpulook_prefix/bin ]]; then
  create-dir "$cpulook_prefix/bin"
fi

# check PATH
if ! [[ $PATH =~ (^|:)"$cpulook_prefix/bin"/?(:|$) ]]; then
  echo "cpulook-install: [1mplease add '$cpulook_prefix/bin' to the environment variable PATH.[m"
fi

function install-bin {
  local file=$1
  local entity=$CPUDIR/$file
  local target=$cpulook_prefix/bin/$file
  if [[ ! -e $target ]]; then
    echo "cpulook-install: creating link '$target' -> '$entity'"
    ln -fs "$entity" "$target"
  fi
}
install-bin cpulook
install-bin cputop
install-bin cpups
install-bin cpulast
install-bin cpuseekd
install-bin cpusub
install-bin cpukill
#------------------------------------------------------------------------------
