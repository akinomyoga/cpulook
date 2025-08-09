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

sub:"$@"
