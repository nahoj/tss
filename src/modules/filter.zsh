tss_filter() {
  local -a help name_only_opt tags_opts not_tags_opts not_all_tags_opts
  zparseopts -D -E -F - -help=help {n,-name-only}=name_only_opt {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts \
    -not-all-tags+:=not_all_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss filter [<options>]

Options:
  -n, --name-only               $label_filter_name_only_descr
  -t, --tags <pattern...>       $label_filter_tags_descr
  -T, --not-tags <pattern...>   $label_filter_not_tags_descr
  --not-all-tags <pattern...>   $label_filter_not_all_tags_descr
  --help                        $label_generic_help_help_descr

EOF
    return 0
  fi

  # Process options
  local name_only=$name_only_opt
  local regular_file_pattern accept_non_regular
  internal_file_pattern_parse_tag_opts

  # Reject positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  if [[ $# -ne 0 ]]; then
    fail "No positional arguments expected"
  fi

  internal_filter
}

internal_filter() {
  require_parameter name_only 'scalar*'
  require_parameter regular_file_pattern 'scalar*'
  require_parameter accept_non_regular 'scalar*'

  if [[ $regular_file_pattern = '*' && $accept_non_regular ]]; then
    cat
    return 0
  fi

  # Loop over stdin
  local file_path
  while read -r file_path; do
    if internal_test; then
      print -r -- "$file_path"
    fi
  done
}
