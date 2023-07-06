
###############
# General utils
###############

logg() {
  print -r -- "tss:$@" >&2
}

fail() {
  logg "$@"
  return 1
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
  if [[ $# -ne 3 ]]; then
    fail "Usage: require_parameter <caller_function_name> <parameter_name> <type_pattern>"
  fi

  if [[ ! -v $2 ]]; then
    fail "$1: Parameter ${(qq)2} must be set"
  elif [[ ${(t)${(P)2}} != ${~3} ]]; then
    fail "$1: Parameter ${(qq)2} must have type ${(qq)3}"
  fi
}

# Evaluate the given arguments as a command and print the exit status
status() {
  unsetopt err_exit err_return
  $@ >/dev/null
  print $?
}

with_cd() {
  local dir
  dir=$1
  shift

  local return_dir
  return_dir=$PWD

  cd $dir
  {
    $@
  } always {
    cd $return_dir
  }
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

  # FIXME doesn't remove $lock_file in case of ^C
  touch $lock_file
  {
    $@
  } always {
    rm -f $lock_file
  }
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
    fail "File already exists: ${(qqq)file_path}"
  fi
}

require_exists() {
  local pathh
  pathh=$1

  if [[ ! -e $pathh ]]; then
    fail "No such file or directory: ${(qqq)pathh}"
  fi
}

require_exists_taggable() {
  local file_path
  file_path=$1

  require_exists $file_path

  if [[ ! -f $file_path ]]; then
    fail "Not a regular file: ${(qqq)file_path}"
  fi
}

require_well_formed() {
  unsetopt warn_create_global warn_nested_var

  local file_path
  file_path=$1

  if [[ ! $file_path =~ $well_formed_file_name_maybe_tag_group_regex ]]; then
    fail "Ill-formed file name: ${(qqq)file_path}"
  fi
}

require_tag_valid() {
  local tag
  tag=$1

  # if $tag contains ] or [ or etc.
  if [[ "$tag" =~ '[][/[:cntrl:][:space:]]' ]]; then
    fail "Invalid tag: ${(qqq)tag}"
  fi
}

tss_util_file_with_tag_pattern() {
  if [[ $# -gt 1 ]]; then
    fail "Only one positional argument expected"
  fi
  local p
  p=$1
  if [[ $p = *[[:space:]]* ]]; then
    fail "Invalid pattern (contains whitespace); please provide a pattern for a single tag."
  fi

  print -r "*[[](($p)|($p)[:space:]*|*[:space:]($p)|*[:space:]($p)[:space:]*)[]]*(.)"
}

tss_util() {
  local subcommand
  subcommand=$1
  shift
  case "$subcommand" in
    file-with-tag-pattern)
      tss_util_file_with_tag_pattern "$@"
      ;;
    *)
      fail "Unknown subcommand: $subcommand"
      ;;
  esac
}
