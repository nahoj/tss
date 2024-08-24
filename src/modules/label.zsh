local label_add_descr="Add tags to one or more files."
local label_add_quiet_descr="Be less verbose. In particular, don't print the new path of each given file."
local label_add_tags_descr="Add the given tags, in addition to tags given in the first positional argument."

local label_clean_descr="Remove tag group from one or more files."
local label_clean_quiet_descr=$label_add_quiet_descr

local label_comp_descr="Completion utilities."

local label_files_descr="List files with tags matching the given patterns."
local label_files_not_all_tags_descr="Don't output files that have tags matching all of the given patterns."
local label_files_not_tags_descr="Don't output files that have any tag matching any of the given patterns."
local label_files_tags_descr="Only output files that have tags matching all the given patterns."

local label_filter_descr="Filter files with tags matching the given patterns."
local label_filter_name_only_descr="Filter files based on their name, assume they exist and are taggable files."
local label_filter_not_all_tags_descr=$label_files_not_all_tags_descr
local label_filter_not_tags_descr=$label_files_not_tags_descr
local label_filter_tags_descr=$label_files_tags_descr

local label_generic_completion_help_descr="Show help message."
local label_generic_dry_run_descr="Don't actually modify files."
local label_generic_help_help_descr="Show this help message."
local label_generic_quiet_descr="Don't print non-fatal errors."

local label_label_descr="App labels (parameter descriptions etc.)."

local label_location_descr="Work with Locations."
local label_location_index_descr="Work with indexes."
local label_location_init_descr="Make a directory a location."
local label_location_of_descr="Print the location of a file or directory."
local label_location_remove_descr="Make a directory no longer a location."

local label_query_descr="Alias for 'files'."

local label_remove_descr="Remove tags from one or more files."
local label_remove_quiet_descr=$label_add_quiet_descr
local label_remove_tags_descr="Remove tags matching the given patterns, in addition to patterns given in the first positional argument."

local label_tags_descr="List tags present on one or more files."
local label_tags_l_descr="Print tags on separate lines. (Default: single line, separated by spaces.)"
local label_tags_not_matching_descr="Only print tags that don't match any of the given patterns."
local label_tags_on_files_with_tags_descr="Only print tags present on files with tags matching all the given patterns."
local label_tags_on_files_without_tags_descr="Only print tags present on files without any tag matching any of the given patterns."
local label_tags_on_files_with_not_all_tags_descr="Only print tags present on files that lack tags matching at least one of the given patterns."

local label_test_descr="Test whether a file matches one or more tag patterns."
local label_test_name_only_descr="Test only the file's name, assume the file exists and is a taggable file."
local label_test_not_all_tags_descr="True only if at least 1 of the patterns is not matched by any of the file's tags."
local label_test_not_tags_descr="True only if the file doesn't have any tag matching any of the given patterns."
local label_test_tags_descr="True only if the file has tags matching all the given patterns."

local label_util_descr="Utilities."

tss_label() {
  case $1 in
    list)
      print -rl -- ${(@o)${parameters[(I)label_*]}#label_}
      ;;
    *)
      local var="label_$1"
      if [[ ! -v $var ]]; then
        fail "Unknown label: $1"
      fi
      print -r -- ${(P)var}
      ;;
  esac
}
