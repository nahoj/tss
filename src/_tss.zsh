#compdef tss

# Description: Zsh completion script for the 'tss' command

_tss_dir_all_tags() {
  _arguments -s \
             '1:dir:_files -/'
}

_tss_dir() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"

  case "$state" in
    cmds)
      _values "tss-dir command" \
              "all-tags[List all tags that appear under a given directory]" \
      ;;
    args)
      case $line[1] in
        all-tags)
          _tss_dir_all_tags
          ;;
      esac
      ;;
  esac
}

# tss file clean takes  one or more files as positional arguments
_tss_file_clean() {
  _arguments -s \
             '*:file:_files'
}

# tss file has takes 2 positional arguments: a tag and a single file
_tss_file_has() {
  _arguments -s \
             '1:file:_files' \
             '2: :->tag'
}

_tss_file_location() {
  _arguments -s \
             '1:file:_files'
}

_tss_file_tags() {
  _arguments -s \
             '1:file:_files'
}

_tss_file() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tss-file command" \
              "clean[Remove the whole tag group from one or more files.]" \
              "has[Test whether a file has a given tag.]" \
              "tags[List the tags for a given file.]" \
              "location[Prints the TagSpaces location of the given file, or an empty string]" \
      ;;
    args)
      case $line[1] in
        clean)
          _tss_file_clean
          ;;
        has)
          _tss_file_has
          ;;
        tags)
          _tss_file_tags
          ;;
        location)
          _tss_file_location
          ;;
      esac
      ;;
  esac
}

_tss_location_index_all_tags() {
  _arguments -s \
             '1:location:_files'
}

_tss_location_index_build() {
  _arguments -s \
             '1:location:_files -/'
}

_tss_location_index() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tss-location-index command" \
              "all-tags[List all tags that appear in the index]" \
              "build[Build index]" \
      ;;
    args)
      case $line[1] in
        all-tags)
          _tss_location_index_all_tags
          ;;
        build)
          _tss_location_index_build
          ;;
      esac
      ;;
  esac
}

_tss_location_of() {
  _arguments -s \
             '1:file:_files'
}

_tss_location() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tss-location command" \
              "index[TODO descr]" \
              "of[Print the TagSpaces location of the given path, or an empty string]" \
      ;;
    args)
      case $line[1] in
        index)
          _tss_location_index
          ;;
        of)
          _tss_location_of
          ;;
      esac
      ;;
  esac
}

_tss_tag_add() {
  local line state

  _arguments -sC \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
    tags)
      # One or more tags separated by spaces
      local location
      local -aU tags
      if location=$(tss file location .); then
        tags=($(tss location index all-tags $location))
      else
        # All tags in the current directory
        for f in *(.); do
          tags+=($(tss file tags $f))
        done
      fi
      if [[ $#tags -ne 0 ]]; then
        _values -s ' ' "tag" "${tags[@]}"
      fi
      ;;

    files)
      local -aU tags
      tags=(${(s: :)${(Q)line[1]}})

      if [[ $#tags -eq 1 ]]; then
        # Aim to offer files that don't have the tag
        local location files_newlines

        if location=$(tss file location .); then
          local list_command=(tss location index files $location)
          if [[ -n $line[$CURRENT] ]]; then
            list_command+=(--path-starts-with $line[$CURRENT])
          fi
          files_newlines=$("$list_command[@]" | tss filter -T ${(b)tags[1]})
          local files_array
          files_array=("${(@f)files_newlines}")
          _multi_parts / files_array

        else
          # Don't browse recursively, just read $line[$CURRENT]'s dir
          local dirs
          dirs=($line[$CURRENT]*(/))
          if [[ $#dirs -eq 0 ]]; then
            # Offer filtered files
            local all_regular_files
            all_regular_files=($line[$CURRENT]*(.))
            if [[ $#all_regular_files -ne 0 ]]; then
              local files
              files=($(tss tag files '' -T ${(b)tags[1]} "$all_regular_files[@]"))
              _values "file" "${(b)files[@]}"
            fi
          else
            # Give up on filtering
            _files
          fi
        fi

      else
        # Too complex to filter
        _files
      fi
      ;;
  esac
}

_tss_tag_files() {
  _arguments -sC \
             '1: :->tag' \
             '*:file:_files'

  case "$state" in
    tag)
      local dir tags
      dir=${$(tss file location .):-.} || return $?
      tags=($(tss dir all-tags $dir)) || return $?
      _values "tag" \
              "${tags[@]}" \
      ;;
  esac
}

_tss_tag_remove() {
  local line state

  _arguments -sC \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
    tags)
      # One or more tag patterns separated by spaces; we offer existing tags
      local location
      local -aU tags
      if location=$(tss file location .); then
        tags=($(tss location index all-tags $location))
      else
        # All tags in the current directory
        for f in *(.); do
          tags+=($(tss file tags $f))
        done
      fi
      if [[ $#tags -ne 0 ]]; then
        _values -s ' ' "tag" "${tags[@]}"
      fi
      ;;

    files)
      # We aim to offer files that have any tag matching any of the given patterns
      local -aU patterns
      patterns=(${(s: :)${(Q)line[1]}})
      local filter_pattern="(${(j:|:)patterns})"

      local location
      if location=$(tss file location .); then
        local list_command=(tss location index files $location)
        if [[ -n $line[$CURRENT] ]]; then
          list_command+=(--path-starts-with $line[$CURRENT])
        fi
        local files_newlines
        files_newlines=$("$list_command[@]" | tss filter -t ${filter_pattern})
        local -a files_array
        files_array=("${(@f)files_newlines}")
        _multi_parts / files_array

      else
        # Don't browse recursively, just read $line[$CURRENT]'s dir
        local dirs
        dirs=($line[$CURRENT]*(/))
        if [[ $#dirs -eq 0 ]]; then
          # Offer filtered files
          local all_regular_files
          all_regular_files=($line[$CURRENT]*(.))
          if [[ $#all_regular_files -ne 0 ]]; then
            local files
            files=($(tss tag files $filter_pattern "$all_regular_files[@]"))
            _values "file" "${(b)files[@]}"
          fi
        else
          # Give up on filtering
          _files
        fi
      fi
      ;;
  esac
}

_tss_tag() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tss-tag command" \
              "add[Add one or more tags to one or more files.]" \
              "files[List files with a given tag under the given paths.]" \
              "remove[Remove one or more tags from one or more files.]" \
      ;;
    args)
      case $line[1] in
        add)
          _tss_tag_add
          ;;
        files)
          _tss_tag_files
          ;;
        remove)
          _tss_tag_remove
          ;;
      esac
      ;;
  esac
}

_tss() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tss command" \
              "dir[TODO descr]" \
              "file[TODO descr]" \
              "location[TODO descr]" \
              "tag[blah]" \
      ;;
    args)
      case $line[1] in
        dir)
          _tss_dir
          ;;
        file)
          _tss_file
          ;;
        location)
          _tss_location
          ;;
        tag)
          _tss_tag
          ;;
      esac
      ;;
  esac
}

_tss "$@"
