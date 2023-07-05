tss_files() {
  local help tags_opts not_tags_opts
  zparseopts -D -E -F - -help=help {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF >&2

Usage: tss files [options] <path>...

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

  # Process positional arguments
  local paths
  if [[ $# -eq 0 ]]; then
    paths=(*)
  else
    paths=("$@")
  fi

  internal_files
}

internal_files() {
  [[ ${(t)patterns} = array* ]]
  [[ ${(t)anti_patterns} = array* ]]
  [[ ${(t)paths} = array* ]]

  local pathh location
  local -r path_starts_with=''
  for pathh in "${paths[@]}"; do
    require_exists $pathh || continue

    if [[ -f $pathh ]]; then
      print -r -- $pathh
    elif [[ -d $pathh ]]; then
      if location=$(tss_location_of $pathh); then
        internal_location_index_files
      else
        print -lr -- $pathh/**/*(.)
      fi
    # Not a regular file = don't print
    fi

  done | internal_filter
}
