
###############
# General utils
###############

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
    print -r "Usage: require_parameter <caller_function_name> <parameter_name> <type_pattern>" >&2
    return 1
  fi

  if [[ ! -v $2 ]]; then
    print -r -- "$1: Parameter ${(qq)2} must be set" >&2
    return 1
  elif [[ ${(t)${(P)2}} != ${~3} ]]; then
    print -r -- "$1: Parameter ${(qq)2} must have type ${(qq)3}" >&2
    return 1
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
    print -r "File is locked: ${(qqq)file}" >&2
    return 1
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
    print -r  "File already exists: ${(qqq)file_path}" >&2
    return 1
  fi
}

require_exists() {
  local pathh
  pathh=$1

  if [[ ! -e $pathh ]]; then
    print -r "No such file or directory: ${(qqq)pathh}" >&2
    return 1
  fi
}

require_exists_taggable() {
  local file_path
  file_path=$1

  require_exists $file_path

  if [[ ! -f $file_path ]]; then
    print -r  "Not a regular file: ${(qqq)file_path}" >&2
    return 1
  fi
}

require_well_formed() {
  unsetopt warn_create_global warn_nested_var

  local file_path
  file_path=$1

  if [[ ! $file_path =~ $well_formed_file_name_maybe_tag_group_regex ]]; then
    print -r "Ill-formed file name: ${(qqq)file_path}" >&2
    return 1
  fi
}

require_tag_valid() {
  local tag
  tag=$1

  # if $tag contains ] or [ or etc.
  if [[ "$tag" =~ '[][/[:cntrl:][:space:]]' ]]; then
    print -r "Invalid tag: ${(qqq)tag}" >&2
    return 1
  fi
}

tss_util_file_with_tag_pattern() {
  if [[ $# -gt 1 ]]; then
    print -r "Only one positional argument expected" >&2
    return 1
  fi
  local p
  p=$1
  if [[ $p = *[[:space:]]* ]]; then
    print -r "Invalid pattern (contains whitespace); please provide a pattern for a single tag." >&2
    return 1
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
      print -r "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
