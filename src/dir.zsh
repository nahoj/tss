
require_dir_exists() {
  local dir_path
  dir_path=$1
  if [[ ! -d "$dir_path" ]]; then
    print -r "Directory does not exist: $dir_path" >&2
    return 1
  fi
}

tsp_dir_all_tags() {
  local dir_path
  dir_path=${1:-.}
  require_dir_exists "$dir_path"

  local file_path
  local -aU tags # array of unique tags
  for file_path in "$dir_path"/**/*(^/); do
    tags+=($(tsp_file_tags "$file_path"))
  done
  # print sorted tags
  print -l ${(in)tags}
}

tsp_dir() {
  local subcommand
  subcommand=$1
  shift
  case "$subcommand" in
    all-tags)
      tsp_dir_all_tags "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
