#compdef tss

# Description: Zsh completion script for the 'tss' command

###############
# General utils
###############

_tss_comp_log() {
  if [[ ${TSS_DEBUG:-} ]]; then
    print -r -- "$@" >>tss-comp.log
  fi
}

_tss_comp_logl() {
  if [[ ${TSS_DEBUG:-} ]]; then
    print -rl -- "$@" >>tss-comp.log
  fi
}

_tss_comp_require_parameter() {
  if [[ ${TSS_DEBUG:-} ]]; then
    if [[ ! -v $1 ]]; then
      tss util failk 4 "Parameter ${(qq)1} must be set"
    elif [[ ${(t)${(P)1}} != ${~2} ]]; then
      tss util failk 4 "Parameter ${(qq)1} must have type ${(qq)2}"
    fi
  fi
}

# Escape special characters in a raw string to give to _values
_tss_comp_escape_value() {
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

_tss_comp_escape_values() {
  local value
  for value in "$@"; do
    _tss_comp_escape_value "$value"
    print
  done
}


####################
# File and tag utils
####################

_tss_internal_comp_parse_index_mode() {
  _tss_comp_require_parameter use_index 'scalar*'

  # Get the last index-mode option before the current word, if any
  local index_mode_opt=${${(Q)words[1,$CURRENT]}[(R)(-i|--index|-I|--no-index)]}
  if [[ index_mode_opt = (-I|--no-index) ]]; then
    use_index=no
  else
    use_index=yes
  fi
}

_tss_comp_parse_one_patterns_opt_args() {
  local opt_args=$1
  local current_word=$2

  # Split on unquoted ':' and unquote (_arguments quoting)
  local -a patterns_args
  IFS=':' read -A patterns_args <<<$opt_args

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

_tss_internal_comp_parse_all_patterns_opt_args() {
  _tss_comp_require_parameter patterns 'array*'
  _tss_comp_require_parameter anti_patterns 'array*'
  _tss_comp_require_parameter not_all_patterns 'array*'

  local args
  patterns=(${(s: :)$(
    args=${opt_args[-t]:-}:${opt_args[--tags]:-}
    if [[ $state = yes-tags ]]; then
      _tss_comp_parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
    else
      _tss_comp_parse_one_patterns_opt_args "$args" ''
    fi
  )})
  anti_patterns=(${(s: :)$(
    args=${opt_args[-T]:-}:${opt_args[--not-tags]:-}
    if [[ $state = not-tags ]]; then
      _tss_comp_parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
    else
      _tss_comp_parse_one_patterns_opt_args "$args" ''
    fi
  )})
  not_all_patterns=(${(s: :)$(
    args=${opt_args[--not-all-tags]:-}
    if [[ $state = not-all-tags ]]; then
      _tss_comp_parse_one_patterns_opt_args "$args" "$words[$CURRENT]"
    else
      _tss_comp_parse_one_patterns_opt_args "$args" ''
    fi
  )})
}

_tss_internal_comp_get_tags() {
  _tss_comp_require_parameter location 'scalar*'
  _tss_comp_require_parameter paths 'array*'
  _tss_comp_require_parameter name_only 'scalar*'
  # plus standard completion parameters

  # Prepare all parameters for 'tss internal-tags'
  local use_index
  _tss_internal_comp_parse_index_mode

  local -a patterns anti_patterns not_all_patterns
  _tss_internal_comp_parse_all_patterns_opt_args
  local regular_file_pattern accept_non_regular
  tss util internal-file-pattern
  local -r not_matching_pattern="(${(j:|:)patterns}|${(j:|:)anti_patterns})"

  local -r stdin=
  tss internal-tags
}

_tss_internal_comp_files() {
  _tss_comp_require_parameter patterns 'array*'
  _tss_comp_require_parameter anti_patterns 'array*'
  _tss_comp_require_parameter not_all_patterns 'array*'

  local dir_pattern
  if [[ ${(Q)words[$CURRENT]} != */* ]]; then
    dir_pattern="**/"
  elif [[ ${(Q)words[$CURRENT]} = */ ]]; then
    dir_pattern="${(Q)words[$CURRENT]}**/"
  else
    dir_pattern="${${(Q)words[$CURRENT]}:h}/**/"
  fi

  local regular_file_pattern accept_non_regular
  tss util internal-file-pattern

  # (null_glob is in effect)
  local files=(${~dir_pattern}${~regular_file_pattern}(.))
  if [[ $accept_non_regular ]]; then
    files+=(${~dir_pattern}*(^.))
  fi
  _tss_comp_logl files_head: $files[1,10]

  unsetopt -m $tss_comp_shell_option_patterns
#    local expl
#    _wanted files expl 'files'
  _multi_parts -f - / files
}

################
# Query commands
################

_tss_files() {
  files() {
    local -a patterns anti_patterns not_all_patterns
    _tss_internal_comp_parse_all_patterns_opt_args
    _tss_internal_comp_files
  }

  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "-C[$(tss label generic_C_descr)]" \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-i,--index}"[$(tss label files_index_descr)]" \
             {-I,--no-index}"[$(tss label files_no_index_descr)]" \
             "*--not-all-tags[$(tss label files_not_all_tags_descr)]:patterns:->not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label files_not_tags_descr)]:patterns:->not-tags" \
             '*'{-t,--tags}"[$(tss label files_tags_descr)]:patterns:->yes-tags" \
             '*:file:files' # let _arguments handle status != 0 on an option

  setopt -m tss_comp_shell_option_patterns

  case "$state" in
    *-tags)
      local location
      location=$(tss location of ${(Q)line[1]:-.})
      # If no path is (yet) known, list all tags in the current directory's location, if it is in one
      local -r paths=(${(Q)line[@]:-${location:-.}})
      local -r name_only=
      local tags
      tags=(${(s: :)$(_tss_internal_comp_get_tags)})
      if [[ $tags ]]; then
        local values
        values=(${(f)$(_tss_comp_escape_values $tags)})
        unsetopt -m $tss_comp_shell_option_patterns
        _values -s ' ' "tag" $values
      else
        return 1
      fi
      ;;
  esac
}

_tss_filter() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label filter_name_only_descr)]" \
             "*--not-all-tags[$(tss label filter_not_all_tags_descr)]:patterns:->not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label filter_not_tags_descr)]:patterns:->not-tags" \
             '*'{-t,--tags}"[$(tss label filter_tags_descr)]:patterns:->yes-tags" \

  setopt -m tss_comp_shell_option_patterns

  case "$state" in
    *-tags)
      _tss_test_tags
      ;;
  esac
}

