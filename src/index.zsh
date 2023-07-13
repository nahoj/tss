
tss_location_index_tags() {
  local location
  if [[ -n $1 ]]; then
    location=$1
    require_is_location "$location"
  else
    location=$(tss_location_of_dir_unsafe ${.:a}) || fail "Not in a location"
  fi

  local index
  index="$location/.ts/tsi.json"

  # Get sorted, unique tags
  jq -r '[.[].tags | .[].title] | unique | .[]' "$index"
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
  print_json_string "$file_name"

  print -n ',\n    "isFile": '
  if [[ $typ = 'f' ]]; then
    print -n 'true'
  else
    print -n 'false'
  fi

  print -n ',\n    "extension": '
  local file_name_without_tag_group extension
  local -a match mbegin mend
  [[ $file_name =~ $file_name_maybe_tag_group_regex ]]
  file_name_without_tag_group="$match[1]$match[4]"
  extension=${file_name_without_tag_group:e}
  print_json_string "$extension"

  print -n ',\n    "tags": ['
  if [[ $typ = 'f' ]]; then
    local tag
    local -r name_only=x
    local -i i=0
    for tag in ${(s: :)$(internal_file_tags)}; do
      if (( i++ > 0 )); then
        print -rn ', '
      fi
      print_json_tag_object "$tag"
    done
  fi

  print -n '],\n    "size": '
  print -n "$size_bytes"

  print -n ',\n    "lmdt": '
  [[ $mtime =~ '^(-?[0-9]+)\.([0-9]{3})[0-9]*$' ]]
  print -n "$match[1]"
  print -n "$match[2]"

  print -n ',\n    "path": '
  print_json_string "$file_path"
  print -n '\n  }'
}

tss_location_index_build() {
  local location
  location=${1:-.}
  require_is_location "$location"

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
          if [[ $file_path = *[[:cntrl:]]* ]]; then
            logg "Warning: File path contains control character(s): ${(qqqq)file_path}"
          fi
          internal_print_json_file_object
        done
      } >>$new_index || return $?
    fi
    print '\n]' >>$new_index

    mv $new_index $index
  }
  with_lock_file "$location/.ts/tsi.json" \
    with_cd "$location" \
      do_build_index
}

tss_location_index_files() {
  local -a path_opt tags_opts not_tags_opts not_all_tags_opts
  zparseopts -D -E -F - {-path,-path-starts-with}:=path_opt {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts \
    -not-all-tags+:=not_all_tags_opts

  # Process options
  local -aU patterns anti_patterns not_all_patterns
  local -i i
  for ((i=2; i <= $#tags_opts; i+=2)); do
    patterns+=(${(s: :)tags_opts[i]})
  done
  for ((i=2; i <= $#not_tags_opts; i+=2)); do
    anti_patterns+=(${(s: :)not_tags_opts[i]})
  done
  for ((i=2; i <= $#not_all_tags_opts; i+=2)); do
    not_all_patterns+=(${(s: :)not_all_tags_opts[i]})
  done

  # Process positional arguments
  if [[ ${1:-} = '--' ]]; then
    shift
  fi
  local location
  location=$1

  case ${path_opt[1]:-} in
    '')
      local -r pathh=.
      internal_location_index_files_path
      ;;
    --path)
      local -r pathh=$path_opt[2]
      internal_location_index_files_path
      ;;
    --path-starts-with)
      local -r path_starts_with=$path_opt[2]
      internal_location_index_files_path_starts_with
      ;;
  esac
}

internal_location_index_files_path() {
  require_parameter location 'scalar*'
  require_parameter pathh 'scalar*'
  require_exists "$pathh"

  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'

  if [[ -d $pathh ]]; then
    local -r dir_path=$pathh
    local -r file_name_prefix=
    internal_location_index_files_dir_and_file_name_prefix

  else
    # For single files, don't use the index at all
    local file_path=$pathh
    local -r name_only=
    if [[ ${file_path:a} = ${location:a}/* ]] && internal_test; then
      print -r -- "$file_path"
    fi
  fi
}

internal_location_index_files_path_starts_with() {
  require_parameter location 'scalar*'
  require_parameter path_starts_with 'scalar*'

  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'

  local file_name_prefix=${path_starts_with##*/}             # $path_starts_with after last / excluded
  local dir_path=${${path_starts_with%$file_name_prefix}:-.} # $path_starts_with up to last / included, or .
  internal_location_index_files_dir_and_file_name_prefix
}

internal_location_index_files_dir_and_file_name_prefix() {
  require_parameter location 'scalar*'
  require_is_location "$location"

  require_parameter dir_path 'scalar*'
  require_parameter file_name_prefix 'scalar*'

  require_parameter patterns 'array*'
  require_parameter anti_patterns 'array*'
  require_parameter not_all_patterns 'array*'

  local abs_location=${location:a}
  local abs_dir_path=${dir_path:a}
  if [[ $abs_dir_path = $PWD ]]; then
    local output_prefix=
  else
    local output_prefix="${dir_path%/}/"
  fi

  if [[ $abs_dir_path = $abs_location ]]; then
    local index_prefix=$file_name_prefix
    local -i offset=0

  # If the dir is strictly under the location
  elif [[ $abs_dir_path = $abs_location/* ]]; then
    local index_dir_path=${abs_dir_path#$abs_location/}
    local index_prefix="$index_dir_path/$file_name_prefix"
    local -i offset=$(($#index_dir_path + 1))

  # If the location is strictly under the dir
  elif [[ $abs_location = $abs_dir_path/* ]]; then
    # All files in the index are in the path
    local index_prefix=
    local -i offset=0
    output_prefix+="${abs_location#$abs_dir_path/}/"

  else
    # No file in the index is in the path
    return 0
  fi

  local condition='.isFile'
  if [[ -n $index_prefix ]]; then
    condition+=' and (.path | startswith('$(print_json_string "$index_prefix")'))'
  fi

  local index="$location/.ts/tsi.json"
  jq -r 'map(select('$condition') | .path) | .[]' "$index" | {

    local file_path
    while read -r file_path; do
      print -rn -- "$output_prefix"
      print -r -- "${file_path:$offset}"
    done

  } | {
    local -r name_only=x
    internal_filter

  } || return $?
}

tss_location_index() {
  local subcommand
  subcommand=$1
  shift
  case $subcommand in
    build)
      tss_location_index_build "$@"
      ;;
    files)
      tss_location_index_files "$@"
      ;;
    tags)
      tss_location_index_tags "$@"
      ;;
    *)
      fail "Unknown subcommand $subcommand"
      ;;
  esac
}
