
require_dir_exists() {
  local dir_path
  dir_path=$1
  if [[ ! -d "$dir_path" ]]; then
    print -r "Directory does not exist: $dir_path" >&2
    return 1
  fi
}

tss_dir_all_tags() {
  local dir_path
  dir_path=${1:-.}
  require_dir_exists "$dir_path"

  local file_path
  local -aU tags # array of unique tags
  for file_path in "$dir_path"/**/*(.); do
    tags+=($(tss_tags "$file_path"))
  done
  # print sorted tags
  print -l -- ${(in)tags}
}

tss_dir() {
  local subcommand
  subcommand=$1
  shift
  case "$subcommand" in
    all-tags)
      tss_dir_all_tags "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
