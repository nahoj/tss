
tss_location_index_all_tags() {
  local pathh
  if [[ -n $1 ]]; then
    pathh=$1
    require_exists $pathh
  else
    pathh=.
  fi

  local location index
  location=$(tss_location_of_dir_unsafe .) || fail "Not in a location"
  index="$location/.ts/tsi.json"

  # Get sorted, unique tags
  jq -r '[.[].tags | .[].title] | unique | .[]' $index
}

print_json_string() {
  local s
  s=$1

  print -n '"'
  local c
  for c in ${(s::)s}; do
    case $c in
      \"|\\)
        print -nr "\\$c"
        ;;
      $'\b')
        print -nr '\b'
        ;;
      $'\f')
        print -nr '\f'
        ;;
      $'\n')
        print -nr '\n'
        ;;
      $'\r')
        print -nr '\r'
        ;;
      $'\t')
        print -nr '\t'
        ;;
      [[:cntrl:]])
        printf '\\u%04x' "'$c"
        ;;
      *)
        print -nr -- $c
        ;;
    esac
  done
  print -n '"'
}

print_json_tag_object() {
  print -rn '{ "title": '
  print_json_string $1
  print -rn ', "type": "plain" }'
}

internal_print_json_file_object() {
  unsetopt warn_create_global warn_nested_var

  require_parameter typ 'scalar*'
  require_parameter mtime 'scalar*'
  require_parameter size_bytes 'scalar*'
  require_parameter file_path 'scalar*'

  local file_name
  file_name=${file_path:t}

  print '  {'
  print -n '    "uuid": "'
  print -n $(uuidgen)

  print -n '",\n    "name": '
  print_json_string $file_name

  print -n ',\n    "isFile": '
  if [[ $typ = 'f' ]]; then
    print -n 'true'
  else
    print -n 'false'
  fi

  print -n ',\n    "extension": '
  local file_name_without_tag_group extension
  [[ $file_name =~ $file_name_maybe_tag_group_regex ]]
  file_name_without_tag_group="$match[1]$match[4]"
  extension=${file_name_without_tag_group:e}
  print_json_string "$extension"

  print -n ',\n    "tags": ['
  if [[ $typ = 'f' ]]; then
    local tag
    local -ar name_only_opt=(-n)
    local -i i=0
    for tag in ${(s: :)$(internal_file_tags)}; do
      if (( i++ > 0 )); then
        print -rn ', '
      fi
      print_json_tag_object $tag
    done
  fi

  print -n '],\n    "size": '
  print -n $size_bytes

  print -n ',\n    "lmdt": '
  [[ $mtime =~ '^(-?[0-9]+)\.([0-9]{3})[0-9]*$' ]]
  print -n $match[1]
  print -n $match[2]

  print -n ',\n    "path": '
  print_json_string $file_path
  print -n '\n  }'
}

tss_location_index_build() {
  local location
  location=${1:-.}
  require_is_location $location

  do_build_index() {
    print -r "Building index $location/.ts/tsi.json"

    # Note: We are in $location
    local index new_index
    index=".ts/tsi.json"
    new_index="$index.NEW"

    print '[' >$new_index
    # If the current dir is not empty
    if [ .(FN) ]; then
      # Exclude hidden files
      find [^.]* -not -path '*/.*' -printf '%y\t%T@\t%s\t' -print0 | {
        local IFS=$'\t'
        local typ mtime size_bytes file_path
        local -i i=0
        while read -r -d $'\0' typ mtime size_bytes file_path; do
          if (( i++ > 0 )); then
            print ','
          fi
          internal_print_json_file_object
        done
      } >>$new_index || return $?
    fi
    print '\n]' >>$new_index

    mv $new_index $index
  }
  with_lock_file "$location/.ts/tsi.json" with_cd $location do_build_index
}

tss_location_index_files() {
  local -a tags_opts not_tags_opts
  local -A opts
  zparseopts -D -E -F -A opts - -path: -path-starts-with: {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts

  # Process options
  local pathh path_starts_with
  pathh=${opts[--path]:-}
  path_starts_with=${opts[--path-starts-with]:-}

  local -aU patterns anti_patterns
  local -i i
  for ((i=2; i <= ${#tags_opts}; i+=2)); do
    patterns+=(${(s: :)tags_opts[i]})
  done
  for ((i=2; i <= ${#not_tags_opts}; i+=2)); do
    anti_patterns+=(${(s: :)not_tags_opts[i]})
  done

  # Process positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  local location
  location=$1
  require_is_location $location

  internal_location_index_files
}

internal_location_index_files() {
  require_parameter pathh 'scalar*'
  require_parameter path_starts_with 'scalar*'

  require_parameter location 'scalar*'

  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'

  local condition='.isFile'
  if [[ -n $pathh ]]; then
    require_exists $pathh
    if [[ -d $pathh ]]; then
      condition+=' and (.path | startswith('$(print_json_string "$pathh/")'))'
    else
      condition+=' and .path == '$(print_json_string $pathh)
    fi
  fi
  if [[ -n $path_starts_with ]]; then
    condition+=' and (.path | startswith('$(print_json_string $path_starts_with)'))'
  fi

  local index
  index="$location/.ts/tsi.json"
  local -ar name_only_opt=(-n)
  jq -r "map(select($condition)) | .[].path" $index | internal_filter
}

tss_location_index() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    all-tags)
      tss_location_index_all_tags "$@"
      ;;
    files)
      tss_location_index_files "$@"
      ;;
    build)
      tss_location_index_build "$@"
      ;;
    *)
      fail "Unknown subcommand $subcommand"
      ;;
  esac
}
