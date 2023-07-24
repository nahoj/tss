tss_tags() {
  local help l_opts not_matching_opts tags_opts not_tags_opts not_all_tags_opts quiet_opts
  zparseopts -D -E -F - -help=help l=l_opts -not-matching+:=not_matching_opts -on-files-with-tags+:=tags_opts \
    -on-files-without-tags+:=not_tags_opts -on-files-with-not-all-tags+:=not_all_tags_opts {q,-quiet}=quiet_opts

  if [[ -n $help ]]; then
    cat <<EOF

Usage:          tss tags [<options>] [--] [<path>...]
(in particular) tss tags [<options>] [--] <file>

Print tags found on files in the given path(s).

Options:
  -l                                        $label_tags_l_descr
  --not-matching <pattern...>               $label_tags_not_matching_descr
  --on-files-with-tags <pattern...>         $label_tags_on_files_with_tags_descr
  --on-files-without-tags <pattern...>      $label_tags_on_files_without_tags_descr
  --on-files-with-not-all-tags <pattern...> $label_tags_on_files_with_not_all_tags_descr
  -q, --quiet                               $label_generic_quiet_descr
  --help                                    $label_generic_help_help_descr

EOF
    return 0
  fi

  # Process options
  local separate_lines=$l_opts
  local quiet=$quiet_opts

  local -aU not_matching_patterns
  local -i i
  for ((i=2; i <= $#not_matching_opts; i+=2)); do
    not_matching_patterns+=(${(s: :)not_matching_opts[i]})
  done
  require_valid_patterns $not_matching_patterns

  local regular_file_pattern accept_non_regular
  internal_file_pattern_parse_tag_opts

  # Process positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  if [[ $# -gt 0 ]]; then
    local paths=($@)
  else
    local paths=(*)
  fi

  local tags=()
  {
    tss_internal_tags
  } always {
    if [[ $separate_lines ]]; then
      if [[ $tags ]]; then
        print -rl -- ${(in)tags}
      fi
    else
      print -r -- ${(in)tags}
    fi
  }
}

tss_internal_tags() {
  require_parameter paths 'array*'
  require_parameter regular_file_pattern 'scalar*'
  require_parameter not_matching_patterns 'array*'

  unsetopt warn_nested_var
  require_parameter tags 'array*'

  local error=

  local -r accept_non_regular=
  local -a files
  tss_internal_files || error=x

  local file_path
  local -a match mbegin mend
  local -aU all_tags=()
  for file_path in $files; do
    [[ ${file_path:t} =~ $file_name_maybe_tag_group_regex ]]
    all_tags+=(${(s: :)match[3]})
  done

  tags=(${all_tags:#(${(j:|:)not_matching_patterns})})

  [[ ! $error ]]
}

# Return the tags of the given file path, without checking whether the file exists and is taggable.
internal_file_tags_name_only() {
  require_parameter file_path 'scalar*'

  unsetopt warn_nested_var
  require_parameter file_tags 'array*'

  local -a match mbegin mend
  [[ ${file_path:t} =~ $file_name_maybe_tag_group_regex ]]
  file_tags=(${(s: :)match[3]})
}
