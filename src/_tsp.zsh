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

# tsp file list takes a single file
_tsp_file_list() {
  _arguments -s \
             '1:file:_files'
}

_tsp_file_location() {
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
              "list[List the tags for a given file.]" \
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
      list)
        _tsp_file_list
        ;;
      location)
        _tsp_file_location
        ;;
      esac
      ;;
  esac
}

# tsp file add takes positional arguments: first a tag, then one or more files
# no completion is offered for the tag, but we can complete the files
_tsp_tag_add() {
  local line state

  _arguments -sC \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
    files)
      _files
      ;;
  esac
}

_tsp_tag_remove() {
  _arguments -s \
             '1: :->tag' \
             '*:file:_files'
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
              "remove[Remove one or more tags from one or more files.]" \
      ;;
    args)
      case $line[1] in
      add)
        _tsp_tag_add
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
