
# Regex groups are:
# - before tag group
# - tag group (brackets included)
# - tag group (brackets excluded)
# - after tag group
file_name_maybe_tag_group_regex='^([^[]*)(\[([^]]*)\])?(.*)$'

well_formed_file_name_maybe_tag_group_regex='^([^][]*)(\[([^][]*)\])?([^][]*)$'

require_does_not_exist() {
  local file_path
  file_path=$1

  if [[ -e $file_path ]]; then
    print -r  "File already exists: ${(qqq)file_path}" >&2
    return 1
  fi
}

require_exists() {
  local pathh
  pathh=$1

  if [[ ! -e $pathh ]]; then
    print -r "No such file or directory: ${(qqq)pathh}" >&2
    return 1
  fi
}

require_exists_taggable() {
  local file_path
  file_path=$1

  require_exists $file_path

  if [[ ! -f $file_path ]]; then
    print -r  "Not a regular file: ${(qqq)file_path}" >&2
    return 1
  fi
}

require_well_formed() {
  unsetopt warn_create_global warn_nested_var

  local file_path
  file_path=$1

  if [[ ! $file_path =~ $well_formed_file_name_maybe_tag_group_regex ]]; then
    print -r "Ill-formed file name: ${(qqq)file_path}" >&2
    return 1
  fi
}

# List taggable files in the given paths
tss_file_list() {
  local paths
  paths=("$@")
  if [[ $#paths -eq 0 ]]; then
    paths=(*)
  fi

  local pathh location
  for pathh in "${paths[@]}"; do
    require_exists $pathh

    if [[ -d $pathh ]]; then
      if location=$(tss_location_of $pathh); then
        tss_location_index_files $location --path $pathh
      else
        print -lr $pathh/**/*(.)
      fi
    else
      print -r $pathh
    fi
  done
}

# Prints the tags for the given file, or an empty string if the file has no tags
tss_file_tags() {
  local file_path
  file_path=$1

  local tags
  tags=($(basename $file_path | sed -En "s/$file_name_maybe_tag_group_regex/\3/p"))
  print -r "${tags[@]}"
}

tss_file() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    list)
      tss_file_list "$@"
      ;;
    tags)
      tss_file_tags "$@"
      ;;
    location)
      tss_location_of "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
