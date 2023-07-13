tss_tags() {
  local help name_only_opt stdin_opt
  zparseopts -D -E -F - -help=help {n,-name-only}=name_only_opt -stdin=stdin_opt

  if [[ -n $help ]]; then
    cat <<EOF

Usage:          tss tags [<options>] [--] <path>...
(in particular) tss tags [<options>] [--] <file>

Print all tags found on files in the given paths and/or files listed on stdin.

Options:
  -n, --name-only       Use only the given file names; assume each path is a taggable file.
                        In particular, this precludes browsing directories.
  --stdin               $label_tags_stdin_descr
  --help                $label_generic_help_help_descr

EOF
    return 0
  fi

  # Process options
  local name_only=$name_only_opt

  # Process positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  local arg_paths
  if [[ $# -eq 0 && -z $stdin_opt ]]; then
    arg_paths=(*(N))
  else
    arg_paths=($@)
  fi

  local -aU tags
  local file_path

  if [[ $#arg_paths -gt 0 ]]; then
    if [[ $name_only ]]; then
      # TODO browse dirs
      for file_path in $arg_paths; do
        tags+=(${(s: :)$(internal_file_tags)})
      done

    else
      tss_files -- "$arg_paths[@]" | () {
        # Always name-only when using the output of tss_files
        unsetopt warn_nested_var
        local -r name_only=x
        while read -r file_path; do
          tags+=(${(s: :)$(internal_file_tags)})
        done
      } || return $?
    fi
  fi

  if [[ -n $stdin_opt ]]; then
    while read -r file_path; do
      tags+=(${(s: :)$(internal_file_tags)})
    done
  fi

  print -r -- ${(in)tags}
}

internal_file_tags() {
  require_parameter name_only 'scalar*'
  require_parameter file_path 'scalar*'

  if [[ ! $name_only ]]; then
    require_exists "$file_path"
    if [[ ! -f $file_path ]]; then
      return 0
    fi
  elif [[ -z $file_path ]]; then
    fail 'Invalid path: ""'
  fi

  local -a match mbegin mend
  [[ ${file_path:t} =~ $file_name_maybe_tag_group_regex ]]
  print -r -- "$match[3]"
}
