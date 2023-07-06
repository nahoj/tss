tss_test() {
  local help name_only_opt tags_opts not_tags_opts
  zparseopts -D -E -F - -help=help {n,-name-only}=name_only_opt {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss test [options] <file>

Return 0 if true, 1 if false, 2 if an error occurred.

Options:
  -n, --name-only             Test only the file's name, assume the file exists and is a taggable file
  -t, --tags <pattern...>     True only if the file has tags matching all the given patterns
  -T, --not-tags <pattern...> True only if the file doesn't have any tag matching any of the given patterns
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

  # Process positional arguments
  if [[ $1 = '--' ]]; then
    shift
  fi
  if [[ $# -ne 1 ]]; then
    print -r "Expected exactly one positional argument, got $# instead" >&2
    return 2
  fi
  local file_path
  file_path=$1

  internal_test
}

internal_test() {
  require_parameter internal_test name_only_opt 'array*' || return 2
  require_parameter internal_test patterns 'array*' || return 2
  require_parameter internal_test anti_patterns 'array*' || return 2
  require_parameter internal_test file_path 'scalar*' || return 2

  local tags pattern tag
  tags=($(internal_file_tags)) || return 2

  for pattern in "${patterns[@]}"; do
    for tag in "${tags[@]}"; do
      if [[ $tag = ${~pattern} ]]; then
        # pattern OK
        continue 2
      fi
    done
    # file KO
    return 1
  done

  for pattern in "${anti_patterns[@]}"; do
    for tag in "${tags[@]}"; do
      if [[ $tag = ${~pattern} ]]; then
        # file KO
        return 1
      fi
    done
    # pattern OK
  done
  # file OK
}
