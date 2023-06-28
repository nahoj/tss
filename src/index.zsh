
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
        print -nr $c
        ;;
    esac
  done
  print '"'
}

make_json_tag_object() {
  print -r '{ "title": '$(make_json_string $1)', "type": "plain" }'
}

make_json_file_object() {
  unsetopt warn_create_global warn_nested_var

  local file_path
  file_path=$1

  local file_name extension
  file_name=$(basename $file_path)
  [[ $file_name =~ $file_name_maybe_tag_group_regex ]]
  extension=${(e)${:-"$match[1]$match[4]"}}

  local -A stat
  zstat -H stat $file_path
  local is_regular_file
  is_regular_file=$((( 0x8000 & stat[mode] )) && print 'true' || print 'false')

  local json_tag_array='[]'
  if [[ $is_regular_file == 'true' ]]; then
    local file_tags tag_objects tag
    file_tags=($(tsp_file_tags $file_path))
    tag_objects=("${(@f)$(for tag in "$file_tags[@]"; do make_json_tag_object $tag; done)}")
    json_tag_array="[${(j:, :)tag_objects[@]}]"
  fi

  print -r '  {'
  print -r '    "uuid": "'$(uuidgen)'",'
  print -r '    "name": '$(make_json_string $file_name)','
  print -r '    "isFile": '$is_regular_file','
  print -r '    "extension": '$(make_json_string $extension)','
  print -r '    "tags": '$json_tag_array','
  print -r '    "size": '$stat[size]','
  print -r '    "lmdt": '$stat[mtime]'000,'
  print -r '    "path": '$(make_json_string $file_path)
  print -r '  }'

}

tsp_location_build_index() {
  local location
  location=$1
  require_is_location "$location"

  if [[ -f "$location/.ts/tsi.json.lock" ]]; then
    print "Index is locked" >&2
    return 1
  fi
  touch "$location/.ts/tsi.json.lock"
  pushd "$location" >/dev/null
  trap "rm -f ${(q)location}/.ts/tsi.json.lock; popd >/dev/null" EXIT INT

  print -r "Building index $location/.ts/tsi.json"
  local file_path
  print '[' >.ts/tsi.json
  # Exclude hidden files
  find * -regextype posix-extended -not -regex '.*/\.([^./]|\.[^/]).*' | {
    read -r file_path || return 0
    make_json_file_object $file_path
    while read -r file_path; do
      print ','
      make_json_file_object $file_path
    done
  } >>.ts/tsi.json
  print ']' >>.ts/tsi.json
}
