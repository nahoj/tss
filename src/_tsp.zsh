#compdef tsp

# Description: Zsh completion script for the 'tsp' command

_tsp_dir_all_tags() {
  _arguments -s \
             '1:dir:_files -/'
}

_tsp_dir() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"

  case "$state" in
    cmds)
      _values "tsp-dir command" \
              "all-tags[List all tags that appear under a given directory]" \
      ;;
    args)
      case $line[1] in
        all-tags)
          _tsp_dir_all_tags
          ;;
      esac
      ;;
  esac
}

# tsp file clean takes  one or more files as positional arguments
_tsp_file_clean() {
  _arguments -s \
             '*:file:_files'
}

# tsp file has takes 2 positional arguments: a tag and a single file
_tsp_file_has() {
  _arguments -s \
             '1:file:_files' \
             '2: :->tag'
}

_tsp_file_location() {
  _arguments -s \
             '1:file:_files'
}

_tsp_file_tags() {
  _arguments -s \
             '1:file:_files'
}

_tsp_file() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tsp-file command" \
              "clean[Remove the whole tag group from one or more files.]" \
              "has[Test whether a file has a given tag.]" \
              "tags[List the tags for a given file.]" \
              "location[Prints the TagSpaces location of the given file, or an empty string]" \
      ;;
    args)
      case $line[1] in
        clean)
          _tsp_file_clean
          ;;
        has)
          _tsp_file_has
          ;;
        tags)
          _tsp_file_tags
          ;;
        location)
          _tsp_file_location
          ;;
      esac
      ;;
  esac
}

_tsp_location_all_tags() {
  _arguments -s \
             '1:location:_files'
}

_tsp_location_build_index() {
  _arguments -s \
             '1:location:_files -/'
}

_tsp_location_of() {
  _arguments -s \
             '1:file:_files'
}

_tsp_location() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tsp-location command" \
              "all-tags[List all tags that appear under a given location]" \
              "build-index[Build index]" \
              "of[Print the TagSpaces location of the given path, or an empty string]" \
      ;;
    args)
      case $line[1] in
        all-tags)
          _tsp_location_all_tags
          ;;
        build-index)
          _tsp_location_build_index
          ;;
        of)
          _tsp_location_of
          ;;
      esac
      ;;
  esac
}

_tsp_tag_add() {
  local line state

  _arguments -sC \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
    tags)
      # one or more tags separated by spaces
      local dir tags
      dir=${$(tsp file location .):-.} || return $?
      tags=($(tsp dir all-tags "$dir")) || return $?
      if [[ ${#tags} -ne 0 ]]; then
        _values -s ' ' "tag" \
                "${tags[@]}"
      fi
      ;;

    files)
      local tag
      tag=$line[1]
      local files_newlines
      if [[ -z "$line[$CURRENT]" ]]; then
        files_newlines=$(tsp tag files-without "$tag" *)
      else
        if [[ "$line[$CURRENT]" =~ ' $' ]]; then
          files_newlines=$(tsp tag files-without "$tag" $line[$CURRENT])
        else
          files_newlines=$(tsp tag files-without "$tag" $line[$CURRENT]*)
        fi
      fi
      local files_array
      files_array=("${(@f)files_newlines}")
      _multi_parts / files_array
      ;;
  esac
}

_tsp_tag_files() {
  _arguments -sC \
             '1: :->tag' \
             '*:file:_files'

  case "$state" in
    tag)
      local dir tags
      dir=${$(tsp file location .):-.} || return $?
      tags=($(tsp dir all-tags "$dir")) || return $?
      _values "tag" \
              "${tags[@]}" \
      ;;
  esac
}

_tsp_tag_files_without() {
  _arguments -sC \
             '1: :->tag' \
             '*:file:_files'

  case "$state" in
    tag)
      local dir tags
      dir=${$(tsp file location .):-.} || return $?
      tags=($(tsp dir all-tags "$dir")) || return $?
      _values "tag" \
              "${tags[@]}" \
      ;;
  esac
}

_tsp_tag_remove() {
  local line state

  _arguments -sC \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
    tags)
      local dir tags
      dir=${$(tsp file location .):-.} || return $?
      tags=($(tsp dir all-tags "$dir")) || return $?
      if [[ ${#tags} -ne 0 ]]; then
        _values -s ' ' "tag" \
                "${tags[@]}"
      fi
      ;;

    files)
      local tag
      tag=$line[1]
      local files_newlines
      if [[ -z "$line[$CURRENT]" ]]; then
        files_newlines=$(tsp tag files "$tag" *)
      else
        if [[ "$line[$CURRENT]" =~ ' $' ]]; then
          files_newlines=$(tsp tag files "$tag" $line[$CURRENT])
        else
          files_newlines=$(tsp tag files "$tag" $line[$CURRENT]*)
        fi
      fi
      local files_array
      files_array=("${(@f)files_newlines}")
      _multi_parts / files_array
      ;;
  esac
}

_tsp_tag() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tsp-tag command" \
              "add[Add one or more tags to one or more files.]" \
              "files[List files with a given tag under the given paths.]" \
              "files-without[List files without a given tag under the given paths.]" \
              "remove[Remove one or more tags from one or more files.]" \
      ;;
    args)
      case $line[1] in
        add)
          _tsp_tag_add
          ;;
        files)
          _tsp_tag_files
          ;;
        files-without)
          _tsp_tag_files_without
          ;;
        remove)
          _tsp_tag_remove
          ;;
      esac
      ;;
  esac
}

_tsp() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tsp command" \
              "dir[TODO descr]" \
              "file[TODO descr]" \
              "location[TODO descr]" \
              "tag[blah]" \
      ;;
    args)
      case $line[1] in
        dir)
          _tsp_dir
          ;;
        file)
          _tsp_file
          ;;
        location)
          _tsp_location
          ;;
        tag)
          _tsp_tag
          ;;
      esac
      ;;
  esac
}

_tsp "$@"
