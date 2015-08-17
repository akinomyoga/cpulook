#!/bin/bash

: ${MWGDIR:="$HOME/.mwg"}
: ${CPUDIR:="$MWGDIR/share/cpulook"}
test "x${CPUDIR%/}" == "x${PWD%/}" && exit

function create-dir {
  if test ! -d "$1"; then
    echo "cpulook-install: creating directory '$1'"
    mkdir -p "$1"
  fi
}

function update {
  local src="$1"
  local dst="${2:-$CPUDIR/$src}"
  if test "$src" -nt "$dst"; then
    echo "cpulook-install: updating '$dst'..."
    cp -p "$src" "$dst"
  fi

  # cpudir 算出を書き換える場合
  # sed '
  #   /^function cpudir\.initialize/i cpudir="$HOME/.mwg/share/cpulook"
  #   /^function cpudir\.initialize/,/^cpudir\.initialize/d
  # ' cputop
}

function update-script {
  local src="$1"
  local dst="${2:-$CPUDIR/$src}"
  if test "$src" -nt "$dst"; then
    echo "cpulook-install: updating '$dst'..."
    cp -p "$src" "$dst"

    # cpudirを書き換える
    sed '
      /^function cpudir\.initialize/i cpudir='"'$CPUDIR'"'
      /^function cpudir\.initialize/,/^cpudir\.initialize/d
    ' "$src" > "$dst"

    touch -r "$src" "$dst"
  fi
}

#------------------------------------------------------------------------------
# .mwg/libexec/echox

create-dir "$MWGDIR/libexec"
update ext/echox "$MWGDIR/libexec/echox"

#------------------------------------------------------------------------------
# .mwg/share/cpulook

create-dir "$CPUDIR"

# update m/
create-dir "$CPUDIR/m"
for d in m/*; do
  if test -d "$d"; then
    cp -rfp "$d" "$CPUDIR/m/"
  fi
done

# create m/switch
if test ! -e "$CPUDIR/m/switch"; then
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
update-script cpukill
update-script cpulast
update-script cpulook
update-script cpups
update-script cpuseekd
update-script cpusub
update-script cputop

# create configuration
if test ! -s "$CPUDIR/cpulist.cfg"; then
  echo "cpulook-install: creating default '$CPUDIR/cpulist.cfg'."
  cp -f "$CPUDIR/cpulist-default.cfg" "$CPUDIR/cpulist.cfg"
  echo "cpulook-install: [1mplease edit '$CPUDIR/cpulist.cfg'.[m"
fi

#------------------------------------------------------------------------------
# .mwg/bin

if test ! -d "$MWGDIR/bin"; then
  create-dir "$MWGDIR/bin"
fi

# check PATH
if ! [[ "$PATH" =~ (^|:)"$MWGDIR/bin"(/:|:|$) ]]; then
  echo "cpulook-install: [1mplease add '$MWGDIR/bin' to environmental variable PATH.[m"
fi

function install-bin {
  local file="$1"
  local entity="$CPUDIR/$file"
  local target="$MWGDIR/bin/$file"
  if test ! -e "$target"; then
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
