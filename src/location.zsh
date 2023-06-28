
require_is_location() {
  local location
  location=$1
  if [[ ! -f "$location/.ts/tsi.json" ]]; then
    print -r "Not a location: ${(qqq)location}" >&2
    return 1
  fi
}

tsp_location_all_tags() {
  local pathh
  if [[ -n $1 ]]; then
    pathh=$1
    require_path_exists $pathh
  else
    pathh=.
  fi

  local location index
  location=$(tsp_location_of_dir_unsafe .)
  if [[ -z $location ]]; then
    print "Not in a location" >&2
    return 1
  fi
  index="$location/.ts/tsi.json"

  # Get sorted, unique tags
  jq -r '[.[].tags | .[].title] | unique | .[]' $index
}

# Return the given dir if it is a location, or its closest ancestor that is a location,
# or the empty string if there is none
tsp_location_of_dir_unsafe() {
  local dir
  dir=$1

  if [[ -f "$dir/.ts/tsi.json" ]]; then
    print -r $dir
  else
    if [[ $dir == "/" ]]; then
      print
    else
      tsp_location_of_dir_unsafe $(dirname $dir)
    fi
  fi
}

tsp_location_of() {
  local pathh
  pathh=$1
  require_file_exists $pathh

  if [[ -d $pathh ]]; then
    tsp_location_of_dir_unsafe $(realpath -s $pathh)
  else
    tsp_location_of_dir_unsafe $(dirname $(realpath -s $pathh))
  fi
}

tsp_location() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    all-tags)
      tsp_location_all_tags "$@"
      ;;
    build-index)
      tsp_location_build_index "$@"
      ;;
    of)
      tsp_location_of "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
