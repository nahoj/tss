setopt err_return local_loops local_options no_unset pipe_fail typeset_silent warn_create_global warn_nested_var

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
  eval "${(q)@[@]}" >/dev/null
  echo $?
}
