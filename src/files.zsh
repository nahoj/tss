tss_files() {
  local help index_mode_opt tags_opts not_tags_opts not_all_tags_opts
  zparseopts -D -E -F - -help=help {I,-no-index}=index_mode_opt {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts \
    -not-all-tags+:=not_all_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss files [options] [--] <path>...

Options:
  -I, --no-index                $label_files_no_index_descr
  -t, --tags <pattern...>       $label_files_tags_descr
  -T, --not-tags <pattern...>   $label_files_not_tags_descr
  --not-all-tags <pattern...>   $label_files_not_all_tags_descr
  --help                        $label_generic_help_help_descr

EOF
    return 0
  fi

  # Process options
  local -aU patterns anti_patterns not_all_patterns
  local -i i
  for ((i=2; i <= $#tags_opts; i+=2)); do
    patterns+=(${(s: :)tags_opts[i]})
  done
  for ((i=2; i <= $#not_tags_opts; i+=2)); do
    anti_patterns+=(${(s: :)not_tags_opts[i]})
  done
  for ((i=2; i <= $#not_all_tags_opts; i+=2)); do
    not_all_patterns+=(${(s: :)not_all_tags_opts[i]})
  done

  # Process positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  local paths
  if [[ $# -eq 0 ]]; then
    paths=(*(N))
  else
    paths=("$@")
  fi

  internal_files
}

internal_files() {
  require_parameter index_mode_opt 'array*'
  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'
  require_parameter paths 'array*'

  # No-index mode
  if [[ -n $index_mode_opt && ( $index_mode_opt[1] = '-I' || $index_mode_opt[1] = '--no-index' ) ]]; then
    local pathh file_path
    for pathh in $paths; do
      require_exists "$pathh"
      if [[ -f $pathh ]]; then
        print -r -- $pathh
      elif [[ -d $pathh ]]; then
        for file_path in "$pathh"/**/*(.N); do
          print -r -- "$file_path"
        done
      fi

    done | {
      local -ar name_only_opt=(-n)
      internal_filter

    } || return $?

  else
    internal_files_in_paths $paths
  fi
}

# List files in the given paths using index(es) if found
internal_files_in_paths() {
  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'

  local paths
  paths=($@)

  local pathh file_path
  local -ar name_only_opt=(-n)
  for pathh in $paths; do
    require_exists "$pathh"

    if [[ -f $pathh ]]; then
      file_path=$pathh
      if internal_test; then
        print -r -- "$pathh"
      fi

    elif [[ -d $pathh ]]; then
      internal_files_in_dir "$pathh"

    # Not a regular file = don't print
    fi
  done
}

# List files under the given dir using the index if found
internal_files_in_dir() {
  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'
  # optional: dont_look_up (true if defined)

  [[ $# -eq 1 ]] || fail "Expected 1 argument, got $#"
  local pathh
  pathh=$1

  # Define location if possible
  local location
  if [[ -v dont_look_up ]]; then
    # We know no ancestor directory is a location
    if [[ -f $pathh/.ts/tsi.json ]]; then
        location=.
    fi
  else
    location=$(tss_location_of "$pathh") || true
  fi

  # If we found a location
  if [[ -n $location ]]; then
    internal_location_index_files_path

  else
    local -r dont_look_up
    internal_files_in_paths "$pathh"/*(N)
  fi
}
