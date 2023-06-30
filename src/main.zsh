tss() {
  local subcommand=$1
  shift
  case $subcommand in
    dir)
      tss_dir "$@"
      ;;
    file)
      tss_file "$@"
      ;;
    location)
      tss_location "$@"
      ;;
    tag)
      tss_tag "$@"
      ;;
    *)
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
