tss_files() {
  local help ignored index_mode_opt tags_opts not_tags_opts not_all_tags_opts
  zparseopts -D -E -F - -help=help C=ignored {i,-index,I,-no-index}=index_mode_opt {t,-tags}+:=tags_opts \
    {T,-not-tags}+:=not_tags_opts -not-all-tags+:=not_all_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss files [options] [--] [<path>...]

List files under the given path(s), or under the current directory if no path is given.
Uses the location index if available and fresh. Takes the location of the first given path, or of the current directory if no path is given.

Options:
  -C                            $label_generic_C_descr
  -i, --index                   $label_files_index_descr
  -I, --no-index                $label_files_no_index_descr
  -t, --tags <pattern...>       $label_files_tags_descr
  -T, --not-tags <pattern...>   $label_files_not_tags_descr
  --not-all-tags <pattern...>   $label_files_not_all_tags_descr
  --help                        $label_generic_help_help_descr

EOF
    return 0
  fi

  # Process options
  local regular_file_pattern accept_non_regular
  internal_file_pattern_parse_tag_opts

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
  require_parameter paths 'array*'
  require_parameter regular_file_pattern 'scalar*'
  require_parameter accept_non_regular 'scalar*'

  local pathh files file_path error
  for pathh in $paths; do
    require_exists "$pathh" || error=x

    if [[ -d $pathh ]]; then
      files=("${pathh%/}"/**/${~regular_file_pattern}(.N))
      if [[ $accept_non_regular ]]; then
        files+=("${pathh%/}"/**/*(N^.))
      fi
      print -rl -- ${(in)files}

    else
      file_path=$pathh
      if [[ internal_test ]]; then
        print -r -- "$pathh"
      fi
    fi
  done
  [[ ! $error ]]
}
