
require_is_location() {
  local location
  location=$1
  if [[ ! -f "$location/.ts/tsi.json" ]]; then
    print -r "Not a location: ${(qqq)location}" >&2
    return 1
  fi
}

tss_location_all_tags() {
  local pathh
  pathh=${1:-.}

  local location index
  location=$(tss_location_of $pathh)
  index="$location/.ts/tsi.json"

  # if index is > 20 minutes old, refresh it
  if [[ ! -f $index || $(zstat +mtime $index) -lt $(($(date +%s) - 1200)) ]]; then
    tss_location_index_build $location
  fi

  tss_location_index_all_tags $location
}

# Return the given dir if it is a location, or its closest ancestor that is a location,
# or the empty string if there is none
tss_location_of_dir_unsafe() {
  local dir
  dir=$1

  if [[ -f "$dir/.ts/tsi.json" ]]; then
    print -r $dir
  else
    if [[ $dir == "/" ]]; then
      print
    else
      tss_location_of_dir_unsafe $(dirname $dir)
    fi
  fi
}

tss_location_of() {
  local pathh
  pathh=$1
  require_file_exists $pathh

  if [[ -d $pathh ]]; then
    tss_location_of_dir_unsafe $(realpath -s $pathh)
  else
    tss_location_of_dir_unsafe $(dirname $(realpath -s $pathh))
  fi
}

tss_location() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    all-tags)
      tss_location_all_tags "$@"
      ;;
    index)
      tss_location_index "$@"
      ;;
    of)
      tss_location_of "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
