# Prints the tags for the given file, or an empty string if the file has no tags
tsp_file_list() {
  local file_path
  file_path=$1
  require_file_exists "$file_path"

  local tags
  tags=($(basename "$file_path" | sed -En "s/$file_name_maybe_tag_group_regex/\3/p"))
  echo "${tags[@]}"
}

# Prints the closest ancestor directory of the given file that contains a `.ts/tsi.json` file,
# or an empty string if there is none
tsp_file_location() {
  aux() {
    local file_path
    file_path=$1

    if [[ "$file_path" == "/" ]]; then
      echo ""
    else
      local dir_path="$(dirname "$file_path")"
      if [[ -f "$dir_path/.ts/tsi.json" ]]; then
        echo "$dir_path"
      else
        aux "$dir_path"
      fi
    fi
  }

  local file_path
  file_path=$1
  require_file_exists "$file_path"
  aux "$(realpath -s "$file_path")"
}

tsp_file_has() {
  local file_path tag
  file_path=$1
  tag=$2
  require_file_exists "$file_path"

  local file_tags
  file_tags=($(tsp_file_list "$file_path"))
  ((file_tags[(Ie)$tag]))
}

# remove tag group from the given files
tsp_file_clean() {
  local file_path
  for file_path in "$@"; do
    require_file_exists "$file_path"

    local file_name new_file_name
    file_name=$(basename "$file_path")
    new_file_name=$(sed -E "s/$file_name_maybe_tag_group_regex/\1\4/" <<<"$file_name")
    if [[ "$new_file_name" != "$file_name" ]]; then
      local new_file_path
      new_file_path="$(dirname "$file_path")/$new_file_name"
      require_file_does_not_exist "$new_file_path"
      mv "$file_path" "$new_file_path"
    fi
  done
}

tsp_file_set() {
  local file_path tags
  file_path=$1
  tags=(${(z)2})
  require_file_exists "$file_path"

  # if tags empty, clean file
  if [[ ${#tags[@]} -eq 0 ]]; then
    tsp_file_clean "$file_path"

  else
    local file_name
    file_name=$(basename "$file_path")

    if ! [[ "$file_name" =~ $file_name_maybe_tag_group_regex ]]; then
      echo "Invalid file name: $file_path"
      return 1
    fi

    # If file has tag group, replace it
    local new_file_name
    if [[ -n "${match[2]}" ]]; then
      new_file_name="$match[1][${tags[@]}]$match[4]"

    # Else, insert tag group before extension if present, else at end of file name
    else
      if [[ "$file_name" =~ '^(.+)(\.[^.]+)$' ]]; then
        new_file_name="$match[1][${tags[@]}]$match[2]"
      else
        new_file_name="${file_name}[${tags[@]}]"
      fi
    fi

    if [[ "$new_file_name" != "$file_name" ]]; then
      local new_file_path
      new_file_path="$(dirname "$file_path")/$new_file_name"
      require_file_does_not_exist "$new_file_path"
      mv "$file_path" "$new_file_path"
    fi
  fi
}

tsp_file() {
  local subcommand
  subcommand=$1
  shift
  case "$subcommand" in
#    add)
#      tsp_file_add "$@"
#      ;;
    clean)
      tsp_file_clean "$@"
      ;;
    has)
      tsp_file_has "$@"
      ;;
    list)
      tsp_file_list "$@"
      ;;
    location)
      tsp_file_location "$@"
      ;;
#    remove)
#      tsp_file_remove "$@"
#      ;;
    *)
      echo "Unknown subcommand: $subcommand"
      return 1
      ;;
  esac
}
