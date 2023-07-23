tss_files() {
  local help tags_opts not_tags_opts not_all_tags_opts
  zparseopts -D -E -F - -help=help {t,-tags}+:=tags_opts \
    {T,-not-tags}+:=not_tags_opts -not-all-tags+:=not_all_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss files [options] [--] [<path>...]

List files under the given path(s), or under the current directory if no path is given.

Options:
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
  if [[ $# -eq 0 ]]; then
    local paths=(*(N))
  else
    local paths=("$@")
  fi

  local files=()
  {
    internal_files
  } always {
    if [[ $files ]]; then
      print -rl -- ${(in)files}
    fi
  }
}

internal_files() {
  require_parameter paths 'array*'
  require_parameter regular_file_pattern 'scalar*'
  require_parameter accept_non_regular 'scalar*'

  require_parameter files 'array*'

  unsetopt warn_nested_var

  files=()
  local pathh file_path error
  for pathh in $paths; do
    require_exists "$pathh" || error=x

    if [[ -d $pathh ]]; then
      files+=("${pathh%/}"/**/${~regular_file_pattern}(.N))
      if [[ $accept_non_regular ]]; then
        files+=("${pathh%/}"/**/*(N^.))
      fi

    else
      file_path=$pathh
      if [[ internal_test ]]; then
        files+=("$pathh")
      fi
    fi
  done
  [[ ! $error ]]
}
