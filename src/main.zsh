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
    files|query)
      tss_files "$@"
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
    tags)
      tss_tags "$@"
      ;;
    test)
      tss_test "$@"
      ;;
    util)
      tss_util "$@"
      ;;
    *)
      fail "Unknown subcommand: $subcommand"
      ;;
  esac
}