_tss_tags() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-i,--index}"[$(tss label tags_index_descr)]" \
             {-I,--no-index}"[$(tss label tags_no_index_descr)]" \
             {-n,--name-only}"[$(tss label tags_name_only_descr)]" \
             "*--not-matching[$(tss label tags_not_matching_descr)]:patterns:->not-matching-tags" \
             "*--on-files-with-not-all-tags[$(tss label tags_on_files_with_not_all_tags_descr)]:patterns:->not-all-tags" \
             "*--on-files-without-tags[$(tss label tags_on_files_without_tags_descr)]:patterns:->not-tags" \
             "*--on-files-with-tags[$(tss label tags_on_files_with_tags_descr)]:patterns:->yes-tags" \
             "--stdin[$(tss label tags_stdin_descr)]" \
             '*:file:_files' \

  setopt -m tss_comp_shell_option_patterns

  case "$state" in
    *-tags)
      local location
      location=$(tss location of ${(Q)line[1]:-.})
      # If no path is (yet) known, list all tags in the current directory's location, if it is in one
      local -r paths=(${(Q)line[@]:-${location:-.}})
      local -r name_only=

      local tags
      tags=(${(s: :)$(
        case "$state" in
          not-matching-tags)
            local use_index
            _tss_internal_comp_parse_index_mode
            local -ar patterns anti_patterns not_all_patterns
            local -r not_matching_pattern= stdin=
            tss internal-tags
            ;;
          *)
            () {
              # Define fake opt_args for _tss_internal_comp_get_tags
              local tags=${opt_args[--on-files-with-tags]:-}
              local not_tags=${opt_args[--on-files-without-tags]:-}
              local not_all_tags=${opt_args[--on-files-with-not-all-tags]:-}
              local -Ar opt_args=(
                [--tags]="$tags"
                [--not-tags]="$not_tags"
                [--not-all-tags]="$not_all_tags"
              )
              _tss_internal_comp_get_tags
            }
            ;;
        esac
        )})

      if [[ $tags ]]; then
        local values
        values=(${(f)$(_tss_comp_escape_values $tags)})
        unsetopt -m $tss_comp_shell_option_patterns
        _values -s ' ' "tag" $values
      else
        return 1
      fi
      ;;
  esac
}

