
require_tag_valid() {
  local tag
  tag=$1

  # if $tag contains ] or [ or etc.
  if [[ "$tag" =~ '[][/[:cntrl:][:space:]]' ]]; then
    print -r "Invalid tag: ${(qqq)tag}" >&2
    return 1
  fi
}

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
#    echo $file_path >&2
    if internal_test; then
      print -r $file_path
    fi
  done
}

tss_test() {
  local help tags_opts not_tags_opts
  zparseopts -D -E -F - -help=help {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF >&2

Usage: tss test [options] <file>

Return 0 if true, 1 if false, 2 if an error occurred.

Options:
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
  if [[ $# -ne 1 ]]; then
    print -r "Expected exactly one positional argument, got $# instead" >&2
    return 2
  fi
  local file_path
  file_path=$1

  internal_test
}


internal_test() {
  [[ ${(t)patterns} = array* ]] || return 2
  [[ ${(t)anti_patterns} = array* ]] || return 2
  [[ ${(t)file_path} = scalar* ]] || return 2

  local tags pattern tag
  tags=($(tss_file_tags $file_path)) || return 2

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

tss_tag_files() {
  local help not
  zparseopts -D -E -F - -help=help {T,-not-tags}+:=not

  if [[ -n $help ]]; then
    cat <<EOF >&2

Usage: tss tag files [options] <pattern...> <path>...

Options:
  -T, --not-tags <pattern...> Exclude files that have any tag matching any of the given patterns
  --help                      Show this help message

EOF
    return 0
  fi

  # Process options
  local anti_patterns=()
  local -i i
  for ((i=2; i <= ${#not}; i+=2)); do
    anti_patterns+=(${(s: :)not[i]})
  done

  # Process positional arguments
  local patterns paths
  patterns=(${(s: :)1})
  shift 1
  paths=("$@")

  tss_file_list $paths | internal_filter
}

tss_tag_in_patterns() {
  local tag tag_patterns
  tag=$1
  tag_patterns=(${(s: :)2})
  if [[ ${#tag_patterns} -eq 0 ]]; then
    print -r "No tag patterns given" >&2
    return 1
  fi

  local pattern
  for pattern in "${tag_patterns[@]}"; do
    if [[ $tag = ${~pattern} ]]; then
      return 0
    fi
  done
  return 1
}

tss_tag() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    files)
      tss_tag_files "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
