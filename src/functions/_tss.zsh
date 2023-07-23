#compdef tss

# Description: Zsh completion script for the 'tss' command

###############
# General utils
###############

_tss_comp_raw_values() {
  local desc=$1
  shift
  (( $# )) || return 1

  local value values=()
  for value in "$@"; do
    values+=($(tss comp escape-value "$value"))
  done

  unsetopt -m $tss_comp_shell_option_patterns
  if [[ $sep ]]; then
    _values -s "$sep" "$desc" $values
  else
    _values "$desc" $values
  fi
}

_tss_comp_raw_values_sep() {
  local sep=$1
  shift
  _tss_comp_raw_values "$@"
}

####################
# File and tag utils
####################

_tss_comp_internal_get_tags() {
  tss comp require-parameter paths 'array*'
  tss comp require-parameter tags 'array*'
  # plus standard completion parameters

  # Prepare all parameters for 'tss internal-tags'
  local -a patterns anti_patterns not_all_patterns
  tss comp internal-parse-patterns-opt-args

  local regular_file_pattern accept_non_regular
  tss util internal-file-pattern

  local -r not_matching_pattern="(${(j:|:)patterns}|${(j:|:)anti_patterns})"

  tss internal-tags
}

_tss_comp_internal_files() {
  tss comp require-parameter patterns 'array*'
  tss comp require-parameter anti_patterns 'array*'
  tss comp require-parameter not_all_patterns 'array*'

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

  local files=(${~dir_pattern}${~regular_file_pattern}(.))
  if [[ $accept_non_regular ]]; then
    files+=(${~dir_pattern}*(^.))
  fi

  unsetopt -m $tss_comp_shell_option_patterns
  _multi_parts -f - / files
}

################
# Query commands
################

_tss_files() {
  files() {
    local -a patterns anti_patterns not_all_patterns
    tss comp internal-parse-patterns-opt-args
    _tss_comp_internal_files
  }

  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             "*--not-all-tags[$(tss label files_not_all_tags_descr)]:patterns:->not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label files_not_tags_descr)]:patterns:->not-tags" \
             '*'{-t,--tags}"[$(tss label files_tags_descr)]:patterns:->yes-tags" \
             '*:file:files' # let _arguments handle status != 0 on an option

  setopt -m tss_comp_shell_option_patterns

  case "$state" in
    *-tags)
      # If no path is (yet) known, list all tags in the current directory's location, if it is in one
      local -r paths=(${(Q)line[@]:-.})
      local -a tags
      _tss_comp_internal_get_tags
      _tss_comp_raw_values_sep ' ' "tag" $tags
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
             "*--not-matching[$(tss label tags_not_matching_descr)]:patterns:->not-matching-tags" \
             "*--on-files-with-not-all-tags[$(tss label tags_on_files_with_not_all_tags_descr)]:patterns:->not-all-tags" \
             "*--on-files-without-tags[$(tss label tags_on_files_without_tags_descr)]:patterns:->not-tags" \
             "*--on-files-with-tags[$(tss label tags_on_files_with_tags_descr)]:patterns:->yes-tags" \
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
            local -ar patterns anti_patterns not_all_patterns
            local -r not_matching_pattern=
            tss internal-tags
            ;;
          *)
            () {
              # Define fake opt_args for _tss_comp_internal_get_tags
              local tags=${opt_args[--on-files-with-tags]:-}
              local not_tags=${opt_args[--on-files-without-tags]:-}
              local not_all_tags=${opt_args[--on-files-with-not-all-tags]:-}
              local -Ar opt_args=(
                [--tags]="$tags"
                [--not-tags]="$not_tags"
                [--not-all-tags]="$not_all_tags"
              )
              _tss_comp_internal_get_tags
            }
            ;;
        esac
        )})

      _tss_comp_raw_values_sep ' ' "tag" $tags
      ;;
  esac
}

_tss_test_tags() {
  local location
  location=$(tss location of .)
  local -r paths=(${location:-.})
  local -r name_only=
  local tags
  tags=(${(s: :)$(_tss_comp_internal_get_tags)})
  _tss_comp_raw_values_sep ' ' "tag" $tags
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
    _tss_comp_internal_files
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
      _tss_comp_raw_values_sep ' ' "tag" $tags
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
    _tss_comp_internal_files
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
      _tss_comp_raw_values_sep ' ' "tag" $tags
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

#######
# Misc.
#######

_tss_comp() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "(-): :->cmds" \
             "*::arg:->args"

  case "$state" in
    cmds)
      _values "tss-comp command" \
              "escape-value" \
              "internal-parse-patterns-opt-args" \
              "require-parameter" \
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

_tss_label() {
  setopt -m $tss_comp_shell_option_patterns
  _tss_comp_raw_values "label" "list" "${(f)$(tss label list)}"
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
      # Omits comp and label because there's no practical use for them
      _values "tss command" \
              "add[$(tss label add_descr)]" \
              "clean[$(tss label clean_descr)]" \
              "files[$(tss label files_descr)]" \
              "filter[$(tss label filter_descr)]" \
              "internal-files[See 'files'.]" \
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
        comp)
          _tss_comp
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
