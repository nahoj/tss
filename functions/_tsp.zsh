#compdef tsp

# Description: Zsh completion script for the 'tsp' command

# tsp file add takes positional arguments: first a tag, then one or more files
# no completion is offered for the tag, but we can complete the files
_tsp_file_add() {
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

# tsp file clean takes  one or more files as positional arguments
_tsp_file_clean() {
  _arguments -s \
             '*:file:_files'
}

# tsp file has takes 2 positional arguments: a tag and a single file
_tsp_file_has() {
  _arguments -s \
             '1: :->tag' \
             '2:file:_files'
}

# tsp file list takes a single file
_tsp_file_list() {
  _arguments -s \
             '1:file:_files'
}

_tsp_file_remove() {
  _arguments -s \
             '1: :->tag' \
             '*:file:_files'
}

_tsp_file() {
  local line state

  _arguments -sC \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tsp_file command" \
              "add[Add one or more tags to one or more files.]" \
              "clean[Remove the whole tag group from one or more files.]" \
              "has[Test whether a file has a given tag.]" \
              "list[List the tags for a given file.]" \
              "remove[Remove one or more tags from one or more files.]" \
      ;;
    args)
      case $line[1] in
      add)
        _tsp_file_add
        ;;
      clean)
        _tsp_file_clean
        ;;
      has)
        _tsp_file_has
        ;;
      list)
        _tsp_file_list
        ;;
      remove)
        _tsp_file_remove
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
              "test[blah]" \
      ;;
    args)
      case $line[1] in
      file)
        _tsp_file
        ;;
      test)
        _tsp_test
        ;;
      esac
      ;;
  esac
}

_tsp "$@"
