#!/usr/bin/env bash

shopt -s nullglob

cpulook_prefix=${PREFIX-}
if [[ ! $cpulook_prefix ]]; then
  if [[ ${XDG_DATA_HOME-} &&${XDG_DATA_HOME%/} == */share ]]; then
    cpulook_prefix=${XDG_DATA_HOME%/}
    cpulook_prefix=${cpulook_prefix%/share}
  else
    cpulook_prefix=~/.local
  fi
fi

cpudir=$cpulook_prefix/share/cpulook

function print { printf '%s\n' "${1-}"; }
function create-dir {
  if [[ ! -d $1 ]]; then
    print "cpulook/install: creating directory '$1'"
    mkdir -p "$1"
  fi
}

function install {
  local src=$1
  local dst=${2:-$cpudir/$src}
  if [[ $src -nt $dst ]]; then
    print "cpulook/install: updating '$dst'..."
    cp -p "$src" "$dst"
  fi
}

function install-script {
  local src=$1
  local dst=${2:-$cpudir/$src}
  if [[ $src -nt $dst ]]; then
    print "cpulook/install: updating '$dst'..."
    make/cmd.bash install-script "$src" "$dst" "$cpudir"
  fi
}

#------------------------------------------------------------------------------
# <cpudir>

function install-files {
  # <cpudir>/lib
  create-dir "$cpudir/lib"
  install        lib/echox.bash
  install        lib/cpudef.bash
  install        lib/cpujobs.awk
  install-script lib/cpugetdata.sh

  # <cpudir>/m
  create-dir "$cpudir/m"
  for f in m/*.bash; do
    install "$f"
  done
  create-dir "$cpudir/m/rsh"
  install-script m/rsh/rshexec.sh
  install-script m/rsh/rshkill.sh

  # <cpudir>/hosts
  create-dir "$cpudir/hosts"
  install hosts/sh
  install hosts/ssh

  # <cpudir>/m/switch: create if non-existent
  local switch=$cpudir/m/switch
  if [[ -d $switch || -L $switch && ! -e $switch ]]; then
    # This is the symbolic link for an old implementation of cpulook.  If the
    # corresponding file is found, we create a new symbolic link.  If not, we
    # remove the old symbolic link.
    local old=$(readlink "$switch")
    rm -f "$switch"
    [[ -s m/$old.bash ]] && ln -sf "$old.bash" "$switch"
  fi
  if [[ ! -e $switch ]]; then
    if type bsub &>/dev/null; then
      ln -fs bsub.bash "$switch"
    else
      ln -fs rsh.bash  "$switch"
    fi
  fi

  # update scripts
  install cpulist-default.cfg
  install-script cpukill
  install-script cpulast
  install-script cpulook
  install-script cpups
  install-script cpuseekd
  install-script cpusub
  install-script cputop

  # create configuration
  local config_cpulist=$cpudir/cpulist.cfg
  if [[ ! -s $config_cpulist ]]; then
    print "cpulook/install: creating default '$config_cpulist'."
    cp -f "$cpudir/cpulist-default.cfg" "$config_cpulist"
    local nproc=$(
      if type nproc &>/dev/null; then
        nproc 2>/dev/null
      elif [[ -f /proc/cpuinfo ]]; then
        grep -c ^processor /proc/cpuinfo
      else
        print 1
      fi)
    ((nproc=nproc<=0?1:nproc))
    print "${HOSTNAME##*.} $nproc $nproc 20 $nproc" >> "$config_cpulist"
    print "cpulook/install: [1mplease edit '$config_cpulist'.[m"
  fi
}

if [[ ${cpudir%/} != ${PWD%/} ]]; then
  install-files
fi

#------------------------------------------------------------------------------
# <cpulook_prefix>/bin

if [[ ! -d $cpulook_prefix/bin ]]; then
  create-dir "$cpulook_prefix/bin"
fi

# check PATH
if ! [[ $PATH =~ (^|:)"$cpulook_prefix/bin"/?(:|$) ]]; then
  print "cpulook/install: [1mplease add '$cpulook_prefix/bin' to the environment variable PATH.[m"
fi

function install-bin {
  local file=$1
  local entity=$cpudir/$file
  local target=$cpulook_prefix/bin/$file
  if [[ ! -e $target ]]; then
    print "cpulook/install: creating link '$target' -> '$entity'"
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
