#compdef tsp

# Description: Zsh completion script for the 'tsp' command

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
      _values "tsp_file command" \
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

_tsp_tag_add() {
  local line state

  _arguments -sC \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
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
  _arguments -s \
             '1: :->tag' \
             '*:file:_files'
}

_tsp_tag_files_without() {
  _arguments -s \
             '1: :->tag' \
             '*:file:_files'
}

_tsp_tag_remove() {
  local line state

  _arguments -sC \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
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
      _values "tsp_file command" \
              "add[Add one or more tags to one or more files.]" \
              "files[List files with a given tag under the given paths.]" \
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
              "file[TODO descr]" \
              "tag[blah]" \
      ;;
    args)
      case $line[1] in
      file)
        _tsp_file
        ;;
      tag)
        _tsp_tag
        ;;
      esac
      ;;
  esac
}

_tsp "$@"
