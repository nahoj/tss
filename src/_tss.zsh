#compdef tss

# Description: Zsh completion script for the 'tss' command

# Escape special characters in a raw string to give to _values
escape_value() {
  for c in ${(s::)1}; do
    case $c in
      [][:\\+-])
        print -nr -- "\\$c"
        ;;
      *)
        print -nr -- $c
    esac
  done
}


##################
# Edit subcommands
##################

_tss_add() {
  local line state

  _arguments -s -C \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
    tags)
      # One or more tags separated by spaces
      local location
      local -aU tags
      if location=$(tss location of .); then
        tags=($(tss location index all-tags "$location"))
      else
        # All tags in the current directory
        for f in *(.N); do
          tags+=($(tss tags "$f"))
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
        local location
        if location=$(tss location of .); then
          local -a files
          files=("${(@f)"$( \
            tss location index files "$location" --path-starts-with "${(Q)line[$CURRENT]}" -T "${(b)tags[1]}" \
            )"}")
          _multi_parts / files

        else
          # Don't browse recursively, just read $line[$CURRENT]'s dir
          local dirs
          dirs=(${(Q)line[$CURRENT]}*(/N))
          if [[ $#dirs -eq 0 ]]; then
            # Offer filtered files
            local all_regular_files
            all_regular_files=(${(Q)line[$CURRENT]}*(.N))
            if [[ $#all_regular_files -ne 0 ]]; then
              local files
              files=($(tss files -T "${(b)tags[1]}" $all_regular_files))
              local values
              values=("${(@f)$(escape_value "${(F)files}")}")
              _values "file" "$values[@]"
            fi
          else
            # Give up on filtering
            _files -g '*(.)'
          fi
        fi

      else
        # Too complex to filter
        _files -g '*(.)'
      fi
      ;;
  esac
}

# tss clean takes one or more files as positional arguments
_tss_clean() {
  _arguments -s \
             '*::file:->files'

  case "$state" in
    files)
      # Regular files with a tag group
      _files -g '*[[]*[]]*(.)'
      ;;
  esac
}

_tss_remove() {
  local line state

  _arguments -s -C \
             '1: :->tags' \
             '*::file:->files'

  case "$state" in
    tags)
      # One or more tag patterns separated by spaces; we offer existing tags
      local location
      local -aU tags
      if location=$(tss location of .); then
        tags=($(tss location index all-tags "$location"))
      else
        # All tags in the current directory
        for f in *(.N); do
          tags+=($(tss tags "$f"))
        done
      fi
      if [[ $#tags -ne 0 ]]; then
        _values -s ' ' "tag" "${tags[@]}"
      fi
      ;;

    files)
      # Offer files that have any tag matching any of the given patterns
      local -aU patterns
      patterns=(${(s: :)${(Q)line[1]}})
      local filter_pattern="(${(j:|:)patterns})"

      local location
      if location=$(tss location of .); then
        local -a files
        files=("${(@f)"$( \
          tss location index files "$location" --path-starts-with "${(Q)line[$CURRENT]}" -t "$filter_pattern" \
          )"}")
        _multi_parts / files

      else
        _files -g "$(tss util file-with-tag-pattern "$filter_pattern")"
      fi
      ;;
  esac
}


###################
# Query subcommands
###################

_tss_files() {
  _arguments -s -C : \
             '--help[show help]' \
             '*'{-T,--not-tags}"[Don't list files with any tag matching any of the given patterns]:patterns:->tags" \
             '*'{-t,--tags}'[List files with tags matching all of the given patterns]:patterns:->tags' \
             '*:file:_files' \

  case "$state" in
    tags)
      local dir tags
      dir=${$(tss location of .):-.} || return $?
      tags=($(tss tags "$dir")) || return $?
      _values -s ' ' "tag" \
              "${tags[@]}" \
      ;;
  esac
}

_tss_file_location() {
  _arguments -s \
             '1:file:_files'
}

_tss_tags() {
  _arguments -s \
             '1:file:_files'
}

_tss_test() {
  _arguments -s \
             '1:file:_files'
}


####################
# Location and index
####################

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

  _arguments -s -C \
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

  _arguments -s -C \
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

_tss_util() {
  local line state

  _arguments -s -C \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tss-tag command" \
              "file-with-tag-pattern[Output a glob pattern matching any file with a tag matching the given pattern]" \
      ;;
    args)
      case $line[1] in
        file-with-tag-pattern)
          ;;
      esac
      ;;
  esac
}

_tss() {
  local line state

  _arguments -s -C \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tss command" \
              "add[Add tags to one or more files.]" \
              "clean[Remove the whole tag group from one or more files.]" \
              "files[List files]" \
              "filter[Filter paths read on stdin]" \
              "location[TODO descr]" \
              "query[Alias of 'tss files']" \
              "remove[Remove tags from one or more files.]" \
              "tags[List tags]" \
              "test[Tests whether a file meets some criteria]" \
              "util[Utils]" \
      ;;
    args)
      case $line[1] in
        add)
          _tss_add
          ;;
        clean)
          _tss_clean
          ;;
        files|query)
          _tss_files
          ;;
        filter)
          _tss_filter
          ;;
        location)
          _tss_location
          ;;
        remove)
          _tss_remove
          ;;
        tags)
          _tss_tags
          ;;
        test)
          _tss_test
          ;;
        util)
          _tss_util
          ;;
      esac
      ;;
  esac
}

_tss "$@"
