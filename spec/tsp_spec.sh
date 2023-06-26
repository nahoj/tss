Describe 'tsp'
  alias tsp='src/tsp'
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  Describe 'file'

    Describe 'clean'
      It 'rejects a directory'
        mkdir _test/dir
        When call tsp file clean _test/dir
        The status should equal 1
        The output should not equal ""
        The path "_test/dir" should be directory
      End

      It 'rejects a file with an ill-formed name'
        touch "_test/file[tag1 tag2"
        When call tsp file clean "_test/file[tag1 tag2"
        The status should equal 1
        The output should not equal ""
        The file "_test/file[tag1 tag2" should be exist
      End

      It 'ignores an invalid file, cleans a valid file, and returns 1'
        local file1="_test/file1[tag1 tag2"
        local file2="_test/file2[tag3].ext"
        touch "$file1" "$file2"
        When call tsp file clean "$file1" "$file2"
        The status should equal 1
        The output should not equal ""
        The file "$file1" should be exist
        The file "$file2" should not be exist
        The file "_test/file2.ext" should be exist
      End

      It 'removes a tag group from a file with tags'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tsp file clean "$file"
        The file "$file" should not be exist
        The file "_test/file.ext" should be exist
      End

      It 'removes a tag group from a file with an empty tag group'
        local file="_test/file[].ext"
        touch "$file"
        When call tsp file clean "$file"
        The file "$file" should not be exist
        The file "_test/file.ext" should be exist
      End

      It 'leaves a file with no tag group unchanged'
        local file="_test/file.ext"
        touch "$file"
        When call tsp file clean "$file"
        The file "$file" should be exist
      End

      It 'removes a tag group from several files'
        local file1="_test/file1[tag1 tag2].ext"
        local file2="_test/file2[tag3].ext"
        touch "$file1" "$file2"
        When call tsp file clean "$file1" "$file2"
        The file "$file1" should not be exist
        The file "_test/file1.ext" should be exist
        The file "$file2" should not be exist
        The file "_test/file2.ext" should be exist
      End
    End

    Describe 'has'
      It 'rejects a nonexistent file'
        When call tsp file has _test/file tag
        The status should equal 1
        The output should not equal ""
      End

      It 'rejects a directory'
        local dir="_test/dir"
        mkdir "$dir"
        When call tsp file has _test/dir tag
        The status should equal 1
        The output should not equal ""
        The path "$dir" should be directory
      End

      It 'rejects an invalid tag'
        local file="_test/file.ext"
        touch "$file"
        When call tsp file has "$file" '['
        The status should equal 1
        The output should equal "Invalid tag: '['"
        The file "$file" should be exist
      End

      It 'returns 0 if a file has the given tag'
        local file="_test/file[t u v].ext"
        touch "$file"
        When call tsp file has "$file" u
        The status should equal 0
      End

      It 'returns 1 if a file does not have the given tag'
        local file="_test/file[t].ext"
        touch "$file"
        When call tsp file has "$file" u
        The status should equal 1
      End
    End

    Describe 'tags'
      It 'rejects a nonexistent file'
        When call tsp file tags _test/file
        The status should equal 1
        The output should not equal ""
      End

      It 'rejects a directory'
        local dir="_test/dir"
        mkdir "$dir"
        When call tsp file tags "$dir"
        The status should equal 1
        The output should not equal ""
        The path "$dir" should be directory
      End

      It 'lists tags for a file with tags'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tsp file tags "$file"
        The output should equal 'tag1 tag2'
      End

      It 'lists tags for a file with an empty tag group'
        local file="_test/file[].ext"
        touch "$file"
        When call tsp file tags "$file"
        The output should equal ''
      End

      It 'lists tags for a file with no tag group'
        local file="_test/file.ext"
        touch "$file"
        When call tsp file tags "$file"
        The output should equal ''
      End
    End
  End

  Describe 'tag'

    Describe 'add'

      It 'rejects an invalid tag'
        local file="_test/file.ext"
        touch "$file"
        When call tsp tag add '[' "$file"
        The status should equal 1
        The output should not equal ""
        The file "$file" should be exist
      End

      It 'rejects a directory'
        local dir="_test/dir"
        mkdir "$dir"
        When call tsp tag add tag "$dir"
        The status should equal 1
        The output should not equal ""
        The path "$dir" should be directory
      End

      It 'adds a tag to a file with a tag group'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tsp tag add tag3 "$file"
        The file "$file" should not be exist
        The file "_test/file[tag1 tag2 tag3].ext" should be exist
      End

      It 'adds a tag to a file with an empty tag group'
        local file="_test/file[].ext"
        touch "$file"
        When call tsp tag add tag "$file"
        The file "$file" should not be exist
        The file "_test/file[tag].ext" should be exist
      End

      It 'adds a tag to a file with no tag group and which has an extension'
        local file="_test/file.ext"
        touch "$file"
        When call tsp tag add tag "$file"
        The file "$file" should not be exist
        The file "_test/file[tag].ext" should be exist
      End

      It 'adds a tag to a file with no tag group and no extension'
        local file="_test/file"
        touch "$file"
        When call tsp tag add tag "$file"
        The file "$file" should not be exist
        The file "_test/file[tag]" should be exist
      End

      It 'adds a tag to several files'
        local file1="_test/file1[tag1 tag2].ext"
        local file2="_test/file2.ext"
        touch "$file1" "$file2"
        When call tsp tag add tag3 "$file1" "$file2"
        The file "$file1" should not be exist
        The file "_test/file1[tag1 tag2 tag3].ext" should be exist
        The file "$file2" should not be exist
        The file "_test/file2[tag3].ext" should be exist
      End

      It 'adds several tags to a file, normalizing spaces'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tsp tag add ' tag3   tag4 ' "$file"
        The file "$file" should not be exist
        The file "_test/file[tag1 tag2 tag3 tag4].ext" should be exist
      End

      It 'only adds missing tags to a file'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tsp tag add 'tag1 tag3' "$file"
        The file "$file" should not be exist
        The file "_test/file[tag1 tag2 tag3].ext" should be exist
      End
    End

    Describe 'files'
      It 'rejects an invalid tag'
        When call tsp tag files ' '
        The status should equal 1
        The output should equal "Invalid tag: ' '"
      End

      It 'lists files with the given tag'
        local file1="_test/file1[tag1 tag2].ext"
        local file2="_test/file2[tag1].ext"
        local file3="_test/file3[tag2].ext"
        touch "$file1" "$file2" "$file3"
        When call tsp tag files tag1 "_test"
        The status should equal 0
        The output should equal "$file1
