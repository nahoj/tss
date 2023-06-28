
require_tag_valid() {
  local tag
  tag=$1

  # if $tag contains ] or [ or / or whitespace
  if [[ "$tag" =~ '[][/[:space:]]' ]]; then
    print -r "Invalid tag: ${(qqq)tag}" >&2
    return 1
  fi
}

# Add one or more tags to one or more files if not already present
tsp_tag_add() {
  local tags tag file_paths
  tags=(${(z)1})
  for tag in "${tags[@]}"; do
    require_tag_valid $tag
  done
  shift
  file_paths=("$@")

  local file_path
  for file_path in "${file_paths[@]}"; do
    require_file_exists_not_dir $file_path

    local file_tags new_tags
    file_tags=($(tsp_file_tags $file_path))
    new_tags=($file_tags)
    for tag in "${tags[@]}"; do
      if ! ((new_tags[(Ie)$tag])); then
        new_tags+=($tag)
      fi
    done
    if ! arrayeq new_tags file_tags; then
      tsp_file_set $file_path "$new_tags"
    fi
  done
}

list_files_in_paths() {
  local paths
  paths=("$@")
  if [[ ${#paths[@]} -eq 0 ]]; then
    paths=(*)
  fi

  local pathh
  for pathh in "${paths[@]}"; do
    require_file_exists "$pathh"

    if [[ -d $pathh ]]; then
      print -lr $pathh/**/*(^/)
    else
      print -r $pathh
    fi
  done
}

tsp_tag_files_aux() {
  local -i with_0_without_1
  local tag_patterns paths
  with_0_without_1=$1
  tag_patterns=(${(z)2})
  if [[ ${#tag_patterns} -eq 0 ]]; then
    print -r "No tag patterns given" >&2
    return 1
  fi
  shift 2
  paths=("$@")

  local file_path
  list_files_in_paths "${paths[@]}" | while IFS= read -r file_path; do
    if ! (( $(status tsp_file_has $file_path "$tag_patterns") ^^ with_0_without_1 )); then
      print -r $file_path
    fi
  done
}

# List files with the given tag
tsp_tag_files() {
  tsp_tag_files_aux 0 "$@"
}

# List files without the given tag
tsp_tag_files_without() {
  tsp_tag_files_aux 1 "$@"
}

tsp_tag_in_patterns() {
  local tag tag_patterns
  tag=$1
  tag_patterns=(${(z)2})
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

tsp_tag_remove() {
  local tag_patterns file_paths
  tag_patterns=(${(z)1})
  if ((tag_patterns[(Ie)*])); then
    print -r "Removing all tags with * is forbidden as it might be a mistake. If this is what you want to do, use:" >&2
    print -r "    tsp file clean FILE ..." >&2
    return 1
  fi
  shift
  file_paths=("$@")

  local file_path
  for file_path in "$@"; do
    require_file_exists_not_dir $file_path

    local old_tags new_tags tag
    old_tags=($(tsp_file_tags $file_path))
    new_tags=()
    for tag in "${old_tags[@]}"; do
      if ! tsp_tag_in_patterns $tag "$tag_patterns"; then
        new_tags+=($tag)
      fi
    done

    if ! arrayeq new_tags old_tags; then
      tsp_file_set $file_path "$new_tags"
    fi
  done
}

tsp_tag() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    add)
      tsp_tag_add "$@"
      ;;
    files)
      tsp_tag_files "$@"
      ;;
    files-without) # temporary?
      tsp_tag_files_without "$@"
      ;;
    remove)
      tsp_tag_remove "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
