set -euo PIPE_FAIL -o TYPESET_SILENT

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
  local i
  for (( i = 1; i <= $len; i++)); do
    if [[ ${(P)1[i]} != ${(P)2[i]} ]]; then
        return 1
    fi
  done
}

require_file_exists() {
  local file_path
  file_path=$1

  if [[ ! -f "$file_path" ]]; then
    echo "File not found: $file_path"
    return 1
  fi
}

require_file_does_not_exist() {
  local file_path
  file_path=$1

  if [[ -f "$file_path" ]]; then
    echo "File already exists: $file_path"
    return 1
  fi
}

# Regex groups are:
# - before tag group
# - tag group (brackets included)
# - tag group (brackets excluded)
# - after tag group
local file_name_maybe_tag_group_regex='^([^[]*)(\[([^]]*)\])?(.*)$'
