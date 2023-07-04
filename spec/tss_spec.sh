Describe 'tss'
  alias tss='src/tss'
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  Describe 'dir'
    Describe 'all-tags'
      It 'rejects a file'
        local file="_test/file"
        touch "$file"
        When call tss dir all-tags "$file"
        The status should equal 1
        The stderr should not equal ""
      End

      It 'rejects a directory that does not exist'
        When call tss dir all-tags _test/dir
        The status should equal 1
        The stderr should not equal ""
      End

      It 'defaults to . if no argument is given'
        local file1="_test/file1[tag1]"
        touch "$file1"
        pushd _test >/dev/null
        When call tss dir all-tags
        popd >/dev/null
        The status should equal 0
        The output should equal "tag1"
      End

      It 'outputs unique, sorted tags'
        mkdir _test/dir
        local file1="_test/dir/file1[tag3 tag2]"
        local file2="_test/dir/file2[tag2 tag1].ext"
        touch "$file1" "$file2"
        When call tss dir all-tags _test/dir
        The status should equal 0
        The output should equal "tag1
tag2
tag3"
      End

      It 'outputs nothing if there are no tags'
        mkdir _test/dir
        local file1="_test/dir/file1"
        local file2="_test/dir/file2.ext"
        touch "$file1" "$file2"
        When call tss dir all-tags _test/dir
        The status should equal 0
        The output should equal ""
      End

      It 'outputs the tags of all files in the directory recursively'
        mkdir -p _test/dir1/dir2
        local file1="_test/dir1/dir2/file1[tag1 tag2]"
        local file2="_test/dir1/dir2/file2[tag3].ext"
        touch "$file1" "$file2"
        When call tss dir all-tags _test/dir1
        The status should equal 0
        The output should equal "tag1
