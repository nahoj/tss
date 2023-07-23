tss() {
  if [[ ! -v TSS_PATH ]]; then
    # Must match the value in Makefile
    local TSS_PATH=$HOME/.local/share/tss
  fi

  # Robustness settings
  emulate -LR zsh
  setopt err_return local_loops no_unset pipe_fail
  setopt -m 'warn*'
  # We suffix each pipeline with '|| return $?' because of this bug in
  # combining err_return with pipe_fail in zsh <= 5.9:
  # https://www.zsh.org/mla/workers/2023/msg00633.html
  local IFS=

  # Other options
  setopt extended_glob null_glob

  zmodload -F zsh/stat b:zstat

  local module
  for module in $TSS_PATH/*.zsh; do
    . $module
  done

  local help
  zparseopts -D -F - -help=help

  if [[ $# -eq 0 || -n $help ]]; then
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
  comp             $label_comp_descr
  internal-files   See 'files'.
  internal-tags    See 'tags'.
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
    comp)
      tss_comp "$@"
      ;;
    files|query)
      tss_files "$@"
      ;;
    filter)
      tss_filter "$@"
      ;;
    internal-files)
      tss_internal_files "$@"
      ;;
    internal-tags)
      tss_internal_tags "$@"
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
