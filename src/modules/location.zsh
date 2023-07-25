
require_is_location() {
  local location=$1
  if [[ ! -f "$location/.ts/tsi.json" ]]; then
    failk 2 "Not a location: ${(qqq)location}"
  fi
}

tss_location_init() {
  local location=${1:-.}
  require_directory "$location"
  if [[ -f "$location/.ts/tsi.json" ]]; then
    fail "Already a location: ${(qqq)location}"
  fi
  mkdir -p "$location/.ts"
  print -r '[]' >"$location/.ts/tsi.json"
  tss_location_index_build "$location"
}

# Return the given dir if it is a location, or its closest ancestor that is a location,
# or the empty string if there is none
tss_location_of_dir_unsafe() {
  local dir=$1

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
  local pathh=$1
  require_exists "$pathh"

  local abs_dir_path
  if [[ -d $pathh ]]; then
    abs_dir_path=${pathh:a}
  else
    abs_dir_path=${pathh:a:h}
  fi
  tss_location_of_dir_unsafe "$abs_dir_path"
}

tss_location() {
  local command=$1
  shift
  case $command in
    index)
      tss_location_index "$@"
      ;;
    init)
      tss_location_init "$@"
      ;;
    of)
      tss_location_of "$@"
      ;;
    *)
      log "Unknown command: $command"
      return 1
      ;;
  esac
}
