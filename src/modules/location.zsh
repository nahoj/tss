
require_is_location() {
  local location=$1
  if [[ ! -f "$location/.ts/tsi.json" ]]; then
    failk 2 "Not a location: ${(qqq)location}"
  fi
}

tss_location_init() {
  local help
  zparseopts -D -E -F - -help=help

  if [[ $help ]]; then
    cat <<EOF

Usage: tss location init [<path>]

Make the given directory a location. If no path is given, the current \
directory is assumed.

EOF
    return 0
  fi

  local location=${1:-.}
  require_directory "$location"
  if [[ -f "$location/.ts/tsi.json" ]]; then
    fail "Already a location: ${(qqq)location}"
  fi
  if ! type jq >/dev/null; then
    fail "Using locations requires [jq](https://jqlang.github.io/jq/)."
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
  local help
  zparseopts -D -E -F - -help=help

  if [[ $help ]]; then
    cat <<EOF

Usage: tss location of [<path>]

Print the location under which the given file or directory is, if \
any. If no path is given, the current directory is assumed.

Returns 1 if the given path is not under a location.

EOF
    return 0
  fi

  local pathh=${1:-.}
  require_exists "$pathh"

  local abs_dir_path
  if [[ -d $pathh ]]; then
    abs_dir_path=${pathh:a}
  else
    abs_dir_path=${pathh:a:h}
  fi
  tss_location_of_dir_unsafe "$abs_dir_path"
}

tss_location_remove() {
  local help
  zparseopts -D -E -F - -help=help

  if [[ $help ]]; then
    cat <<EOF

Usage: tss location remove [<path>]

Make the given directory no longer a location. If no path is given, \
the current directory is assumed.

EOF
    return 0
  fi

  local location=${1:-.}
  require_is_location "$location"
  rm -rf "$location/.ts"
  logg "${(q-)location} is no longer a location."
}

tss_location() {
  local help
  zparseopts -D -F - -help=help

  if [[ $# -eq 0 || -n $help ]]; then
    cat <<EOF

Usage: tss location <command> [--help] [<parameters>]

A location is a directory where you keep tagged files. Any directory \
can be made a location. Declaring locations is not necessary to use \
tss, but doing so will get you better completion for some commands:

When working under a location, tss can suggest tags from the whole \
location instead of just the working directory.

During completion, when relevant, tss will use the location of the \
first path given on the command line, or of the current directory if \
none is given.

Commands:
  index         $label_location_index_descr
  init          $label_location_init_descr
  of            $label_location_of_descr
  remove        $label_location_remove_descr

Add --help to a command to show its help message.

EOF
    return 0
  fi

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
    remove)
      tss_location_remove "$@"
      ;;
    *)
      log "Unknown command: $command"
      return 1
      ;;
  esac
}
