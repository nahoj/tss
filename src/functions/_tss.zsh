#compdef tss

# Description: Zsh completion script for the 'tss' command

_tss_comp_shell_options=(err_return local_loops local_options local_patterns local_traps no_unset pipe_fail)

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
escape_value() {
  setopt $_tss_comp_shell_options
  for c in ${(s::)1}; do
    case $c in
      [][:\\+-])
        print -nr -- "\\$c"
        ;;
      *)
        print -nr -- $c
    esac
  done
}


##################
# Edit subcommands
##################

_tss_add() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
    tags)
      # One or more tags separated by spaces
      local location
      local -aU tags
      if location=$(tss location of .); then
        tags=($(tss location index tags "$location"))
      else
        # All tags in the current directory
        for f in *(.N); do
          tags+=($(tss tags "$f"))
        done
      fi
      if [[ $#tags -ne 0 ]]; then
        _values -s ' ' "tag" "${tags[@]}"
      fi
      ;;

    files)
      local -aU tags=(${(s: :)${(Q)line[1]}})
      local patterns=(${(b)tags[@]})

      # Offer files that don't have the tags
      local location
      if location=$(tss location of .); then
        local -a files
        files=("${(@f)"$( \
          tss location index files "$location" --path-starts-with "${(Q)line[$CURRENT]}" \
            --not-all-tags "${(j: :)patterns}" \
          )"}")
        _multi_parts -f - / files

      else
        local file_pattern=$(tss util file-with-not-all-tags-pattern $patterns)
        # There seems to be bugs in _files -g
        _path_files -g "**/$file_pattern"
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
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
    tags)
      # One or more tag patterns separated by spaces; we offer existing tags
      local location
      local -aU tags
      if location=$(tss location of .); then
        tags=($(tss location index all-tags "$location"))
      else
        # All tags in the current directory
        for f in *(.N); do
          tags+=($(tss tags "$f"))
        done
      fi
      if [[ $#tags -ne 0 ]]; then
        _values -s ' ' "tag" "${tags[@]}"
      fi
      ;;

    files)
      # Offer files that have any tag matching any of the given patterns
      local -aU patterns
      patterns=(${(s: :)${(Q)line[1]}})
      local filter_pattern="(${(j:|:)patterns})"

      local location
      if location=$(tss location of .); then
        local -a files
        files=("${(@f)"$( \
          tss location index files "$location" --path-starts-with "${(Q)line[$CURRENT]}" -t "$filter_pattern" \
          )"}")
        _multi_parts -f - / files

      else
        local file_pattern=$(tss util file-with-tag-pattern "$filter_pattern")
        _path_files -g "**/$file_pattern"
      fi
      ;;
  esac
}


###################
# Query subcommands
###################

_tss_comp_parse_patterns_opt_args() {
  setopt $_tss_comp_shell_options

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

_tss_comp_internal_get_tags() {
  setopt $_tss_comp_shell_options

  _tss_comp_require_parameter state 'array*'
  _tss_comp_require_parameter location 'scalar*'
  _tss_comp_require_parameter paths 'array*'
  _tss_comp_require_parameter name_only 'scalar*'

  # Prepare all parameters for 'tss internal-tags'
  local patterns anti_patterns not_all_patterns args
  patterns=(${(s: :)$(
    args=${opt_args[-t]:-}:${opt_args[--tags]:-}
    if [[ $state = yes-tags ]]; then
      _tss_comp_parse_patterns_opt_args "$args" "$words[$CURRENT]"
    else
      _tss_comp_parse_patterns_opt_args "$args" ''
    fi
  )})
  anti_patterns=(${(s: :)$(
    args=${opt_args[-T]:-}:${opt_args[--not-tags]:-}
    if [[ $state = not-tags ]]; then
      _tss_comp_parse_patterns_opt_args "$args" "$words[$CURRENT]"
    else
      _tss_comp_parse_patterns_opt_args "$args" ''
    fi
  )})
  not_all_patterns=(${(s: :)$(
    args=${opt_args[--not-all-tags]:-}
    if [[ $state = not-all-tags ]]; then
      _tss_comp_parse_patterns_opt_args "$args" "$words[$CURRENT]"
    else
      _tss_comp_parse_patterns_opt_args "$args" ''
    fi
  )})

  local -r not_matching_pattern="(${(j:|:)patterns}|${(j:|:)anti_patterns})"

  local -r stdin=
  tss internal-tags
}

_tss_files() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-I,--no-index}"[$(tss label files_no_index_descr)]" \
             "--not-all-tags[$(tss label files_not_all_tags_descr)]:patterns:->not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label files_not_tags_descr)]:patterns:->not-tags" \
             '*'{-t,--tags}"[$(tss label files_tags_descr)]:patterns:->yes-tags" \
             '*:file:_files' \

  case "$state" in
    *-tags)
      local location
      location=$(tss location of ${(Q)line[1]:-.})
      # If no path is (yet) known, list all tags in the current directory's location, if it is in one
      local -r paths=(${(Q)line[@]:-${location:-.}})
      local -r name_only=
      local tags
      tags=($(_tss_comp_internal_get_tags)) || return $?
      [[ $#tags -ne 0 ]] || return 1
      _values -s ' ' "tag" $tags
      ;;
  esac
}

_tss_filter() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label filter_name_only_descr)]" \
             "--not-all-tags[$(tss label filter_not_all_tags_descr)]:patterns:->not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label filter_not_tags_descr)]:patterns:->not-tags" \
             '*'{-t,--tags}"[$(tss label filter_tags_descr)]:patterns:->yes-tags" \

  case "$state" in
    *-tags)
      local location
      location=$(tss location of .)
      local -r paths=(${location:-.})
      local -r name_only=
      local tags
      tags=($(_tss_comp_internal_get_tags)) || return $?
      [[ $#tags -ne 0 ]] || return 1
      _values -s ' ' "tag" $tags
      ;;
  esac
}

_tss_tags() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label tags_name_only_descr)]" \
             "--stdin[$(tss label tags_stdin_descr)]" \
             '1:file:_files'
}

_tss_test() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label test_name_only_descr)]" \
             "--not-all-tags[$(tss label test_not_all_tags_descr)]:patterns:->not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label test_not_tags_descr)]:patterns:->not-tags" \
             '*'{-t,--tags}"[$(tss label test_tags_descr)]:patterns:->yes-tags" \
             '1:file:_files'

  case "$state" in
    *-tags)
      local location
      location=$(tss location of .)
      local -r paths=(${location:-.})
      local -r name_only=
      local tags
      tags=($(_tss_comp_internal_get_tags)) || return $?
      [[ $#tags -ne 0 ]] || return 1
      _values -s ' ' "tag" $tags
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
             '1:location:_files'
}

_tss_location_index_build() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             '1:location:_files -/'
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

_tss_location_of() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args

  _arguments -s -C -S : \
             '1:file:_files'
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
              "index[TODO descr]" \
              "of[Print the TagSpaces location of the given path, or an empty string]" \
      ;;
    args)
      case ${(Q)line[1]} in
        index)
          _tss_location_index
          ;;
        of)
          _tss_location_of
          ;;
      esac
      ;;
  esac
}

_tss_label() {
  local line state

  _values "label" 'list' $(tss label list)
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
              "file-with-not-all-tags-pattern[Output a glob pattern matching any file whose tags don't match all the fiven patterns]" \
              "file-with-tag-pattern[Output a glob pattern matching any file with a tag matching the given pattern]" \
      ;;
    args)
      case ${(Q)line[1]} in
        file-with-tag-pattern)
          ;;
      esac
      ;;
  esac
}

_tss() {
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
