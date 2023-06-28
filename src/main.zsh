tsp() {
  local subcommand=$1
  shift
  case $subcommand in
    dir)
      tsp_dir "$@"
      ;;
    file)
      tsp_file "$@"
      ;;
    location)
      tsp_location "$@"
      ;;
    tag)
      tsp_tag "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
