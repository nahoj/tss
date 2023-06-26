tsp() {
  local subcommand="$1"
  shift
  case "$subcommand" in
    dir)
      tsp_dir "$@"
      ;;
    file)
      tsp_file "$@"
      ;;
    tag)
      tsp_tag "$@"
      ;;
    *)
      echo "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