tag2
tag3"
      End

    End
  End

  Describe 'file'

    Describe 'clean'
      It 'rejects a directory'
        mkdir _test/dir
        When call tss file clean _test/dir
        The status should equal 1
        The stderr should not equal ""
        The path "_test/dir" should be directory
      End

      It 'rejects a file with an ill-formed name'
        touch "_test/file[tag1 tag2"
        When call tss file clean "_test/file[tag1 tag2"
        The status should equal 1
        The stderr should not equal ""
        The file "_test/file[tag1 tag2" should be exist
      End

      It 'ignores an invalid file, cleans a valid file, and returns 1'
        local file1="_test/file1[tag1 tag2"
        local file2="_test/file2[tag3].ext"
        touch "$file1" "$file2"
        When call tss file clean "$file1" "$file2"
        The status should equal 1
        The stderr should not equal ""
        The file "$file1" should be exist
        The file "$file2" should not be exist
        The file "_test/file2.ext" should be exist
      End

      It 'removes a tag group from a file with tags'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tss file clean "$file"
        The file "$file" should not be exist
        The file "_test/file.ext" should be exist
      End

      It 'removes a tag group from a file with an empty tag group'
        local file="_test/file[].ext"
        touch "$file"
        When call tss file clean "$file"
        The file "$file" should not be exist
        The file "_test/file.ext" should be exist
      End

      It 'leaves a file with no tag group unchanged'
        local file="_test/file.ext"
        touch "$file"
        When call tss file clean "$file"
        The file "$file" should be exist
      End

      It 'removes a tag group from several files'
        local file1="_test/file1[tag1 tag2].ext"
        local file2="_test/file2[tag3].ext"
        touch "$file1" "$file2"
        When call tss file clean "$file1" "$file2"
        The file "$file1" should not be exist
        The file "_test/file1.ext" should be exist
        The file "$file2" should not be exist
        The file "_test/file2.ext" should be exist
      End
    End

    Describe 'has'
      It 'rejects a nonexistent file'
        When call tss file has _test/file tag
        The status should equal 1
        The stderr should not equal ""
      End

      It 'rejects a directory'
        local dir="_test/dir"
        mkdir "$dir"
        When call tss file has _test/dir tag
        The status should equal 1
        The stderr should not equal ""
        The path "$dir" should be directory
      End

      It 'returns 0 if a file has all the given tags'
       local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tss file has "$file" 'tag1 tag2'
        The status should equal 0
      End

      It 'returns 1 if a file is missing any of the given tags'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tss file has "$file" 'tag1 tag2 tag3'
        The status should equal 1
      End

      It 'returns 0 if a file has all the given tags and more'
        local file="_test/file[tag1 tag2 tag3].ext"
        touch "$file"
        When call tss file has "$file" 'tag1 tag2'
        The status should equal 0
      End

      It 'returns 0 if a file has tags matching all the given glob patterns'
        local file="_test/file[tag11 tag22].ext"
        touch "$file"
        When call tss file has "$file" 'tag1* tag2*'
        The status should equal 0
      End

      It "returns 1 if one pattern isn't matched by any of the file's tags"
        local file="_test/file[tag11 tag22].ext"
        touch "$file"
        When call tss file has "$file" 'tag1* tag2* tag3*'
        The status should equal 1
      End
    End

    Describe 'tags'
      It 'rejects a nonexistent file'
        When call tss file tags _test/file
        The status should equal 1
        The stderr should not equal ""
      End

      It 'rejects a directory'
        local dir="_test/dir"
        mkdir "$dir"
        When call tss file tags "$dir"
        The status should equal 1
        The stderr should not equal ""
        The path "$dir" should be directory
      End

      It 'lists tags for a file with tags'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tss file tags "$file"
        The output should equal 'tag1 tag2'
      End

      It 'lists tags for a file with an empty tag group'
        local file="_test/file[].ext"
        touch "$file"
        When call tss file tags "$file"
        The output should equal ''
      End

      It 'lists tags for a file with no tag group'
        local file="_test/file.ext"
        touch "$file"
        When call tss file tags "$file"
        The output should equal ''
      End
    End
  End

  Describe 'location'
    Describe 'of'
      It 'rejects a nonexistent file'
        When call tss location of _test/file
        The status should equal 1
        The stderr should not equal ""
      End

      It 'returns a location under the current directory'
        local loc="_test/loc"
        mkdir -p "$loc/.ts"
        touch "$loc/.ts/tsi.json"
        local file="$loc/file.ext"
        touch "$file"
        When call tss location of "$file"
        The status should equal 0
        The output should equal "$PWD/$loc"
      End

      It 'returns a location above the current directory'
        local loc="_test/loc"
        mkdir -p "$loc/.ts"
        touch "$loc/.ts/tsi.json"
        local dir="$loc/dir"
        mkdir -p "$dir"
        cd "$dir"
        local file="file.ext"
        touch "$file"
        When call tss location of "$file"
        The status should equal 0
        The output should equal "$(realpath "..")"
        cd "$OLDPWD"
      End

      It 'returns a location unrelated to the current directory'
        local test_dir="/tmp/tss_test"
        local loc="$test_dir/loc"
        mkdir -p "$loc/.ts"
        touch "$loc/.ts/tsi.json"
        local file="$loc/file.ext"
        touch "$file"
        When call tss location of "$file"
        The status should equal 0
        The output should equal "$loc"
        rm -rf "$test_dir"
      End
    End
  End

  Describe 'tag'

    Describe 'add'

      It 'rejects an invalid tag'
        local file="_test/file.ext"
        touch "$file"
        When call tss tag add '[' "$file"
        The status should equal 1
        The stderr should not equal ""
        The file "$file" should be exist
      End

      It 'rejects a directory'
        local dir="_test/dir"
        mkdir "$dir"
        When call tss tag add tag "$dir"
        The status should equal 1
        The stderr should not equal ""
        The path "$dir" should be directory
      End

      It 'adds a tag to a file with a tag group'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tss tag add tag3 "$file"
        The file "$file" should not be exist
        The file "_test/file[tag1 tag2 tag3].ext" should be exist
      End

      It 'adds a tag to a file with an empty tag group'
        local file="_test/file[].ext"
        touch "$file"
        When call tss tag add tag "$file"
        The file "$file" should not be exist
        The file "_test/file[tag].ext" should be exist
      End

      It 'adds a tag to a file with no tag group and which has an extension'
        local file="_test/file.ext"
        touch "$file"
        When call tss tag add tag "$file"
        The file "$file" should not be exist
        The file "_test/file[tag].ext" should be exist
      End

      It 'adds a tag to a file with no tag group and no extension'
        local file="_test/file"
        touch "$file"
        When call tss tag add tag "$file"
        The file "$file" should not be exist
        The file "_test/file[tag]" should be exist
      End

      It 'adds a tag to several files'
        local file1="_test/file1[tag1 tag2].ext"
        local file2="_test/file2.ext"
        touch "$file1" "$file2"
        When call tss tag add tag3 "$file1" "$file2"
        The file "$file1" should not be exist
        The file "_test/file1[tag1 tag2 tag3].ext" should be exist
        The file "$file2" should not be exist
        The file "_test/file2[tag3].ext" should be exist
      End

      It 'adds several tags to a file, normalizing spaces'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tss tag add ' tag3   tag4 ' "$file"
        The file "$file" should not be exist
        The file "_test/file[tag1 tag2 tag3 tag4].ext" should be exist
      End

      It 'only adds missing tags to a file'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tss tag add 'tag1 tag3' "$file"
        The file "$file" should not be exist
        The file "_test/file[tag1 tag2 tag3].ext" should be exist
      End
    End

    Describe 'files'
      It 'lists files with the given tag'
        local file1="_test/file1[tag1 tag2].ext"
        local file2="_test/file2[tag1].ext"
        local file3="_test/file3[tag2].ext"
        touch "$file1" "$file2" "$file3"
        When call tss tag files tag1 "_test"
        The status should equal 0
        The output should equal "$file1
