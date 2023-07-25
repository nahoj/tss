# TTL: Not too short because we're slow, and not exactly 10 minutes to
# have a lower probability of rebuilding at the same time as TagSpaces.
local -i index_ttl_seconds=1200


########
# Build
########

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
  # optional: uuid 'scalar*'

  local file_name
  file_name=${file_path:t}

  print '  {'
  print -n '    "uuid": "'
  print -n ${uuid:-$(uuidgen)}

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
    local -a file_tags
    internal_file_tags_name_only
    local tag
    local -i i=0
    for tag in $file_tags; do
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
  local location=${1:-.}
  require_is_location "$location"

  do_build_index() {
    logg "Building index $location/.ts/tsi.json"

    # Note: We are in $location
    local index new_index
    index=".ts/tsi.json"
    new_index="$index.NEW"

    local error

    print '[' >$new_index
    # If the current dir is not empty
    if [ .(FN) ]; then
      # Don't 'find *' in case there is a file whose name starts with a dash.
      # Exclude hidden files.
      find . -not -path '*/.*' -printf '%y\t%T@\t%s\t' -print | {
        local IFS=$'\t'
        local typ mtime size_bytes file_path
        # Like TagSpaces, generate consecutive UUIDs as a performance improvement
        local -i uuid_start
        uuid_start=16#${"$(uuidgen)":0:8}
        local uuid_suffix uuid
        uuid_suffix=${"$(uuidgen)":10:27}
        local -i i=0
        # Don't 'read -d' in code that can be run asynchronously because of this bug in zsh <= 5.9:
        # https://www.zsh.org/mla/workers/2023/msg00696.html
        while read -r typ mtime size_bytes file_path; do
          if [[ ! ($typ = ? && $mtime = (-|)<->.<-> && $size_bytes = <-> && -n $file_path) ]]; then
            logg "Invalid data from 'find' (tab or newline in file path?): "$typ$'\t'$mtime$'\t'$size_bytes$'\t'$file_path
            error=x
            continue
          fi
          if [[ $file_path = *[[:cntrl:]]* ]]; then
            logg "Warning: File path contains control character(s): ${(qqqq)file_path}"
          fi
          if (( i > 0 )); then
            print ','
          fi
          file_path=${file_path#./}
          uuid=$(printf '%08x-%s' $(( (uuid_start + i) % 0x100000000 )) "$uuid_suffix")
          internal_print_json_file_object
          (( i++ ))
        done
      } >>$new_index || return $?
    fi
    print '\n]' >>$new_index

    mv $new_index $index
    [[ ! $error ]]
  }
  with_lock_file "$location/.ts/tsi.json" \
    with_cd "$location" \
      do_build_index
}

internal_location_index_build_if_stale_async() {
  require_parameter location 'scalar*'

  if ! tss_location_index_is_fresh "$location"; then
    tss_location_index_build "$location" &>/dev/null &!
  fi
}

tss_location_index_is_fresh() {
  local location=$1
  require_is_location "$location"

  local index="$location/.ts/tsi.json"
  [[ $(zstat +mtime "$index") -gt $(($(date +%s) - $index_ttl_seconds)) ]]
}

#######
# Tags
#######

tss_location_index_internal_tags() {
  require_parameter location 'scalar*'

  unsetopt warn_nested_var
  require_parameter tags 'array*'

  local index="$location/.ts/tsi.json"

  # Get sorted, unique tags
  tags=(${(f)$(jq -r '[.[].tags | .[].title] | unique | .[]' "$index")})

  internal_location_index_build_if_stale_async "$location"
}

tss_location_index_tags() {
  if [[ ${1:-} = -- ]]; then
    shift
  fi
  if [[ $# -ne 1 || $1 = --help ]]; then
    fail "Usage: tss location index tags <location>"
  fi
  local location
  if [[ -n $1 ]]; then
    location=$1
    require_is_location "$location"
  else
    location=$(tss_location_of_dir_unsafe ${.:a}) || fail "Not in a location"
  fi

  local -a tags
  {
    tss_location_index_internal_tags
  } always {
    print -r -- $tags
  }
}

#######
# Main
#######

tss_location_index() {
  local command=$1
  shift
  case $command in
    build)
      tss_location_index_build "$@"
      ;;
    internal-tags)
      tss_location_index_internal_tags "$@"
      ;;
    is-fresh)
      tss_location_index_is_fresh "$@"
      ;;
    tags)
      tss_location_index_tags "$@"
      ;;
    *)
      fail "Unknown command: $command"
      ;;
  esac
}
