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
      local -aU tags=(${(s: :)${(Q)line[1]}})
      local patterns=(${(b)tags[@]})

      # Aim to offer files that don't have the tag
      local location
      if location=$(tss location of .); then
        local -a files
        files=("${(@f)"$( \
          tss location index files "$location" --path-starts-with "${(Q)line[$CURRENT]}" \
            --not-all-tags "${(j: :)patterns}" \
          )"}")
        _multi_parts / files

      else
        _files -g "$(tss util files-with-not-all-tags-pattern $patterns)"
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
             "--help[$(tss label generic_completion_help_descr)]" \
             {-I,--no-index}"[$(tss label files_no_index_descr)]" \
             "--not-all-tags[$(tss label files_not_all_tags_descr)]:patterns:->tags" \
             '*'{-T,--not-tags}"[$(tss label files_not_tags_descr)]:patterns:->tags" \
             '*'{-t,--tags}"[$(tss label files_tags_descr)]:patterns:->tags" \
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

_tss_filter() {
  _arguments -s -C : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label filter_name_only_descr)]" \
             "--not-all-tags[$(tss label filter_not_all_tags_descr)]:patterns:->tags" \
             '*'{-T,--not-tags}"[$(tss label filter_not_tags_descr)]:patterns:->tags" \
             '*'{-t,--tags}"[$(tss label filter_tags_descr)]:patterns:->tags" \
}

_tss_tags() {
  _arguments -s -C : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label tags_name_only_descr)]" \
             "--stdin[$(tss label tags_stdin_descr)]" \
             '1:file:_files'
}

_tss_test() {
  _arguments -s -C : \
             "--help[$(tss label generic_completion_help_descr)]" \
             {-n,--name-only}"[$(tss label test_name_only_descr)]" \
             "--not-all-tags[$(tss label test_not_all_tags_descr)]:patterns:->tags" \
             '*'{-T,--not-tags}"[$(tss label test_not_tags_descr)]:patterns:->tags" \
             '*'{-t,--tags}"[$(tss label test_tags_descr)]:patterns:->tags" \
             '1:file:_files'
}


####################
# Location and index
####################

_tss_location_index_tags() {
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
              "build[Build index]" \
              "tags[List all tags that appear in the index]" \
      ;;
    args)
      case $line[1] in
        build)
          _tss_location_index_build
          ;;
        tags)
          _tss_location_index_tags
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

_tss_label() {
  _values "label" 'list' $(tss label list)
}

_tss_util() {
  local line state

  _arguments -s -C \
             "1: :->cmds" \
             "*::arg:->args"
  case "$state" in
    cmds)
      _values "tss-tag command" \
              "file-with-not-all-tags-pattern[Output a glob pattern matching any file whose tags don't match all the fiven patterns]" \
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
      # Omits 'label' because there's no practical use for it
      _values "tss command" \
              "add[$(tss label add_descr)]" \
              "clean[$(tss label clean_descr)]" \
              "files[$(tss label files_descr)]" \
              "filter[$(tss label filter_descr)]" \
              "location[$(tss label location_descr)]" \
              "query[$(tss label query_descr)]" \
              "remove[$(tss label remove_descr)]" \
              "tags[$(tss label tags_descr)]" \
              "test[$(tss label test_descr)]" \
              "util[$(tss label util_descr)]" \
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
        label)
          _tss_label
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