$file2"
      End

      It 'lists a file from a subdirectory'
        local subdir="_test/subdir"
        mkdir "$subdir"
        touch "$subdir/file1[tag1].ext"
        When call tsp tag files tag1 "_test"
        The status should equal 0
        The output should equal "$subdir/file1[tag1].ext"
      End
    End

    Describe 'remove'

      It 'rejects an invalid tag'
        local file="_test/file.ext"
        touch "$file"
        When call tsp tag remove ']' "$file"
        The status should equal 1
        The output should not equal ""
        The file "$file" should be exist
      End

      It 'rejects a directory'
        local dir="_test/dir"
        mkdir "$dir"
        When call tsp tag remove tag "$dir"
        The status should equal 1
        The output should not equal ""
        The path "$dir" should be directory
      End

      It 'removes a tag from a file with a tag group'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tsp tag remove tag1 "$file"
        The file "$file" should not be exist
        The file "_test/file[tag2].ext" should be exist
      End

      It 'leaves a file without the given tag unchanged'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tsp tag remove tag3 "$file"
        The file "$file" should be exist
      End

      It 'leaves a file with no tag group unchanged'
        local file="_test/file.ext"
        touch "$file"
        When call tsp tag remove tag "$file"
        The file "$file" should be exist
      End

      It 'removes a tag from several files'
        local file1="_test/file1[tag1 tag2].ext"
        local file2="_test/file2[tag1 tag2].ext"
        touch "$file1" "$file2"
        When call tsp tag remove tag1 "$file1" "$file2"
        The file "$file1" should not be exist
        The file "_test/file1[tag2].ext" should be exist
        The file "$file2" should not be exist
        The file "_test/file2[tag2].ext" should be exist
      End

      It 'removes several tags from a file'
        local file="_test/file[tag1 tag2 tag3 tag4].ext"
        touch "$file"
        When call tsp tag remove 'tag1 tag3' "$file"
        The file "$file" should not be exist
        The file "_test/file[tag2 tag4].ext" should be exist
      End
    End
  End
End
