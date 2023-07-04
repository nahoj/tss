tss_clean_one_file() {
  unsetopt warn_create_global warn_nested_var

  local file_path file_name
  file_path=$1
  require_exists_taggable $file_path
  file_name=$(basename $file_path)
  if ! [[ $file_name =~ $well_formed_file_name_maybe_tag_group_regex ]]; then
    print -r "Ignoring file with ill-formed name: ${(qqq)file_path}" >&2
    return 1
  fi

  local new_file_name
  new_file_name="$match[1]$match[4]"
  if [[ $new_file_name != $file_name ]]; then
    local new_file_path
    new_file_path="$(dirname $file_path)/$new_file_name"
    require_does_not_exist $new_file_path
    mv $file_path $new_file_path
  fi
}

# remove tag group from the given files
tss_clean() {
  local file_path
  local -i statuss=0
  for file_path in "$@"; do
    tss_clean_one_file $file_path || statuss=$?
  done
  return $statuss
}

tss_set_tags() {
  unsetopt warn_create_global warn_nested_var

  local file_path tags
  file_path=$1
  require_exists_taggable $file_path
  tags=(${(s: :)2})

  # if tags empty, clean file
  if [[ ${#tags[@]} -eq 0 ]]; then
    tss_file_clean $file_path

  else
    local file_name
    file_name=$(basename $file_path)

    if ! [[ "$file_name" =~ $file_name_maybe_tag_group_regex ]]; then
      print -r "Invalid file name: ${(qqq)file_path}" >&2
      return 1
    fi

    # If file has tag group, replace it
    local new_file_name
    if [[ -n $match[2] ]]; then
      new_file_name="$match[1][${tags[@]}]$match[4]"

    # Else, insert tag group before extension if present, else at end of file name
    else
      if [[ $file_name =~ '^(.+)(\.[^.]+)$' ]]; then
        new_file_name="$match[1][${tags[@]}]$match[2]"
      else
        new_file_name="${file_name}[${tags[@]}]"
      fi
    fi

    if [[ $new_file_name != $file_name ]]; then
      local new_file_path
      new_file_path="$(dirname $file_path)/$new_file_name"
      require_does_not_exist $new_file_path
      mv $file_path $new_file_path
    fi
  fi
}

internal_add_remove() {
  [[ ${(t)add_tags} = 'array-local' ]]
  [[ ${(t)remove_patterns} = 'array-local' ]]
  [[ ${(t)file_paths} = 'array-local' ]]

  local file_path old_tags new_tags tag
  for file_path in "${file_paths[@]}"; do
    require_well_formed $file_path
    require_exists_taggable $file_path

    old_tags=($(tss_file_tags $file_path))
    if [[ $#remove_patterns -gt 0 ]]; then
      new_tags=()
      for tag in "${old_tags[@]}"; do
        if ! tss_tag_in_patterns $tag "$remove_patterns"; then
          new_tags+=($tag)
        fi
      done
    else
      new_tags=($old_tags)
    fi

    for tag in "${add_tags[@]}"; do
      if ! ((new_tags[(Ie)$tag])); then
        new_tags+=($tag)
      fi
    done

    if ! arrayeq new_tags old_tags; then
      tss_set_tags $file_path "$new_tags"
    fi
  done
}

# Add one or more tags to one or more files if not already present
tss_add() {
  local add_tags tag file_paths
  add_tags=(${(s: :)1})
  for tag in "${add_tags[@]}"; do
    require_tag_valid $tag
  done
  shift
  file_paths=("$@")

  local remove_patterns=()
  internal_add_remove
}

tss_remove() {
  local remove_patterns file_paths
  remove_patterns=(${(s: :)1})
  if ((remove_patterns[(Ie)*])); then
    print -r "Removing all tags with * is forbidden as it might be a mistake. If this is what you want to do, use:" >&2
    print -r "    tss file clean FILE ..." >&2
    return 1
  fi
  shift
  file_paths=("$@")

  local add_tags=()
  internal_add_remove
}
