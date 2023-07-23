clean_one_file() {
  local file_path file_name
  file_path=$1
  require_exists_taggable "$file_path"
  file_name=${file_path:t}
  local -a match mbegin mend
  if ! [[ $file_name =~ $well_formed_file_name_maybe_tag_group_regex ]]; then
    fail "Ignoring file with ill-formed name: ${(qqq)file_path}"
  fi

  local new_file_name
  new_file_name="$match[1]$match[4]"
  if [[ $new_file_name != $file_name ]]; then
    local new_file_path
    new_file_path="${file_path:h}/$new_file_name"
    require_does_not_exist "$new_file_path"
    mv "$file_path" "$new_file_path"
  fi
}

tss_clean() {
  local help
  zparseopts -D -E -F - -help=help

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss clean <file>...

Remove the whole tag group from the given files.

EOF
    return 0
  fi

  # Process positional arguments
  if [[ ${1:-} = -- ]]; then
    shift
  fi
  if [[ $# -eq 0 ]]; then
    fail "At least one argument expected"
  fi
  local file_paths=($@)

  local file_path error
  for file_path in $file_paths; do
    clean_one_file "$file_path" || error=x
  done

  local location
  if location=$(tss_location_of "${file_paths[1]:h}"); then
    internal_location_index_build_if_stale_async
  fi

  [[ ! $error ]]
}

set_file_tags() {
  local file_path tags
  file_path=$1
  require_exists_taggable "$file_path"
  shift
  tags=($@)

  # if tags empty, clean file
  if [[ $#tags -eq 0 ]]; then
    clean_one_file "$file_path"

  else
    local file_name
    file_name=${file_path:t}

    local -a match mbegin mend
    if ! [[ "$file_name" =~ $file_name_maybe_tag_group_regex ]]; then
      fail "Invalid file name: ${(qqq)file_path}"
    fi

    # If file has tag group, replace it
    local new_file_name
    if [[ -n $match[2] ]]; then
      new_file_name="$match[1][${(j: :)tags}]$match[4]"

    # Else, insert tag group before extension if present, else at end of file name
    else
      if [[ $file_name =~ '^(.+)(\.[^.]+)$' ]]; then
        new_file_name="$match[1][${(j: :)tags}]$match[2]"
      else
        new_file_name="${file_name}[${(j: :)tags}]"
      fi
    fi

    if [[ $new_file_name != $file_name ]]; then
      local new_file_path
      new_file_path="${file_path:h}/$new_file_name"
      require_does_not_exist "$new_file_path"
      mv "$file_path" "$new_file_path"
    fi
  fi
}

tag_in_patterns() {
  local tag patterns
  tag=$1
  shift
  patterns=($@)
  if [[ $#patterns -eq 0 ]]; then
    fail "No tag patterns given"
  fi

  local pattern
  for pattern in "$patterns[@]"; do
    if [[ $tag = ${~pattern} ]]; then
      return 0
    fi
  done
  return 1
}

internal_add_remove_one_file() {
  require_parameter add_tags 'array*'
  require_parameter remove_patterns 'array*'
  require_parameter file_path 'scalar*'
  require_well_formed "$file_path"
  require_exists_taggable "$file_path"

  local -a file_tags
  internal_file_tags_name_only

  local new_tags tag
  if [[ $#remove_patterns -gt 0 ]]; then
    new_tags=()
    for tag in $file_tags; do
      if ! tag_in_patterns "$tag" $remove_patterns; then
        new_tags+=("$tag")
      fi
    done
  else
    new_tags=($file_tags)
  fi

  for tag in $add_tags; do
    if ! ((new_tags[(Ie)$tag])); then
      new_tags+=("$tag")
    fi
  done

  if ! arrayeq new_tags file_tags; then
    set_file_tags "$file_path" $new_tags
  fi
}

internal_add_remove() {
  require_parameter add_tags 'array*'
  require_parameter remove_patterns 'array*'
  require_parameter file_paths 'array*'

  local file_path error
  for file_path in $file_paths; do
    internal_add_remove_one_file || error=x
  done

  local location
  if location=$(tss_location_of "${file_paths[1]:h}"); then
    internal_location_index_build_if_stale_async
  fi

  [[ ! $error ]]
}

tss_add() {
  local help
  zparseopts -D -E -F - -help=help

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss add '<tag> ...' <file>...

Add one or more tags to one or more files if not already present.

EOF
    return 0
  fi

  if [[ ${1:-} = -- ]]; then
    shift
  fi
  if [[ $# -lt 2 ]]; then
    fail "At least 2 argument expected"
  fi
  local add_tags tag file_paths
  add_tags=(${(s: :)1})
  for tag in $add_tags; do
    require_tag_valid "$tag"
  done
  shift
  file_paths=($@)

  local remove_patterns=()
  internal_add_remove
}

tss_remove() {
  local help
  zparseopts -D -E -F - -help=help

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss remove '<pattern> ...' <file>...

Remove all tags matching any of the given patterns from one or more files.

EOF
    return 0
  fi

  if [[ ${1:-} = -- ]]; then
    shift
  fi
  if [[ $# -lt 2 ]]; then
    fail "At least 2 argument expected"
  fi
  local remove_patterns file_paths
  remove_patterns=(${(s: :)1})
  require_valid_patterns $remove_patterns
  if ((remove_patterns[(Ie)*])); then
    logg "Removing all tags with * is forbidden as it might be a mistake. If this is what you want to do, use:"
    logg "    tss file clean <file> ..."
    return 1
  fi
  shift
  file_paths=($@)

  local add_tags=()
  internal_add_remove
}
