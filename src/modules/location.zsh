
require_is_location() {
  local location
  location=$1
  if [[ ! -f "$location/.ts/tsi.json" ]]; then
    failk 2 "Not a location: ${(qqq)location}"
  fi
}

# Return the given dir if it is a location, or its closest ancestor that is a location,
# or the empty string if there is none
tss_location_of_dir_unsafe() {
  local dir
  dir=$1

  if [[ -f "$dir/.ts/tsi.json" ]]; then
    print -r -- "$dir"
  else
    if [[ $dir == "/" ]]; then
      return 1
    else
      tss_location_of_dir_unsafe "${dir:h}"
    fi
  fi
}

tss_location_of() {
  local pathh
  pathh=$1
  require_exists "$pathh"

  local abs_dir_path
  if [[ -d $pathh ]]; then
    abs_dir_path=${pathh:a}
  else
    abs_dir_path=${pathh:a:h}
  fi
  tss_location_of_dir_unsafe "$abs_dir_path"
}

tss_location_tags() {
  local pathh=${1:-.}

  local location
  location=$(tss_location_of "$pathh")

  if ! tss_location_index_is_fresh "$location"; then
    tss_location_index_build "$location"
  fi

  tss_location_index_tags "$location"
}

tss_location() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    index)
      tss_location_index "$@"
      ;;
    of)
      tss_location_of "$@"
      ;;
    tags)
      tss_location_tags "$@"
      ;;
    *)
      log "Unknown subcommand: $subcommand"
      return 1
      ;;
  esac
}
