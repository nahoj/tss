# A ZSH library for TagSpaces

# This file contains a set of zsh functions to read and edit TagSpaces tags.

# From the TagSpaces documentation:
# "TagSpaces supports tagging of files in a cross platform way. It uses basically the name of the file to save this
# kind of meta information. As an example if you want to add the tags vacation and alps to a image named IMG-2653.jpg,
# the application will simply rename it to IMG-2653[vacation alps].jpg."

tsp() {

  set -uo localoptions -o pipefail

  # From https://stackoverflow.com/a/76516890
  # Takes the names of two array variables
  arrayeq() {
    typeset -i i len

    # The P parameter expansion flag treats the parameter as a name of a
    # variable to use
    len=${#${(P)1}}

    if [[ $len -ne ${#${(P)2}} ]]; then
       return 1
    fi

    # Remember zsh arrays are 1-indexed
    for (( i = 1; i <= $len; i++)); do
      if [[ ${(P)1[i]} != ${(P)2[i]} ]]; then
          return 1
      fi
    done
  }

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

  # Prints the closest ancestor directory of the given file that contains a `.ts/tsi.json` file,
  # or an empty string if there is none
  tsp_file_location() {
    aux() {
      local file_path="$1"
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

    local file_path="$1"
    require_file_exists "$file_path"
    aux "$(realpath -s "$file_path")"
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
      if ! arrayeq new_tags file_tags; then
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
      if ! arrayeq new_tags file_tags; then
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
      location)
        tsp_file_location "$@"
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
