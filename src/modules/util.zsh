
###############
# General utils
###############

logkq() {
  local -i k=$1
  shift
  if [[ ${quiet:-} ]]; then
    if [[ ${TSS_DEBUG:-} ]]; then
      print -r -- "tss:${funcstack[k+1]}:$@" >>tss-debug.log
    fi
  else
    print -r -- "tss:${funcstack[k+1]}:$@" >&2
  fi
}

logk() {
  local -i k=$1
  shift
  local -r quiet=
  logkq $((k + 1)) "$@"
}

logg() {
  logk 2 "$@"
}

failk() {
  if [[ $# -eq 0 ]]; then
    failk 2 "Usage: failk <funcstack_index> <message>..."
  fi
  local -i k=$1
  shift
  logk $((k + 1)) "$@"
  return 1
}

fail() {
  failk 2 "$@"
}

# From https://stackoverflow.com/a/76516890
# Takes the names of two array variables
arrayeq() {
  require_parameter "$1" 'array*'
  require_parameter "$2" 'array*'

  typeset -i i len

  # The P parameter expansion flag treats the parameter as a name of a
  # variable to use
  len=${#${(P)1}}

  if [[ $len -ne ${#${(P)2}} ]]; then
     return 1
  fi

  # Remember zsh arrays are 1-indexed
  for (( i = 1; i <= $len; i++)); do
    if [[ ${(P)1[i]} != ${(P)2[i]} ]]; then
        return 1
    fi
  done
}

require_parameter() {
  if [[ $# -ne 2 ]]; then
    failk 2 "Usage: require_parameter <parameter_name> <type_pattern>"
  fi

  if [[ ! -v $1 ]]; then
    failk 2 "Parameter ${(qq)1} must be set"
  elif [[ ${(Pt)1} != ${~2} ]]; then
    failk 2 "Parameter ${(qq)1} must have type ${(qq)2}"
  fi
}

# Adapted from https://stackoverflow.com/a/76699936
is_valid_pattern() {
  { : ${~1} } always { TRY_BLOCK_ERROR=0 } &>/dev/null
}

# Fail if any given argument is not a valid pattern
require_valid_patterns() {
  { : ${~@[@]} } always { TRY_BLOCK_ERROR=0 } # Prints "bad pattern: ..." if one is.
}

# Evaluate the given arguments as a command and print the exit status
status() {
  unsetopt err_exit err_return
  $@ >/dev/null
  print $?
}

always_with_trap_INT() {
  local try_cmd=$1
  local always_cmd=$2

  local interrupted=
  local trap_cmd='unsetopt warn_nested_var; interrupted=x; return 130'
  # (the return code should never get out of the function         ^)
  {
    () {
      trap "$trap_cmd" INT
      eval "$try_cmd"
    }
  } always {
    {
      () {
        trap "$trap_cmd" INT
        eval "$always_cmd"
      }
    } always {
      if [[ $interrupted ]]; then
        kill -s INT "$$"
      fi
    }
  }
}

with_cd() {
  local dir=$1
  shift

  local return_dir
  return_dir=$PWD

  always_with_trap_INT \
    "cd $dir; ${(j: :)${(q)@}}" \
    "cd $return_dir"
}

with_lock_file() {
  local file=$1
  shift

  local lock_file
  lock_file=$file.LOCK
  if [[ -e $lock_file ]]; then
    fail "File is locked: ${(qqq)file}"
  fi

  always_with_trap_INT \
    "touch $lock_file; ${(j: :)${(q)@}}" \
    "rm -f $lock_file"
}


######################
# Command-line parsing
######################

internal_parse_tag_opts() {
  require_parameter tags_opts 'array*'
  require_parameter not_tags_opts 'array*'
  require_parameter not_all_tags_opts 'array*'

  unsetopt warn_nested_var
  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'

  local -i i
  for ((i=2; i <= $#tags_opts; i+=2)); do
    patterns+=(${(s: :)tags_opts[i]})
  done
  require_valid_patterns $patterns

  for ((i=2; i <= $#not_tags_opts; i+=2)); do
    anti_patterns+=(${(s: :)not_tags_opts[i]})
  done
  require_valid_patterns $anti_patterns

  for ((i=2; i <= $#not_all_tags_opts; i+=2)); do
    not_all_patterns+=(${(s: :)not_all_tags_opts[i]})
  done
  require_valid_patterns $not_all_patterns
}


#########################
# Misc. tag-related utils
#########################

# Regex groups are:
# - before tag group
# - tag group (brackets included)
# - tag group (brackets excluded)
# - after tag group
local file_name_maybe_tag_group_regex='^([^[]*)(\[([^]]*)\])?(.*)$'

local well_formed_file_name_maybe_tag_group_regex='^([^][]*)(\[([^][]*)\])?([^][]*)$'

require_does_not_exist() {
  local file_path=$1

  if [[ -e $file_path ]]; then
    failk 2 "File already exists: ${(qqq)file_path}"
  fi
}

require_exists_quietable() {
  local pathh=$1

  if [[ ! -e $pathh ]]; then
    logkq 2 "No such file or directory: ${(qqq)pathh}"
    return 1
  fi
}

require_exists() {
  local -r quiet=
  require_exists_quietable "$@"
}

require_directory() {
  local pathh=$1
  if [[ ! -d $pathh ]]; then
    failk 2 "Path does not exist or is not a directory: ${(qqq)pathh}"
  fi
}

require_exists_taggable() {
  local file_path=$1

  require_exists "$file_path"

  if [[ ! -f $file_path ]]; then
    failk 2 "Not a regular file: ${(qqq)file_path}"
  fi
}

require_well_formed() {
  local file_path=$1

  local -a match mbegin mend
  if [[ ! $file_path =~ $well_formed_file_name_maybe_tag_group_regex ]]; then
    failk 2 "Ill-formed file name: ${(qqq)file_path}"
  fi
}

require_tag_valid() {
  local tag=$1

  # if $tag contains ] or [ or etc.
  if [[ "$tag" =~ '[][/[:cntrl:][:space:]]' ]]; then
    failk 2 "Invalid tag: ${(qqqq)tag}"
  fi
}

###############
# Pattern utils
###############

p_map_tag_group_with_tag() {
  local pattern
  for pattern in $@; do
    # If the output is ever given to _files -g, ' ' should be replaced with [[:space:]] because of this bug:
    # https://www.zsh.org/mla/workers/2023/msg00667.html
    print -r "(* |)($pattern)( *|)"
  done
}

p_and() {
  [[ $@ ]] || failkq 1 "At least one pattern expected"
  if (( $# == 1 )); then
    print -r "(($1))"
  else
    # Don't use ~ because of this bug in zsh <= 5.9:
    # https://www.zsh.org/mla/workers/2023/msg00718.html
    print -r "(^(^(${(j:)|^(:)@})))"
  fi
}

p_or() {
  [[ $@ ]] || failkq 1 "At least one pattern expected"
  # Double ( ) to never be interpreted as a qualifier
  print -r "((${(j:|:)@}))"
}

p_map_not() {
  local pattern
  for pattern in $@; do
    print -r "(^($pattern))"
  done
}

p_file_with_tag_group() {
  print -r "*[[]($1)[]]*"
}

tss_util_internal_file_pattern() {
  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'

  unsetopt warn_nested_var
  require_parameter regular_file_pattern 'scalar*'
  require_parameter accept_non_regular 'scalar*'

  local IFS=$'\n'

  # We do something a bit more complicated than it could be, in order to simplify the patterns built when possible

  local tag_group_anti_patterns=($(p_map_tag_group_with_tag $anti_patterns))
  if [[ $not_all_patterns ]]; then
    tag_group_anti_patterns+=($(p_and $(p_map_tag_group_with_tag $not_all_patterns)))
  fi

  if [[ $patterns ]]; then
    accept_non_regular=
    # Optimize the simplest case
    if [[ $#patterns -eq 1 && ! $tag_group_anti_patterns ]]; then
      regular_file_pattern=$(p_file_with_tag_group $(p_map_tag_group_with_tag $patterns[1]))
    else
      tag_group_anti_patterns+=($(p_map_not $(p_map_tag_group_with_tag $patterns)))
      regular_file_pattern=$(p_file_with_tag_group "(^$(p_or $tag_group_anti_patterns))")
    fi

  else
    accept_non_regular=x
    if [[ $tag_group_anti_patterns ]]; then
      regular_file_pattern="(^($(p_file_with_tag_group $(p_or $tag_group_anti_patterns))))"
    else
      regular_file_pattern="*"
    fi
  fi
}

internal_file_pattern_parse_tag_opts() {
  local -aU patterns anti_patterns not_all_patterns
  internal_parse_tag_opts
  tss_util_internal_file_pattern
}

tss_util_file_pattern() {
  local -a help tags_opts not_tags_opts not_all_tags_opts
  zparseopts -D -E -F - -help=help {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts -not-all-tags+:=not_all_tags_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage: tss util file-pattern [<options>]

Options:
  -t, --tags <pattern...>       $label_filter_tags_descr
  -T, --not-tags <pattern...>   $label_filter_not_tags_descr
  --not-all-tags <pattern...>   $label_filter_not_all_tags_descr
  --help                        $label_generic_help_help_descr

EOF
    return 0
  fi

  local regular_file_pattern accept_non_regular
  internal_file_pattern_parse_tag_opts
  logg "Regular file pattern:"
  print -r -- "$regular_file_pattern"
  logg "Accept non-regular files:"
  print -r -- "$accept_non_regular"
}

# Print a pattern that matches a tag that is on all the given files
tss_utils_tag_on_all_files_pattern() {
  local file_paths=($@)

  local -aU tags
  internal_tags_on_all_files_name_only
  if [[ $tags ]]; then
    p_or $tags
  fi
}


######
# Main
######

tss_util() {
  local command=$1
  shift
  case $command in
    file-pattern)
      tss_util_file_pattern "$@"
      ;;
    internal-file-pattern)
      tss_util_internal_file_pattern "$@"
      ;;
    is-valid-pattern)
      is_valid_pattern "$@"
      ;;
    tag-on-all-files-pattern)
      tss_utils_tag_on_all_files_pattern "$@"
      ;;
    *)
      fail "Unknown command: $command"
      ;;
  esac
}
