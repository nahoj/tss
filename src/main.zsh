tss() {
  local help
  zparseopts -D -F - -help=help

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss <command> [--help] [<parameters>]

A command-line tool to manage TagSpaces-style tags on files.
Home page: https://github.com/nahoj/tss

Commands:
  add              $label_add_descr
  clean            $label_clean_descr
  files, query     $label_files_descr
  filter           $label_filter_descr
  location         $label_location_descr
  remove           $label_remove_descr
  tags             $label_tags_descr
  test             $label_test_descr

Internal commands:
  label            $label_label_descr
  util             $label_util_descr

Add --help to a command to show its help message.

EOF
    return 0
  fi

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
    label)
      tss_label "$@"
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
