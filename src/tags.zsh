tss_tags() {
  local help name_only_opt
  zparseopts -D -E -F - -help=help {n,-name-only}=name_only_opt

  if [[ -n $help ]]; then
    cat <<EOF >&2

Usage: tss tags [options] <file>

Print the tags for the given file, or an empty string if the file has no tags.

Options:
  -n, --name-only Use only the file's name, don't check whether the file exists and is a taggable file
  --help          Show this help message

EOF
    return 0
  fi

  if [[ $# -ne 1 ]]; then
    print -r "Expected exactly one positional argument, got $# instead" >&2
    return 1
  fi
  local file_path
  file_path=$1

  internal_tags
}

internal_tags() {
  unsetopt warn_create_global warn_nested_var

  require_parameter internal_tags name_only_opt 'array*'
  require_parameter internal_tags file_path 'scalar*'

  if [[ -z $name_only_opt ]]; then
    require_exists $file_path
    if [[ ! -f $file_path ]]; then
      return 0
    fi
  fi

  [[ ${file_path:t} =~ $file_name_maybe_tag_group_regex ]]
  print -r -- $match[3]
}
