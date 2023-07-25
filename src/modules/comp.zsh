tss_comp_log() {
  if [[ ${TSS_DEBUG:-} ]]; then
    print -r -- "$@" >>tss-debug.log
  fi
}

tss_comp_logl() {
  if [[ ${TSS_DEBUG:-} ]]; then
    print -rl -- "$@" >>tss-debug.log
  fi
}

tss_comp_require_parameter() {
  if [[ ${TSS_DEBUG:-} ]]; then
    if [[ ! -v $1 ]]; then
      failk 4 "Parameter ${(qq)1} must be set"
    elif [[ ${(t)${(P)1}} != ${~2} ]]; then
      failk 4 "Parameter ${(qq)1} must have type ${(qq)2}"
    fi
  fi
}

# Write in $paths all file paths starting with $prefix and matching any of the given relative path patterns
tss_comp_rec_glob_prefix() {
  local prefix=$1
  local rel_path_patterns=($@[2,-1])

  unsetopt warn_nested_var
  tss_comp_require_parameter paths 'array*'

  local prefix_dir_part=${prefix%%[^/]#}  # $prefix up to last '/' included, if any

  paths=()
  local rel_path_pattern sibling_paths
  for rel_path_pattern in $rel_path_patterns; do
    if [[ $prefix != (*/|) ]]; then
      # Siblings paths of $prefix that match $rel_path_pattern, possibly including $prefix itself
      sibling_paths=($prefix_dir_part${~rel_path_pattern})
      # Those of them that start with $prefix
      paths+=(${(M)sibling_paths:#$prefix*})
    fi

    # Paths strictly under $prefix_dir_part that match $rel_path_pattern
    paths+=($prefix_dir_part**/${~rel_path_pattern})
  done
}

# Escape special characters in a raw string to give to _values
tss_comp_escape_value() {
  local c
  for c in ${(s::)1}; do
    case $c in
      [][\(\)*:\\+-])
        print -nr -- "\\$c"
        ;;
      *)
        print -nr -- $c
    esac
  done
}

# Parse one opt_args value (which may itself contain several option values)
parse_one_patterns_opt_args() {
  local opt_args_value=$1
  local current_word=$2

  # Split on unquoted ':' and unquote (_arguments quoting)
  local -a patterns_args
  IFS=':' read -A patterns_args <<<$opt_args_value

  if [[ $current_word ]]; then
    # Drop current word (one instance only) if present
    local -i i=$patterns_args[(Ie)$current_word]
    if (( i )); then
      patterns_args[$i]=()
    fi
  fi

  local -aU result
  local pattern
  # Unquote again (user input quoting) and split on ' '
  for pattern in ${(@s: :)${(@Q)patterns_args}}; do
    if tss util is-valid-pattern $pattern; then
      result+=($pattern)
    fi
  done

  print -r -- $result
}

tss_comp_internal_parse_patterns_opt_args() {
  tss_comp_require_parameter opt_canonical_name 'scalar*'

  unsetopt warn_nested_var

  local args

  if [[ -v 'opt_args[-t]' || -v 'opt_args[--tags]' || -v 'opt_args[--on-files-with-tags]' ]]; then
    tss_comp_require_parameter patterns 'array*'

    args=${opt_args[-t]:-}:${opt_args[--tags]:-}:${opt_args[--on-files-with-tags]:-}
    patterns=(${(s: :)$(
      if [[ $opt_canonical_name = --tags ]]; then
        parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
      else
        parse_one_patterns_opt_args "$args" ''
      fi
    )})
  fi

  if [[ -v 'opt_args[-T]' || -v 'opt_args[--not-tags]' || -v 'opt_args[--on-files-without-tags]' ]]; then
    tss_comp_require_parameter anti_patterns 'array*'

    args=${opt_args[-T]:-}:${opt_args[--not-tags]:-}:${opt_args[--on-files-without-tags]:-}
    anti_patterns=(${(s: :)$(
      if [[ $opt_canonical_name = --not-tags ]]; then
        parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
      else
        parse_one_patterns_opt_args "$args" ''
      fi
    )})
  fi

  if [[ -v 'opt_args[--not-all-tags]' || -v 'opt_args[--on-files-with-not-all-tags]' ]]; then
    tss_comp_require_parameter not_all_patterns 'array*'

    args=${opt_args[--not-all-tags]:-}:${opt_args[--on-files-with-not-all-tags]:-}
    not_all_patterns=(${(s: :)$(
      if [[ $opt_canonical_name = --not-all-tags ]]; then
        parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
      else
        parse_one_patterns_opt_args "$args" ''
      fi
    )})
  fi

  if [[ -v 'opt_args[--not-matching]' ]]; then
    tss_comp_require_parameter not_matching_patterns 'array*'

    args=${opt_args[--not-matching]:-}
    not_all_patterns=(${(s: :)$(
      if [[ $opt_canonical_name = --not-matching ]]; then
        parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
      else
        parse_one_patterns_opt_args "$args" ''
      fi
    )})
  fi
}

tss_comp() {
  local command=$1
  shift
  case $command in
    escape-value)
      tss_comp_escape_value "$@"
      ;;
    internal-parse-patterns-opt-args)
      tss_comp_internal_parse_patterns_opt_args "$@"
      ;;
    log)
      tss_comp_log "$@"
      ;;
    logl)
      tss_comp_logl "$@"
      ;;
    rec-glob-prefix)
      tss_comp_rec_glob_prefix "$@"
      ;;
    require-parameter)
      tss_comp_require_parameter "$@"
      ;;
    *)
      fail "Unknown command: $command"
      ;;
  esac
}
