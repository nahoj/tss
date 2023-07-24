clean_one_file() {
  local file_path=$1
  require_exists_taggable "$file_path"

  local file_name=${file_path:t}
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
  local file_path=$1
  require_exists_taggable "$file_path"
  shift
  local tags=($@)

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
  local tag=$1
  shift
  local patterns=($@)
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
  require_parameter action 'scalar*'
  require_parameter tags_opts 'array*'

  if [[ ${1:-} = -- ]]; then
    shift
  fi
  if [[ $# -lt 2 ]]; then
    fail "Expected at least 2 positional arguments, got $#."
  fi

  # Get tags or patterns from options and first positional argument
  local opt_tags_or_patterns=()
  local -i i
  for ((i=2; i <= $#tags_opts; i+=2)); do
    opt_tags_or_patterns+=(${(s: :)tags_opts[i]})
  done

  case $action in
    add)
      local -aU add_tags=($opt_tags_or_patterns ${(s: :)1}) remove_patterns=()
      local tag
      for tag in $add_tags; do
        require_tag_valid "$tag"
      done
      ;;

    remove)
      local -aU add_tags=() remove_patterns=($opt_tags_or_patterns ${(s: :)1})
      require_valid_patterns $remove_patterns
      if ((remove_patterns[(Ie)*])); then
        logg "Removing all tags with * is forbidden as it might be a mistake. If this is what you want to do, use:"
        logg "    tss file clean <file> ..."
        return 1
      fi
      ;;
    *)
      fail "Invalid action: $action"
      ;;
  esac
  shift

  # Remaining positional arguments are file paths
  local file_paths=($@)

  local file_path error
  for file_path in $file_paths; do
    internal_add_remove_one_file || error=x
  done

  local location
  if location=$(tss_location_of "${file_paths[1]:h}"); then # :h because the file has likely been renamed
    internal_location_index_build_if_stale_async
  fi

  [[ ! $error ]]
}

tss_add() {
  local help tags_opts
  zparseopts -D -E -F - -help=help {t,-tags}+:=tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss add [<options>] [--] '<tag> ...' <file>...
or:    tss add '' <file>... -t '<tag> ...'  # to get filtered tag suggestions

Add one or more tags to one or more files if not already present.

Options:
  -t, --tags <tag ...>  $label_add_tags_descr
  --help                $label_generic_help_help_descr
EOF
    return 0
  fi

  local -r action=add
  internal_add_remove "$@"
}

tss_remove() {
  local help tags_opts
  zparseopts -D -E -F - -help=help {t,-tags}+:=tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss remove [<options>] [--] '<pattern> ...' <file>...
or:    tss remove '' <file>... -t '<pattern> ...'  # to get filtered tag suggestions

Remove all tags matching any of the given patterns from one or more files.

Options:
  -t, --tags <pattern ...>      $label_remove_tags_descr
  --help                        $label_generic_help_help_descr

EOF
    return 0
  fi

  local -r action=remove
  internal_add_remove "$@"
}
