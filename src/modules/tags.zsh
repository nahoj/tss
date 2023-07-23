tss_tags() {
  local help index_mode_opt name_only_opt not_matching_opts tags_opts not_tags_opts not_all_tags_opts stdin_opt
  zparseopts -D -E -F - -help=help {i,-index,I,-no-index}=index_mode_opt {n,-name-only}=name_only_opt \
    -not-matching+:=not_matching_opts \
    -on-files-with-tags+:=tags_opts -on-files-without-tags+:=not_tags_opts \
    -on-files-with-not-all-tags+:=not_all_tags_opts -stdin=stdin_opt

  if [[ -n $help ]]; then
    cat <<EOF

Usage:          tss tags [<options>] [--] [<path>...]
(in particular) tss tags [<options>] [--] <file>

Print tags found on files in the given path(s) and/or files listed on stdin.

Options:
  -i, --index                               $label_tags_index_descr
  -I, --no-index                            $label_tags_no_index_descr
  -n, --name-only                           Use only the given file names; assume each path is a taggable file.
                                            In particular, this precludes browsing directories.
  --not-matching <pattern...>               $label_tags_not_matching_descr
  --on-files-with-tags <pattern...>         $label_tags_on_files_with_tags_descr
  --on-files-without-tags <pattern...>      $label_tags_on_files_without_tags_descr
  --on-files-with-not-all-tags <pattern...> $label_tags_on_files_with_not_all_tags_descr
  --stdin                                   $label_tags_stdin_descr
  --help                                    $label_generic_help_help_descr

EOF
    return 0
  fi

  # Process options
  local name_only=$name_only_opt
  local stdin=$stdin_opt

  local use_index
  internal_parse_index_mode_opt

  local -aU not_matching_patterns
  local -i i
  for ((i=2; i <= $#not_matching_opts; i+=2)); do
    not_matching_patterns+=(${(s: :)not_matching_opts[i]})
  done
  require_valid_patterns $not_matching_patterns
  local not_matching_pattern="((${(j:|:)not_matching_patterns}))"

  local regular_file_pattern accept_non_regular
  internal_file_pattern_parse_tag_opts

  # Process positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  local paths=() location
  if [[ $# -gt 0 ]]; then
    paths=($@)
    location=$(tss_location_of "$1") || true
  elif [[ ! $stdin ]]; then
    paths=(*(N))
    location=$(tss_location_of .) || true
  fi

  internal_tags
}

internal_tags() {
  require_parameter location 'scalar*'
  require_parameter use_index 'scalar*'
  require_parameter paths 'array*'
  require_parameter stdin 'scalar*'

  require_parameter name_only 'scalar*'
  require_parameter regular_file_pattern 'scalar*'
  require_parameter accept_non_regular 'scalar*'

  require_parameter not_matching_pattern 'scalar*'

  local -aU file_tags
  local file_path

  if [[ $#paths -gt 0 ]]; then
    if [[ $name_only ]]; then
      for file_path in $paths; do
        if internal_test; then
          file_tags+=(${(s: :)$(internal_file_tags)})
        fi
      done

    else
      internal_files | () {
        # Always name-only when using the output of internal_files
        unsetopt warn_nested_var
        local -r name_only=x
        while read -r file_path; do
          file_tags+=(${(s: :)$(internal_file_tags)})
        done
      } || return $?
    fi
  fi

  if [[ $stdin ]]; then
    internal_filter | () {
      # Always name-only when using the output of internal_filter
      unsetopt warn_nested_var
      local -r name_only=x
      while read -r file_path; do
        file_tags+=(${(s: :)$(internal_file_tags)})
      done
    } || return $?
  fi

  local result=() tag
  for tag in $file_tags; do
    if [[ $tag != ${~not_matching_pattern} ]]; then
      result+=($tag)
    fi
  done
  print -r -- ${(in)result}
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
