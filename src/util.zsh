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

tss_util_file_with_tag_pattern() {
  local p
  p=$1
  if [[ $p = *[[:space:]]* ]]; then
    print -r "Invalid pattern (contains whitespace); please provide a pattern for a single tag." >&2
    return 1
  fi

  print -r "*[[](($p)|($p)[:space:]*|*[:space:]($p)|*[:space:]($p)[:space:]*)[]]*(.)"
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

  touch $lock_file
  {
    $@
  } always {
    rm -f $lock_file
  }
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