_tss_test_tags() {
  local location
  location=$(tss location of .)
  local -r paths=(${location:-.})
  local -r name_only=
  local tags
  tags=(${(s: :)$(_tss_internal_comp_get_tags)})
  if [[ $tags ]]; then
    local values
    values=(${(f)$(_tss_comp_escape_values $tags)})
    unsetopt -m $tss_comp_shell_option_patterns
    _values -s ' ' "tag" $values
  else
    return 1
  fi
}

_tss_test() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label test_name_only_descr)]" \
             "*--not-all-tags[$(tss label test_not_all_tags_descr)]:patterns:->not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label test_not_tags_descr)]:patterns:->not-tags" \
             '*'{-t,--tags}"[$(tss label test_tags_descr)]:patterns:->yes-tags" \
             ':file:_files'

  setopt -m tss_comp_shell_option_patterns

  case "$state" in
    *-tags)
      _tss_test_tags
      ;;
  esac
}


###############
# Edit commands
###############

_tss_add() {
  files() {
    # Offer files that don't have all the tags
    local -aU tags=(${(s: :)${(Q)line[1]}})
    local patterns=() anti_patterns=()
    local not_all_patterns(${(b)tags[@]})
    _tss_internal_comp_files
  }

  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "-C[$(tss label generic_C_descr)]" \
             ':tags:->tags' \
             '*:file:files' # let _arguments handle status != 0 on an option

  setopt -m $tss_comp_shell_option_patterns

  case "$state" in
    tags)
      # One or more tags separated by spaces
      local location
      local -aU tags
      if location=$(tss location of .); then
        tags=(${(s: :)$(tss location index tags "$location")})
      else
        # All tags in the current directory
        local f
        for f in *(.N); do
          tags+=(${(s: :)$(tss tags "$f")})
        done
      fi
      if [[ $tags ]]; then
        local values
        values=(${(f)$(_tss_comp_escape_values $tags)})
        unsetopt -m $tss_comp_shell_option_patterns
        _values -s ' ' "tag" $values
      else
        return 1
      fi
      ;;
  esac
}

# tss clean takes one or more files as positional arguments
_tss_clean() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             '*::file:->files'

  case "$state" in
    files)
      # Regular files with a tag group
      _path_files -g '**/*[[]*[]]*(.)'
      ;;
  esac
}

_tss_remove() {
  files() {
    # Offer files that have any tag matching any of the given patterns
    local -aU arg_patterns=(${(s: :)${(Q)line[1]}})
    local -r patterns=("((${(j:|:)arg_patterns}))")
    local -r anti_patterns=() not_all_patterns=()
    _tss_internal_comp_files
  }

  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "-C[$(tss label generic_C_descr)]" \
             ':patterns:->tags' \
             '*:file:files' # let _arguments handle status != 0 on an option

  setopt -m $tss_comp_shell_option_patterns

  case "$state" in
    tags)
      # One or more tag patterns separated by spaces; we offer existing tags
      local location
      local -aU tags
      if location=$(tss location of .); then
        tags=(${(s: :)$(tss location index tags "$location")})
      else
        # All tags in the current directory
        local f
        for f in *(.N); do
          tags+=(${(s: :)$(tss tags "$f")})
        done
      fi
      if [[ $tags ]]; then
        local values
        values=(${(f)$(_tss_comp_escape_values $tags)})
        unsetopt -m $tss_comp_shell_option_patterns
        _values -s ' ' "tag" $values
      else
        return 1
      fi
      ;;
  esac
}


