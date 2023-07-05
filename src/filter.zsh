tss_filter() {
  local help tags_opts not_tags_opts
  zparseopts -D -E -F - -help=help {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF >&2

Usage: tss filter [options]

Options:
  -t, --tags <pattern...>     Only output files that have tags matching all the given patterns
  -T, --not-tags <pattern...> Don't output files that have any tag matching any of the given patterns
  --help                      Show this help message

EOF
    return 0
  fi

  # Process options
  local -aU patterns anti_patterns
  local -i i
  for ((i=2; i <= ${#tags_opts}; i+=2)); do
    patterns+=(${(s: :)tags_opts[i]})
  done
  for ((i=2; i <= ${#not_tags_opts}; i+=2)); do
    anti_patterns+=(${(s: :)not_tags_opts[i]})
  done

  # Reject positional arguments
  if [[ $# -ne 0 ]]; then
    print -r "No positional arguments expected" >&2
    return 1
  fi

  internal_filter
}

internal_filter() {
  [[ ${(t)patterns} = array* ]]
  [[ ${(t)anti_patterns} = array* ]]

  if [[ $#patterns -eq 0 && $#anti_patterns -eq 0 ]]; then
    cat
    return 0
  fi

  # Loop over stdin
  local file_path
  while IFS= read -r file_path; do
    if internal_test; then
      print -r $file_path
    fi
  done
}
