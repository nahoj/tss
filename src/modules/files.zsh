tss_files() {
  local help index_mode_opt tags_opts not_tags_opts not_all_tags_opts
  zparseopts -D -E -F - -help=help {I,-no-index}=index_mode_opt {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts \
    -not-all-tags+:=not_all_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss files [options] [--] [<path>...]

List files under the given path(s), or under the current directory if no path is given.
Uses the location index if available and fresh. Takes the location of the first given path, or of the current directory if no path is given.

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
  internal_parse_tag_opts

  # Process positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  local paths location
  if [[ $# -eq 0 ]]; then
    paths=(*(N))
    location=$(tss_location_of .) || true
  else
    paths=("$@")
    location=$(tss_location_of "$1") || true
  fi

  if [[ $index_mode_opt && $index_mode_opt[1] = (-I|--no-index) ]]; then
    location=
  fi

  internal_files
}

internal_files() {
  require_parameter location 'scalar*'
  require_parameter paths 'array*'

  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'

  if [[ $location ]]; then
    if tss_location_index_is_fresh $location; then
      local pathh file_path error
      for pathh in $paths; do
        require_exists "$pathh" || error=x
        if [[ -f $pathh ]]; then
          file_path=$pathh
          if internal_test; then
            print -r -- "$pathh"
          fi
        elif [[ -d $pathh ]]; then
          internal_location_index_files_path $location
        # Not a regular file = don't print
        fi
      done
      [[ ! $error ]]

    else
      internal_files_in_paths_no_index
      internal_location_index_build_if_stale_async
    fi

  else
    internal_files_in_paths_no_index
  fi
}

internal_files_in_paths_no_index() {
  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'
  require_parameter paths 'array*'

  {
    local pathh file_path error
    for pathh in $paths; do
      require_exists "$pathh" || error=x
      if [[ -f $pathh ]]; then
        print -r -- $pathh
      elif [[ -d $pathh ]]; then
        for file_path in "$pathh"/**/*(.N); do
          print -r -- "$file_path"
        done
      fi
    done
    [[ ! $error ]]

   } | {
    local -r name_only=x
    internal_filter

  } || return $?
}
