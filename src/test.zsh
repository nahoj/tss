tss_test() {
  local help name_only_opt tags_opts not_tags_opts not_all_tags_opts
  zparseopts -D -E -F - -help=help {n,-name-only}=name_only_opt {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts \
    -not-all-tags+:=not_all_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss test [<options>] [--] <file>

Return 0 if true, 1 if false, 2 if an error occurred.

Options:
  -n, --name-only             $label_filter_name_only_descr
  -t, --tags <pattern...>     $label_filter_tags_descr
  -T, --not-tags <pattern...> $label_filter_not_tags_descr
  --not-all-tags <pattern...> $label_filter_not_all_tags_descr
  --help                      $label_generic_help_help_descr

EOF
    return 0
  fi

  # Process options
  local -aU patterns anti_patterns not_all_patterns
  local -i i
  for ((i=2; i <= $#tags_opts; i+=2)); do
    patterns+=(${(s: :)tags_opts[i]})
  done
  for ((i=2; i <= $#not_tags_opts; i+=2)); do
    anti_patterns+=(${(s: :)not_tags_opts[i]})
  done
  for ((i=2; i <= $#not_all_tags_opts; i+=2)); do
    not_all_patterns+=(${(s: :)not_all_tags_opts[i]})
  done

  # Process positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  if [[ $# -ne 1 ]]; then
    logg "Expected exactly one positional argument, got $# instead"
    return 2
  fi
  local file_path
  file_path=$1

  internal_test
}

internal_test() {
  require_parameter name_only_opt 'array*' || return 2
  require_parameter patterns 'array*' || return 2
  require_parameter anti_patterns 'array*' || return 2
  require_parameter not_all_patterns 'array*' || return 2
  require_parameter file_path 'scalar*' || return 2

  local tags pattern tag
  tags=(${(s: :)$(internal_file_tags)}) || return 2

  for pattern in $patterns; do
    for tag in $tags; do
      if [[ $tag = ${~pattern} ]]; then
        # pattern OK
        continue 2
      fi
    done
    # file KO
    return 1
  done

  for pattern in $anti_patterns; do
    for tag in $tags; do
      if [[ $tag = ${~pattern} ]]; then
        # file KO
        return 1
      fi
    done
    # pattern OK
  done
  # file OK

  if [[ $#not_all_patterns -gt 0 ]]; then
    local -i found_unmatched_pattern=1
    for pattern in $not_all_patterns; do
      for tag in $tags; do
        if [[ $tag = ${~pattern} ]]; then
          continue 2
        fi
      done
      found_unmatched_pattern=0
      break
    done
    if [[ $found_unmatched_pattern -eq 1 ]]; then
      return 1
    fi
  fi

  return 0
}
