# A ZSH library for TagSpaces

# This file contains a set of zsh functions to read and edit TagSpaces tags.

# From the TagSpaces documentation:
# "TagSpaces supports tagging of files in a cross platform way. It uses basically the name of the file to save this
# kind of meta information. As an example if you want to add the tags vacation and alps to a image named IMG-2653.jpg,
# the application will simply rename it to IMG-2653[vacation alps].jpg."

tsp() {

  set -euo pipefail

  require_file_exists() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
      echo "File not found: $file_path"
      return 1
    fi
  }

  require_file_does_not_exist() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
      echo "File already exists: $file_path"
      return 1
    fi
  }

  # Regex groups are:
  # - before tag group
  # - tag group (brackets included)
  # - tag group (brackets excluded)
  # - after tag group
  local file_name_maybe_tag_group_regex='^([^[]*)(\[([^]]*)\])?(.*)$'

  # Prints the tags for the given file, or an empty string if the file has no tags
  tsp_file_list() {
    local file_path="$1"
    require_file_exists "$file_path"
    local tags=($(basename "$file_path" | sed -En "s/$file_name_maybe_tag_group_regex/\3/p"))
    echo "${tags[@]}"
  }

  tsp_file_has() {
    local tag="$1"
    local file_path="$2"
    require_file_exists "$file_path"
    local file_tags=($(tsp_file_list "$file_path"))
    ((file_tags[(Ie)$tag]))
  }

  # remove tag group from the given files
  tsp_file_clean() {
    local file_path
    for file_path in "$@"; do
      require_file_exists "$file_path"
      local file_name=$(basename "$file_path")
      local new_file_name=$(sed -E "s/$file_name_maybe_tag_group_regex/\1\4/" <<<"$file_name")
      if [[ "$new_file_name" != "$file_name" ]]; then
        local new_file_path="$(dirname "$file_path")/$new_file_name"
        require_file_does_not_exist "$new_file_path"
        mv "$file_path" "$new_file_path"
      fi
    done
  }


  tsp_file_set() {
    local tags=(${(z)1})
    local file_path="$2"
    require_file_exists "$file_path"

    # if tags empty, clean file
    if [[ ${#tags[@]} -eq 0 ]]; then
      tsp_file_clean "$file_path"

    else
      local file_name=$(basename "$file_path")

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
        local new_file_path="$(dirname "$file_path")/$new_file_name"
        require_file_does_not_exist "$new_file_path"
        mv "$file_path" "$new_file_path"
      fi
    fi
  }

  # Add one or more tags to one or more files if not already present
  tsp_file_add() {
    local tags=(${(z)1})
    shift

    for file_path in "$@"; do
      require_file_exists "$file_path"

      local file_tags=($(tsp_file_list "$file_path"))
      local new_tags=($file_tags)
      for tag in "${tags[@]}"; do
        if ! ((new_tags[(Ie)$tag])); then
          new_tags+=($tag)
        fi
      done
      if [[ $new_tags != $file_tags ]]; then # TODO check S/O
        tsp_file_set "$new_tags" "$file_path"
      fi
    done
  }

  # Remove tag from each of the given files if present
  tsp_file_remove() {
    local tags=(${(z)1})
    shift

    for file_path in "$@"; do
      require_file_exists "$file_path"

      local file_tags=($(tsp_file_list "$file_path"))
      local new_tags=($file_tags)
      for tag in "${tags[@]}"; do
        new_tags=("${(@)new_tags:#$tag}")
      done
      if [[ $new_tags != $file_tags ]]; then # TODO check S/O
        tsp_file_set "$new_tags" "$file_path"
      fi
    done
  }

  tsp_file() {
    local subcommand="$1"
    shift
    case "$subcommand" in
      add)
        tsp_file_add "$@"
        ;;
      clean)
        tsp_file_clean "$@"
        ;;
      has)
        tsp_file_has "$@"
        ;;
      list)
        tsp_file_list "$@"
        ;;
      remove)
        tsp_file_remove "$@"
        ;;
      *)
        echo "Unknown subcommand: $subcommand"
        return 1
        ;;
    esac
  }

  ##############################
  # Main
  ##############################

  local subcommand="$1"
  shift
  case "$subcommand" in
    file)
      tsp_file "$@"
      ;;
    *)
      echo "Unknown subcommand: $subcommand"
      return 1
      ;;
  esac
}
