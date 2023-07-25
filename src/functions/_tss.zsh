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
    _values ${compadd_opts:-} -s "$sep" "$desc" $values
  else
    _values ${compadd_opts:-} "$desc" $values
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

_tss_comp_internal_files() {
  tss comp require-parameter patterns 'array*'
  tss comp require-parameter anti_patterns 'array*'
  tss comp require-parameter not_all_patterns 'array*'

  local regular_file_pattern accept_non_regular
  tss util internal-file-pattern

  local file_patterns=("$regular_file_pattern(.)")
  if [[ $accept_non_regular ]]; then
    file_patterns+=("*(^.)")
  fi

  local -a paths
  tss comp rec-glob-prefix "${(Q)words[$CURRENT]}" $file_patterns

  unsetopt -m $tss_comp_shell_option_patterns
  _multi_parts ${compadd_opts:-} -f - / paths
}

_tss_comp_tags() {
  _tss_comp_raw_values_sep ' ' "tags" $@
}

_tss_comp_internal_all_tags() {
  tss comp require-parameter paths 'array*'
  tss comp require-parameter not_matching_patterns 'array*'

  # Get location tags, if we're in a location
  local -a paths=(${paths:-.})
  local location
  local -aU tags
  if location=$(tss location of "$paths[1]"); then
    tss location index internal-tags "$location" || true
  else
    local -r regular_file_pattern='*'
    tss internal-tags || true
  fi

  # Get common tags from environment variables (arrays whose name starts with 'tss_tags_')
  local param
  for param in ${(o)parameters[(I)tss_tags_*]}; do
    if [[ ${(Pt)param} = array* ]]; then
      tags+=(${(P)param})
    fi
  done

  _tss_comp_tags ${tags:#${~:-(${(j:|:)not_matching_patterns})}}
}

# Complete with tags found on files
_tss_comp_internal_file_tags() {
  tss comp require-parameter paths 'array*'
  tss comp require-parameter patterns 'array*'
  tss comp require-parameter anti_patterns 'array*'
  tss comp require-parameter not_all_patterns 'array*'
  tss comp require-parameter not_matching_patterns 'array*'

  local regular_file_pattern accept_non_regular
  tss util internal-file-pattern

  local -r quiet=x
  local -a tags
  tss internal-tags || true

  _tss_comp_tags $tags
}


################
# Query commands
################

# Complete files for _tss_files and _tss_tags
_tss_files_tags_files() {
  setopt -m tss_comp_shell_option_patterns

  local compadd_opts=($@)

  local -r opt_canonical_name=
  local -a patterns anti_patterns not_all_patterns
  local -a not_matching_patterns
  tss comp internal-parse-patterns-opt-args
  unset not_matching_patterns

  _tss_comp_internal_files
}

# Complete tags for _tss_files and _tss_tags
_tss_files_tags_tags() {
  setopt -m tss_comp_shell_option_patterns

  local compadd_opts=($@[1,-2])
  local opt_canonical_name=$@[-1]

  case $opt_canonical_name in
    --tags|--not-tags|--not-all-tags)
      local paths=(${(Q)line[@]})

      local -a patterns anti_patterns not_all_patterns
      local -a not_matching_patterns # Value set by 'tss comp internal-parse-patterns-opt-args' ignored
      tss comp internal-parse-patterns-opt-args
      not_matching_patterns=($patterns $anti_patterns)

      if [[ $paths || $patterns || $anti_patterns || $not_all_patterns ]]; then
        paths=(${paths:-.})
        _tss_comp_internal_file_tags
      else
        _tss_comp_internal_all_tags
      fi
      ;;

    --not-matching)
      # Simplistic completion for the time being
      local paths=(${(Q)line[@]})
      local -r not_matching_patterns=()
      _tss_comp_internal_all_tags
      ;;

    *)
      tss comp log "Unknown option name: $opt_canonical_name"
      return 1
  esac
}

