
# Regex groups are:
# - before tag group
# - tag group (brackets included)
# - tag group (brackets excluded)
# - after tag group
file_name_maybe_tag_group_regex='^([^[]*)(\[([^]]*)\])?(.*)$'

well_formed_file_name_maybe_tag_group_regex='^([^][]*)(\[([^][]*)\])?([^][]*)$'

# deprecated (use require_path_exists)?
require_file_exists() {
  local file_path
  file_path=$1

  if [[ ! -e $file_path ]]; then
    print -r  "File not found: ${(qqq)file_path}" >&2
    return 1
  fi
}

require_file_exists_not_dir() {
  local file_path
  file_path=$1

  require_file_exists $file_path

  if [[ -d $file_path ]]; then
    print -r  "File is a directory: ${(qqq)file_path}" >&2
    return 1
  fi
}

require_file_does_not_exist() {
  local file_path
  file_path=$1

  if [[ -f $file_path ]]; then
    print -r  "File already exists: ${(qqq)file_path}" >&2
    return 1
  fi
}

require_path_exists() {
  local pathh
  pathh=$1

  if [[ ! -e $pathh ]]; then
    print -r "Unknown file or directory: ${(qqq)pathh}" >&2
    return 1
  fi
}

tsp_file_has() {
  local file_path tag
  file_path=$1
  require_file_exists_not_dir $file_path
  tag=$2
  require_tag_valid $tag

  local file_tags
  file_tags=($(tsp_file_tags $file_path))
  ((file_tags[(Ie)$tag]))
}

tsp_file_clean_one_file() {
  unsetopt warn_create_global warn_nested_var

  local file_path file_name
  file_path=$1
  require_file_exists_not_dir $file_path
  file_name=$(basename $file_path)
  if ! [[ $file_name =~ $well_formed_file_name_maybe_tag_group_regex ]]; then
    print -r "Ignoring file with ill-formed name: ${(qqq)file_path}" >&2
    return 1
  fi

  local new_file_name
  new_file_name="$match[1]$match[4]"
  if [[ $new_file_name != $file_name ]]; then
    local new_file_path
    new_file_path="$(dirname $file_path)/$new_file_name"
    require_file_does_not_exist $new_file_path
    mv $file_path $new_file_path
  fi
}

# remove tag group from the given files
tsp_file_clean() {
  local file_path
  local -i statuss=0
  for file_path in "$@"; do
    tsp_file_clean_one_file $file_path || statuss=$?
  done
  return $statuss
}

tsp_file_set() {
  unsetopt warn_create_global warn_nested_var

  local file_path tags
  file_path=$1
  require_file_exists_not_dir $file_path
  tags=(${(z)2})

  # if tags empty, clean file
  if [[ ${#tags[@]} -eq 0 ]]; then
    tsp_file_clean $file_path

  else
    local file_name
    file_name=$(basename $file_path)

    if ! [[ "$file_name" =~ $file_name_maybe_tag_group_regex ]]; then
      print -r "Invalid file name: ${(qqq)file_path}" >&2
      return 1
    fi

    # If file has tag group, replace it
    local new_file_name
    if [[ -n $match[2] ]]; then
      new_file_name="$match[1][${tags[@]}]$match[4]"

    # Else, insert tag group before extension if present, else at end of file name
    else
      if [[ $file_name =~ '^(.+)(\.[^.]+)$' ]]; then
        new_file_name="$match[1][${tags[@]}]$match[2]"
      else
        new_file_name="${file_name}[${tags[@]}]"
      fi
    fi

    if [[ $new_file_name != $file_name ]]; then
      local new_file_path
      new_file_path="$(dirname $file_path)/$new_file_name"
      require_file_does_not_exist $new_file_path
      mv $file_path $new_file_path
    fi
  fi
}

# Prints the tags for the given file, or an empty string if the file has no tags
tsp_file_tags() {
  local file_path
  file_path=$1
  require_file_exists_not_dir $file_path

  local tags
  tags=($(basename $file_path | sed -En "s/$file_name_maybe_tag_group_regex/\3/p"))
  print -r "${tags[@]}"
}

tsp_file() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
#    add)
#      tsp_file_add "$@"
#      ;;
    clean)
      tsp_file_clean "$@"
      ;;
    has)
      tsp_file_has "$@"
      ;;
    tags)
      tsp_file_tags "$@"
      ;;
    location)
      tsp_location_of "$@"
      ;;
#    remove)
#      tsp_file_remove "$@"
#      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
