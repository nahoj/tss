tss() {
  local subcommand=$1
  shift
  case $subcommand in
    add)
      tss_add "$@"
      ;;
    clean)
      tss_clean "$@"
      ;;
    dir)
      tss_dir "$@"
      ;;
    file)
      tss_file "$@"
      ;;
    filter)
      tss_filter "$@"
      ;;
    location)
      tss_location "$@"
      ;;
    remove)
      tss_remove "$@"
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
