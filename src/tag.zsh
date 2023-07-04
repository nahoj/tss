
require_tag_valid() {
  local tag
  tag=$1

  # if $tag contains ] or [ or etc.
  if [[ "$tag" =~ '[][/[:cntrl:][:space:]]' ]]; then
    print -r "Invalid tag: ${(qqq)tag}" >&2
    return 1
  fi
}

# Add one or more tags to one or more files if not already present
tss_tag_add() {
  local tags tag file_paths
  tags=(${(s: :)1})
  for tag in "${tags[@]}"; do
    require_tag_valid $tag
  done
  shift
  file_paths=("$@")

  local file_path
  for file_path in "${file_paths[@]}"; do
    require_exists_taggable $file_path

    local file_tags new_tags
    file_tags=($(tss_file_tags $file_path))
    new_tags=($file_tags)
    for tag in "${tags[@]}"; do
      if ! ((new_tags[(Ie)$tag])); then
        new_tags+=($tag)
      fi
    done
    if ! arrayeq new_tags file_tags; then
      tss_file_set $file_path "$new_tags"
    fi
  done
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

  # Loop over stdin
  local file_path tags pattern tag
  while IFS= read -r file_path; do
    tags=($(tss_file_tags $file_path))

    for pattern in "${patterns[@]}"; do
      for tag in "${tags[@]}"; do
        if [[ $tag = ${~pattern} ]]; then
          # pattern OK
          continue 2
        fi
      done
      # file KO
      continue 2
    done

    for pattern in "${anti_patterns[@]}"; do
      for tag in "${tags[@]}"; do
        if [[ $tag = ${~pattern} ]]; then
          # file KO
          continue 3
        fi
      done
      # pattern OK
    done
    # file OK

    print -r $file_path
  done
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

  local filter_command=(tss_filter)
  if [[ -n $patterns ]]; then
    filter_command+=(-t "$patterns")
  fi
  if [[ -n $anti_patterns ]]; then
    filter_command+=(-T "$anti_patterns")
  fi

  tss_file_list $paths | "$filter_command[@]"
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

tss_tag_remove() {
  local tag_patterns file_paths
  tag_patterns=(${(s: :)1})
  if ((tag_patterns[(Ie)*])); then
    print -r "Removing all tags with * is forbidden as it might be a mistake. If this is what you want to do, use:" >&2
    print -r "    tss file clean FILE ..." >&2
    return 1
  fi
  shift
  file_paths=("$@")

  local file_path
  for file_path in "$@"; do
    require_exists_taggable $file_path

    local old_tags new_tags tag
    old_tags=($(tss_file_tags $file_path))
    new_tags=()
    for tag in "${old_tags[@]}"; do
      if ! tss_tag_in_patterns $tag "$tag_patterns"; then
        new_tags+=($tag)
      fi
    done

    if ! arrayeq new_tags old_tags; then
      tss_file_set $file_path "$new_tags"
    fi
  done
}

tss_tag() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    add)
      tss_tag_add "$@"
      ;;
    files)
      tss_tag_files "$@"
      ;;
    remove)
      tss_tag_remove "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
