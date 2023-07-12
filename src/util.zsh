
###############
# General utils
###############

logg() {
  print -r -- "tss:$@" >&2
}

failk() {
  local -i funcstack_index
  funcstack_index=$1
  shift
  logg "${funcstack[$((funcstack_index + 1))]}:$@"
  return 1
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


###################
# Tag-related utils
###################

# Regex groups are:
# - before tag group
# - tag group (brackets included)
# - tag group (brackets excluded)
# - after tag group
file_name_maybe_tag_group_regex='^([^[]*)(\[([^]]*)\])?(.*)$'

well_formed_file_name_maybe_tag_group_regex='^([^][]*)(\[([^][]*)\])?([^][]*)$'

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

tss_util_file_with_not_all_tags_pattern() {
  if [[ $# -eq 0 ]]; then
    fail "Usage: tss util file-with-not-all-tags-pattern <pattern>..."
  fi
  local patterns=($@)

  local p allowed_file_patterns=()
  for p in $patterns; do
    if [[ $p = *[[:space:]]* ]]; then
      fail "Invalid pattern (contains whitespace): ${(qqqq)p}"
    fi
    allowed_file_patterns+=("^(*[[](* |)($p)( *|)[]]*)")
  done
  print -r "(${(j:|:)allowed_file_patterns})(.)"
}

tss_util_file_with_tag_pattern() {
  if [[ $# -ne 1 ]]; then
    fail "Usage: tss util file-with-tag-pattern <pattern>"
  fi
  local p
  p=$1
  if [[ $p = *[[:space:]]* ]]; then
    fail "Invalid pattern (contains whitespace); please provide a pattern for a single tag."
  fi

  print -r "*[[](* |)($p)( *|)[]]*(.)"
}

tss_util() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    file-with-not-all-tags-pattern)
      tss_util_file_with_not_all_tags_pattern "$@"
      ;;
    file-with-tag-pattern)
      tss_util_file_with_tag_pattern "$@"
      ;;
    *)
      fail "Unknown subcommand: $subcommand"
      ;;
  esac
}
