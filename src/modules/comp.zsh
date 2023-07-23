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
  tss_comp_require_parameter patterns 'array*'
  tss_comp_require_parameter anti_patterns 'array*'
  tss_comp_require_parameter not_all_patterns 'array*'

  unsetopt warn_nested_var

  local args
  patterns=(${(s: :)$(
    args=${opt_args[-t]:-}:${opt_args[--tags]:-}
    if [[ $state = yes-tags ]]; then
      parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
    else
      parse_one_patterns_opt_args "$args" ''
    fi
  )})
  anti_patterns=(${(s: :)$(
    args=${opt_args[-T]:-}:${opt_args[--not-tags]:-}
    if [[ $state = not-tags ]]; then
      parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
    else
      parse_one_patterns_opt_args "$args" ''
    fi
  )})
  not_all_patterns=(${(s: :)$(
    args=${opt_args[--not-all-tags]:-}
    if [[ $state = not-all-tags ]]; then
      parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
    else
      parse_one_patterns_opt_args "$args" ''
    fi
  )})
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
    require-parameter)
      tss_comp_require_parameter "$@"
      ;;
    *)
      fail "Unknown command: $command"
      ;;
  esac
}
