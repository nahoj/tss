
require_tag_valid() {
  local tag
  tag=$1

  # if $tag contains [ or ] or whitespace
  if [[ "$tag" =~ '[][[:space:]]' ]]; then
    echo "Invalid tag: '$tag'" >&2
    return 1
  fi
}

# Add one or more tags to one or more files if not already present
tsp_tag_add() {
  local tags tag file_paths
  tags=(${(z)1})
  for tag in "${tags[@]}"; do
    require_tag_valid "$tag"
  done
  shift
  file_paths=("$@")

  local file_path
  for file_path in "${file_paths[@]}"; do
    require_file_exists_not_dir "$file_path"

    local file_tags new_tags
    file_tags=($(tsp_file_tags "$file_path"))
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

list_files_in_paths() {
  local paths
  paths=("$@")
  if [[ ${#paths[@]} -eq 0 ]]; then
    paths=(*)
  fi

  local pathh
  for pathh in "${paths[@]}"; do
    require_file_exists "$pathh"

    if [[ -d "$pathh" ]]; then
      print -l "$pathh"/**/*(^/)
    else
      echo "$pathh"
    fi
  done
}

tsp_tag_files_aux() {
  local -i with_0_without_1
  local tag paths
  with_0_without_1=$1
  tag=$2
  require_tag_valid "$tag"
  shift 2
  paths=("$@")

  local file_path
  list_files_in_paths "${paths[@]}" | while IFS= read -r file_path; do
    if ! (( $(status tsp_file_has "$file_path" "$tag") ^^ with_0_without_1 )); then
      echo "$file_path"
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

# Remove tag from each of the given files if present
tsp_tag_remove() {
  local tags tag file_paths
  tags=(${(z)1})
  for tag in "${tags[@]}"; do
    require_tag_valid "$tag"
  done
  shift
  file_paths=("$@")

  local file_path
  for file_path in "$@"; do
    require_file_exists_not_dir "$file_path"

    local file_tags new_tags
    file_tags=($(tsp_file_tags "$file_path"))
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
      echo "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
