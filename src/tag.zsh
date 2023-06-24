
require_tag_valid() {
  local tag
  tag=$1

  # if $tag contains [ or ] or whitespace
  if [[ "$tag" =~ '[][[:space:]]' ]]; then
    echo "Invalid tag: '$tag'"
    return 1
  fi
}

# Add one or more tags to one or more files if not already present
tsp_tag_add() {
  local tags file_paths
  tags=(${(z)1})
  shift
  file_paths=("$@")
  local tag
  for tag in "${tags[@]}"; do
    require_tag_valid "$tag"
  done

  local file_path
  for file_path in "${file_paths[@]}"; do
    require_file_exists_not_dir "$file_path"

    local file_tags new_tags
    file_tags=($(tsp_file_list "$file_path"))
    new_tags=($file_tags)
    for tag in "${tags[@]}"; do
      if ! ((new_tags[(Ie)$tag])); then
        new_tags+=($tag)
      fi
    done
    if ! arrayeq new_tags file_tags; then
      tsp_file_set "$file_path" "$new_tags"
    fi
  done
}

# Remove tag from each of the given files if present
tsp_tag_remove() {
  local tags file_paths
  tags=(${(z)1})
  shift
  file_paths=("$@")
  local tag
  for tag in "${tags[@]}"; do
    require_tag_valid "$tag"
  done

  local file_path
  for file_path in "$@"; do
    require_file_exists_not_dir "$file_path"

    local file_tags new_tags
    file_tags=($(tsp_file_list "$file_path"))
    new_tags=($file_tags)
    for tag in "${tags[@]}"; do
      new_tags=("${(@)new_tags:#$tag}")
    done
    if ! arrayeq new_tags file_tags; then
      tsp_file_set "$file_path" "$new_tags"
    fi
  done
}

tsp_tag() {
  local subcommand
  subcommand=$1
  shift
  case "$subcommand" in
    add)
      tsp_tag_add "$@"
      ;;
    remove)
      tsp_tag_remove "$@"
      ;;
    *)
      echo "Unknown subcommand: $subcommand"
      return 1
      ;;
  esac
}
