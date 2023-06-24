tsp() {
  local subcommand="$1"
  shift
  case "$subcommand" in
    file)
      tsp_file "$@"
      ;;
    tag)
      tsp_tag "$@"
      ;;
    *)
      echo "Unknown subcommand: $subcommand"
      return 1
      ;;
  esac
}
