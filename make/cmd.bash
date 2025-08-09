#!/usr/bin/env bash

function sub:update-common-header {
  local file=$1
  cp -f "$file" "$file.part" &&
    {
      cat make/common-header.bash &&
        sed -n '/^##----CPULOOK_COMMON_HEADER_END----[[:space:]]*$/,$p' "$file"
    } > "$file.part" &&
    mv "$file.part" "$file"
}

function sub:install-script {
  local src=$1 dst=$2 cpudir=$3 q=\' Q="'\''"
  cp -f "$src" "$dst.part" &&
    {
      printf '%s\n' '#!/usr/bin/env bash'
      printf '%s\n' "cpudir='${cpudir//$q/$Q}'"
      printf '%s\n' 'source "$cpudir/lib/common.bash"'
      sed -n '/^##----CPULOOK_COMMON_HEADER_END----[[:space:]]*$/,$p' "$src"
    } > "$dst.part" &&
    mv "$dst.part" "$dst"
}

sub:"$@"
