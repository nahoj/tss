setopt -m err_return 'local*' no_unset pipe_fail typeset_silent 'warn*'

zmodload -F zsh/stat b:zstat

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
  trap "cd ${(q)return_dir}" EXIT INT

  $@
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
  trap "rm -f ${(q)lock_file}" EXIT INT

  $@
}
