tss_test() {
  local help name_only_opt tags_opts not_tags_opts not_all_tags_opts
  zparseopts -D -E -F - -help=help {n,-name-only}=name_only_opt {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts \
    -not-all-tags+:=not_all_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss test [<options>] [--] <file>

Return 0 if true, 1 if false, 2 if an error occurred.

Options:
  -n, --name-only             $label_filter_name_only_descr
  -t, --tags <pattern...>     $label_filter_tags_descr
  -T, --not-tags <pattern...> $label_filter_not_tags_descr
  --not-all-tags <pattern...> $label_filter_not_all_tags_descr
  --help                      $label_generic_help_help_descr

EOF
    return 0
  fi

  # Process options
  local name_only=$name_only_opt
  local regular_file_pattern accept_non_regular
  internal_file_pattern_parse_tag_opts

  # Process positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  if [[ $# -ne 1 ]]; then
    logg "Expected exactly one positional argument, got $# instead"
    return 2
  fi
  local file_path
  file_path=$1

  internal_test
}

internal_test() {
  require_parameter name_only 'scalar*' || return 2
  require_parameter regular_file_pattern 'scalar*' || return 2
  require_parameter accept_non_regular 'scalar*' || return 2
  require_parameter file_path 'scalar*' || return 2

  if [[ $name_only ]]; then
    [[ $file_path = (*/|)${~regular_file_pattern} ]]

  else
    require_exists_quietable $file_path || return 2
    if [[ -f $file_path ]]; then
      [[ $file_path = (*/|)${~regular_file_pattern} ]]
    else
      [[ $accept_non_regular ]]
    fi
  fi
}