_tss_files() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             "*--not-all-tags[$(tss label files_not_all_tags_descr)]:patterns:_tss_files_tags_tags --not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label files_not_tags_descr)]:patterns:_tss_files_tags_tags --not-tags" \
             '*'{-t,--tags}"[$(tss label files_tags_descr)]:patterns:_tss_files_tags_tags --tags" \
             '*:file:_tss_files_tags_files' # let _arguments handle status != 0 on an option
}

_tss_filter() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label filter_name_only_descr)]" \
             "*--not-all-tags[$(tss label filter_not_all_tags_descr)]:patterns:_tss_test_tags --not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label filter_not_tags_descr)]:patterns:_tss_test_tags --not-tags" \
             '*'{-t,--tags}"[$(tss label filter_tags_descr)]:patterns:_tss_test_tags --tags" \
}

_tss_tags() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             "-l[$(tss label tags_l_descr)]" \
             "*--not-matching[$(tss label tags_not_matching_descr)]:patterns:_tss_files_tags_tags --not-matching" \
             "*--on-files-with-not-all-tags[$(tss label tags_on_files_with_not_all_tags_descr)]:patterns:_tss_files_tags_tags --not-all-tags" \
             "*--on-files-without-tags[$(tss label tags_on_files_without_tags_descr)]:patterns:_tss_files_tags_tags --not-tags" \
             "*--on-files-with-tags[$(tss label tags_on_files_with_tags_descr)]:patterns:_tss_files_tags_tags --tags" \
             '*:file:_tss_files_tags_files' # let _arguments handle status != 0 on an option
}

# Also used in _tss_filter
_tss_test_tags() {
  setopt -m tss_comp_shell_option_patterns

  local compadd_opts=($@[1,-2])
  local opt_canonical_name=$@[-1]

  local -a patterns anti_patterns not_all_patterns
  tss comp internal-parse-patterns-opt-args
  local -r not_matching_patterns=($patterns $anti_patterns)

  local -r paths=(${$(tss location of ${(Q)line[1]:-.}):-.})

  if [[ $patterns || $anti_patterns || $not_all_patterns ]]; then
    _tss_comp_internal_file_tags
  else
    _tss_comp_internal_all_tags
  fi
}

_tss_test() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label test_name_only_descr)]" \
             "*--not-all-tags[$(tss label test_not_all_tags_descr)]:patterns:_tss_test_tags --not-all-tags" \
             '*'{-T,--not-tags}"[$(tss label test_not_tags_descr)]:patterns:_tss_test_tags --not-tags" \
             '*'{-t,--tags}"[$(tss label test_tags_descr)]:patterns:_tss_test_tags --tags" \
             ':file:_files'
}


###############
# Edit commands
###############

_tss_add() {
  # Get tags from options and first positional argument
  internal_get_arg_tags() {
    tss comp require-parameter opt_canonical_name 'scalar*'

    unsetopt warn_nested_var
    tss comp require-parameter arg_tags 'array*'

    local -a patterns
    tss comp internal-parse-patterns-opt-args
    arg_tags=($patterns ${(s: :)${(Q)line[1]:-}})
  }

  files() {
    setopt -m $tss_comp_shell_option_patterns

    local compadd_opts=($@)

    local -r opt_canonical_name=
    local -aU arg_tags
    internal_get_arg_tags

    # Offer files that don't have all the tags
    local -r patterns=() anti_patterns=() not_all_patterns=(${(b)arg_tags[@]})
    _tss_comp_internal_files
  }

  tags() {
    setopt -m $tss_comp_shell_option_patterns

    local compadd_opts=($@[1,-2])
    local opt_canonical_name=$@[-1]

    local -aU arg_tags
    internal_get_arg_tags

    local -r paths=(${(Q)line[2,-1]})
    # Exclude tags already given
    local -aU not_matching_patterns=(${(b)arg_tags[@]})
    # Exclude tags that are on all of the files
    if [[ $paths ]]; then
      not_matching_patterns+=($(tss util tag-on-all-files-pattern $paths))
    fi
    _tss_comp_internal_all_tags
  }

  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-t,--tags}"[$(tss label add_tags_descr)]:tags:tags --tags" \
             ':tags:tags ""' \
             '*:file:files' # let _arguments handle status != 0 on an option
}

