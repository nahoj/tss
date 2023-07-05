
tss_location_index_all_tags() {
  local pathh
  if [[ -n $1 ]]; then
    pathh=$1
    require_exists $pathh
  else
    pathh=.
  fi

  local location index
  location=$(tss_location_of_dir_unsafe .) || {
    print "Not in a location" >&2
    return 1
  }
  index="$location/.ts/tsi.json"

  # Get sorted, unique tags
  jq -r '[.[].tags | .[].title] | unique | .[]' $index
}

# (>100x as fast as calling jq on a single string)
make_json_string() {
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
  print '"'
}

make_json_tag_object() {
  local json_title
  json_title=$(make_json_string $1)
  print -r '{ "title": '$json_title', "type": "plain" }'
}

make_json_file_object() {
  unsetopt warn_create_global warn_nested_var

  local file_path
  file_path=$1

  local uuid
  uuid=$(uuidgen)

  local file_name json_file_name
  file_name=$(basename $file_path)
  json_file_name=$(make_json_string $file_name)

  local -A stat
  zstat -H stat $file_path
  local is_regular_file
  is_regular_file=$((( 0x8000 & stat[mode] )) && print 'true' || print 'false')

  local extension
  [[ $file_name =~ $file_name_maybe_tag_group_regex ]]
  extension=$(make_json_string ${(e)${:-"$match[1]$match[4]"}})

  local json_tag_array='[]'
  if [[ $is_regular_file == 'true' ]]; then
    local file_tags tag_objects tag
    file_tags=($(tss_file_tags $file_path))
    tag_objects=("${(@f)$(for tag in "$file_tags[@]"; do make_json_tag_object $tag; done)}")
    json_tag_array="[${(j:, :)tag_objects[@]}]"
  fi

  local json_path
  json_path=$(make_json_string $file_path)

  print -r '  {'
  print -r '    "uuid": "'$uuid'",'
  print -r '    "name": '$json_file_name','
  print -r '    "isFile": '$is_regular_file','
  print -r '    "extension": '$extension','
  print -r '    "tags": '$json_tag_array','
  print -r '    "size": '$stat[size]','
  print -r '    "lmdt": '$stat[mtime]'000,'
  print -r '    "path": '$json_path
  print -r '  }'
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
    print -lr **/* | {
      local file_path
      read -r file_path || return 0
      make_json_file_object $file_path
      while read -r file_path; do
        print ','
        make_json_file_object $file_path
      done
    } >>$new_index
    print ']' >>$new_index

    mv $new_index $index
  }
  with_lock_file "$location/.ts/tsi.json" with_cd $location do_build_index
}

tss_location_index_files() {
  local -a opts tags_opts not_tags_opts
  zparseopts -D -E -F -A opts - -path: -path-starts-with: {t,-tags}+:=tags_opts {T,-not-tags}+:=not_tags_opts

  # Process options
  local -aU patterns anti_patterns
  local -i i
  for ((i=2; i <= ${#tags_opts}; i+=2)); do
    patterns+=(${(s: :)tags_opts[i]})
  done
  for ((i=2; i <= ${#not_tags_opts}; i+=2)); do
    anti_patterns+=(${(s: :)not_tags_opts[i]})
  done

  # Process positional arguments
  local location
  location=$1
  require_is_location $location

  local condition='.isFile'
  if [[ -v 'opts[--path]' ]]; then
    require_exists $opts[--path]
    if [[ -d $opts[--path] ]]; then
      condition+=' and (.path | startswith('$(make_json_string "$opts[--path]/")'))'
    else
      condition+=' and .path == '$(make_json_string $opts[--path])
    fi
  fi
  if [[ -n ${opts[--path-starts-with]:-} ]]; then
    condition+=' and (.path | startswith('$(make_json_string $opts[--path-starts-with])'))'
  fi

  local index
  index="$location/.ts/tsi.json"
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
      print "Unknown subcommand $subcommand" >&2
      return 1
      ;;
  esac
}
