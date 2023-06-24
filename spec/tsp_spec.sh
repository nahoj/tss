Describe 'tsp'
  Include src/util.zsh
  Include src/file.zsh
  Include src/tag.zsh
  Include src/main.zsh
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  Describe 'file'

    Describe 'clean'
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

    Describe 'list'
      It 'lists tags for a file with tags'
        local file="_test/file[tag1 tag2].ext"
        touch "$file"
        When call tsp file list "$file"
        The output should equal 'tag1 tag2'
      End

      It 'lists tags for a file with an empty tag group'
        local file="_test/file[].ext"
        touch "$file"
        When call tsp file list "$file"
        The output should equal ''
      End

      It 'lists tags for a file with no tag group'
        local file="_test/file.ext"
        touch "$file"
        When call tsp file list "$file"
        The output should equal ''
      End
    End
  End

  Describe 'tag'

    Describe 'add'
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

    Describe 'remove'
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
        ls _test
        The file "$file" should not be exist
        The file "_test/file[tag2 tag4].ext" should be exist
      End
    End
  End
End
