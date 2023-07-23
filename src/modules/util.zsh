
###############
# General utils
###############

logg() {
  print -r -- "tss:$@" >&2
}

failk() {
  local -i funcstack_index=$1
  shift
  logg "${funcstack[$((funcstack_index + 1))]}:$@"
  return 1
}

tss_util_failk() {
  if [[ $# -eq 0 || $1 = --help ]]; then
    failk 1 "Usage: tss util failk <funkstack_index> <message>..."
  fi
  local -i funcstack_index=$1
  shift
  failk $((funcstack_index + 3)) "$@"
}

fail() {
  failk 2 "$@"
}

# From https://stackoverflow.com/a/76516890
# Takes the names of two array variables
arrayeq() {
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
  elif [[ ${(t)${(P)1}} != ${~2} ]]; then
    failk 2 "Parameter ${(qq)1} must have type ${(qq)2}"
  fi
}

# Adapted from https://stackoverflow.com/a/76699936
is_valid_pattern() {
  setopt nullglob
  { : ${~1} } always { TRY_BLOCK_ERROR=0 } &>/dev/null
}

# Fail if any given argument is not a valid pattern
require_valid_patterns() {
  setopt nullglob
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
  local dir
  dir=$1
  shift

  local return_dir
  return_dir=$PWD

  always_with_trap_INT \
    "cd $dir; ${(j: :)${(q)@}}" \
    "cd $return_dir"
}

with_lock_file() {
  local file
  file=$1
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

internal_parse_index_mode_opt() {
  require_parameter index_mode_opt 'array*'
  require_parameter use_index 'scalar*'

  unsetopt warn_nested_var

  case ${index_mode_opt[1]:-} in
    -i|--index)
      use_index=yes
      ;;
    '')
      use_index=if-fresh
      ;;
    -I|--no-index)
      use_index=no
      ;;
    *)
      failk 2 "Invalid index-mode opt: ${index_mode_opt[1]}"
      ;;
  esac
}

internal_parse_tag_opts() {
  require_parameter tags_opts 'array*'
  require_parameter not_tags_opts 'array*'
  require_parameter not_all_tags_opts 'array*'
  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'

  unsetopt warn_nested_var

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
  local file_path
  file_path=$1

  if [[ -e $file_path ]]; then
    failk 2 "File already exists: ${(qqq)file_path}"
  fi
}

require_exists() {
  local pathh
  pathh=$1

  if [[ ! -e $pathh ]]; then
    failk 2 "No such file or directory: ${(qqq)pathh}"
  fi
}

require_directory() {
  local pathh=$1
  if [[ ! -d $pathh ]]; then
    failk 2 "Path does not exist or is not a directory: ${(qqq)pathh}"
  fi
}

require_exists_taggable() {
  local file_path
  file_path=$1

  require_exists "$file_path"

  if [[ ! -f $file_path ]]; then
    failk 2 "Not a regular file: ${(qqq)file_path}"
  fi
}

require_well_formed() {
  local file_path
  file_path=$1

  local -a match mbegin mend
  if [[ ! $file_path =~ $well_formed_file_name_maybe_tag_group_regex ]]; then
    failk 2 "Ill-formed file name: ${(qqq)file_path}"
  fi
}

require_tag_valid() {
  local tag
  tag=$1

  # if $tag contains ] or [ or etc.
  if [[ "$tag" =~ '[][/[:cntrl:][:space:]]' ]]; then
    failk 2 "Invalid tag: ${(qqqq)tag}"
  fi
}

###############
# Pattern utils
###############

tss_util_internal_file_pattern() {
  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'

  require_parameter regular_file_pattern 'scalar*'
  require_parameter accept_non_regular 'scalar*'

  unsetopt warn_nested_var

  local IFS=$'\n'

  group_with_tag() {
    local pattern
    for pattern in $@; do
      # Don't use a literal space because of this bug in _files:
      # https://www.zsh.org/mla/workers/2023/msg00667.html
      print -r -- "(*[[:space:]]|)${pattern}([[:space:]]*|)"
    done
  }

  and() {
    [[ $@ ]]
    print -r -- "(${(j:)~^(:)@})"
  }

  or() {
    [[ $@ ]]
    print -r -- "(${(j:|:)@})"
  }

  file_with_group() {
    print -r -- "*[[]${1}[]]*"
  }

  if [[ $patterns ]]; then
    regular_file_pattern=$(file_with_group "($(and $(group_with_tag $patterns)))")
    accept_non_regular=
  else
    regular_file_pattern="*"
    accept_non_regular=x
  fi
  if [[ $anti_patterns ]]; then
    regular_file_pattern+="~$(file_with_group $(or $(group_with_tag $anti_patterns)))"
  fi
  if [[ $not_all_patterns ]]; then
    regular_file_pattern+="~$(file_with_group "($(and $(group_with_tag $not_all_patterns)))")"
  fi
}

internal_file_pattern_parse_tag_opts() {
  local -aU patterns anti_patterns not_all_patterns
  internal_parse_tag_opts
  tss_util_internal_file_pattern
}


######
# Main
######

tss_util() {
  local command=$1
  shift
  case $command in
    failk)
      tss_util_failk "$@"
      ;;
    internal-file-pattern)
      tss_util_internal_file_pattern "$@"
      ;;
    is-valid-pattern)
      is_valid_pattern "$@"
      ;;
    *)
      fail "Unknown command: $command"
      ;;
  esac
}