_tss_clean() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "*:file:_path_files -g '**/*[[]*[]]*(.)'" # Regular files with a tag group
}

_tss_remove() {
  # Get patterns from options and first positional argument
  internal_get_arg_patterns() {
    tss comp require-parameter opt_canonical_name 'scalar*'

    unsetopt warn_nested_var
    tss comp require-parameter arg_patterns 'array*'

    local -a patterns
    tss comp internal-parse-patterns-opt-args
    arg_patterns=($patterns ${(s: :)${(Q)line[1]:-}})
  }

  # Offer files that have any tag matching any of the given patterns, or all files if no pattern is given
  files() {
    setopt -m $tss_comp_shell_option_patterns

    local compadd_opts=($@)

    local -r opt_canonical_name=
    local -aU arg_patterns
    internal_get_arg_patterns

    if [[ $arg_patterns ]]; then
      local -r patterns=("((${(j:|:)arg_patterns}))")
    else
      local -r patterns=()
    fi
    local -r anti_patterns=() not_all_patterns=()
    _tss_comp_internal_files
  }

  # Offer tags not matched by the already-given patterns
  tags() {
    setopt -m $tss_comp_shell_option_patterns

    local compadd_opts=($@[1,-2])
    local opt_canonical_name=${@[-1]}

    local -aU arg_patterns
    internal_get_arg_patterns
    local -r not_matching_patterns=($arg_patterns)

    local paths=(${(Q)line[2,-1]})
    if [[ $paths ]]; then
      local -r patterns=() anti_patterns=() not_all_patterns=()
      _tss_comp_internal_file_tags

    else
      _tss_comp_internal_all_tags
    fi
  }

  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-t,--tags}"[$(tss label remove_tags_descr)]:patterns:tags --tags" \
             ':patterns:tags ""' \
             '*:file:files' # let _arguments handle status != 0 on an option
}


####################
# Location and index
####################

# Complete location paths
_tss_comp_locations() {
  setopt -m $tss_comp_shell_option_patterns
  local compadd_opts=($@)

  # Get paths of indexes
  local -a paths
  tss comp rec-glob-prefix "${(Q)words[$CURRENT]}" '.ts/tsi.json'

  local locations=(${${paths%/.ts/tsi.json}:/.ts\/tsi.json/.})

  unsetopt -m $tss_comp_shell_option_patterns
  _multi_parts ${compadd_opts:-} -f - / locations
}

_tss_location_index_build() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             ':location:_tss_comp_locations'
}

_tss_location_index_tags() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             ':location:_tss_comp_locations'
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
              "internal-tags[See tags.]" \
              "is-fresh" \
              "tags[List all tags that appear in the index]" \
      ;;
    args)
      case ${(Q)line[1]} in
        build)
          _tss_location_index_build
          ;;
        internal-*)
          return 1
          ;;
        is-fresh)
          return 1
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

_tss_location_remove() {
  local curcontext=$curcontext state state_descr line
  local -A opt_args
  _arguments -s -C -S : \
             ':location:_tss_comp_locations'
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
              "index[$(tss label location_index_descr)]" \
              "init[$(tss label location_init_descr)]" \
              "of[$(tss label location_of_descr)]" \
              "remove[$(tss label location_remove_descr)]" \
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
        remove)
          _tss_location_remove
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
              "log" \
              "logl" \
              "rec-glob-prefix" \
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
              "tag-on-all-files-pattern" \
      ;;
    args)
      case ${(Q)line[1]} in
        tag-on-all-files-pattern)
          _files
          ;;
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

  local log=(tss comp log) logl=(tss comp logl)

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