####################
# Location and index
####################

_tss_location_index_tags() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             ':location:_files -/'
}

_tss_location_index_build() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             ':location:_files -/'
}

_tss_location_index() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             "(-): :->cmds" \
             "*::arg:->args"

  case "$state" in
    cmds)
      _values "tss-location-index command" \
              "build[Build index]" \
              "tags[List all tags that appear in the index]" \
      ;;
    args)
      case ${(Q)line[1]} in
        build)
          _tss_location_index_build
          ;;
        tags)
          _tss_location_index_tags
          ;;
      esac
      ;;
  esac
}

_tss_location_init() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             ':location:_files -/'
}

_tss_location_of() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             ':file:_files'
}

_tss_location() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             "(-): :->cmds" \
             "*::arg:->args"

  case "$state" in
    cmds)
      _values "tss-location command" \
              "init[Initialize a location]" \
              "index[TODO descr]" \
              "of[Print the TagSpaces location of the given path, or an empty string]" \
      ;;
    args)
      case ${(Q)line[1]} in
        index)
          _tss_location_index
          ;;
        init)
          _tss_location_init
          ;;
        of)
          _tss_location_of
          ;;
      esac
      ;;
  esac
}

_tss_label() {
  setopt -m $tss_comp_shell_option_patterns
  local values
  values=(${(f)$(_tss_comp_escape_values 'list' ${(f)$(tss label list)})})
  unsetopt -m $tss_comp_shell_option_patterns
  _values "label" $values
}

_tss_util() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             "(-): :->cmds" \
             "*::arg:->args"

  case "$state" in
    cmds)
      _values "tss-util command" \
              "failk" \
              "internal-file-pattern" \
              "is-valid-pattern" \
      ;;
    args)
      case ${(Q)line[1]} in
        *)
          return 1
          ;;
      esac
      ;;
  esac
}

_tss() {
  # Throughout the completion functions, we set the following options in custom
  # code and unset them when calling functions from the completion system. As
  # such, this should only contain options that are not set by default during
  # completion.
  # Note: local_options is set by default during completion.
  local tss_comp_shell_option_patterns=(err_return pipe_fail)
  if [[ ${TSS_DEBUG:-} ]]; then
    tss_comp_shell_option_patterns+=(local_loops no_unset 'warn*')
  fi

  local IFS=

  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             "(-): :->cmds" \
             "*::arg:->args"

  case "$state" in
    cmds)
      # Omits 'label' because there's no practical use for it
      _values "tss command" \
              "add[$(tss label add_descr)]" \
              "clean[$(tss label clean_descr)]" \
              "files[$(tss label files_descr)]" \
              "filter[$(tss label filter_descr)]" \
              "internal-tags[See 'tags'.]" \
              "location[$(tss label location_descr)]" \
              "query[$(tss label query_descr)]" \
              "remove[$(tss label remove_descr)]" \
              "tags[$(tss label tags_descr)]" \
              "test[$(tss label test_descr)]" \
              "util[$(tss label util_descr)]" \
      ;;
    args)
      case ${(Q)line[1]} in
        add)
          _tss_add
          ;;
        clean)
          _tss_clean
          ;;
        files|query)
          _tss_files
          ;;
        filter)
          _tss_filter
          ;;
        internal-*)
          return 1
          ;;
        label)
          _tss_label
          ;;
        location)
          _tss_location
          ;;
        remove)
          _tss_remove
          ;;
        tags)
          _tss_tags
          ;;
        test)
          _tss_test
          ;;
        util)
          _tss_util
          ;;
      esac
      ;;
  esac
}

_tss "$@"