$file2"
      End

      It 'lists a file from a subdirectory'
        local subdir="_test/subdir"
        mkdir "$subdir"
        touch "$subdir/file1[tag1].ext"
        When call tss tag files tag1 "_test"
        The status should equal 0
        The output should equal "$subdir/file1[tag1].ext"
      End

      It "lists files that don't match the given tag patterns"
        local file1="_test/file1[tag1 tag2].ext"
        local file2="_test/file2[tag3].ext"
        local file3="_test/file3[tag4].ext"
        touch "$file1" "$file2" "$file3"
        When call tss tag files '' -T 'tag1 tag3' "_test"
        The status should equal 0
        The output should equal "$file3"
      End
    End

    Describe 'remove'
      It "rejects tag pattern '*'"
        When call tss tag remove '*' '_test/file'
        The status should equal 1
        The stderr should not equal ""
      End

      It 'rejects a directory'
        local dir="_test/dir"
        mkdir "$dir"
        When call tss tag remove tag "$dir"
        The status should equal 1
        The stderr should not equal ""
        The path "$dir" should be directory
      End

      It 'removes a tag matching a pattern from a file with a tag group'
        local file="_test/file[tag11 tag22].ext"
        touch "$file"
        When call tss tag remove 'tag1*' "$file"
        The file "$file" should not be exist
        The file "_test/file[tag22].ext" should be exist
      End

      It 'leaves a file without the given tag unchanged'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tss tag remove tag3 "$file"
        The file "$file" should be exist
      End

      It 'leaves a file with no tag group unchanged'
        local file="_test/file.ext"
        touch "$file"
        When call tss tag remove tag "$file"
        The file "$file" should be exist
      End

      It 'removes a tag from several files'
        local file1="_test/file1[tag1 tag2].ext"
        local file2="_test/file2[tag1 tag2].ext"
        touch "$file1" "$file2"
        When call tss tag remove tag1 "$file1" "$file2"
        The file "$file1" should not be exist
        The file "_test/file1[tag2].ext" should be exist
        The file "$file2" should not be exist
        The file "_test/file2[tag2].ext" should be exist
      End

      It 'removes several tags from a file'
        local file="_test/file[tag1 tag2 tag3 tag4].ext"
        touch "$file"
        When call tss tag remove 'tag1 tag3' "$file"
        The file "$file" should not be exist
        The file "_test/file[tag2 tag4].ext" should be exist
      End
    End
  End
End
