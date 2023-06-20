Describe 'tsp.zsh'
  Include functions/tsp.zsh
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  Describe 'tsp file add'
    It 'adds a tag to a file with a tag group'
      local file="_test/file[tag1 tag2].ext"
      touch "$file"
      When call tsp file add tag3 "$file"
      The file "$file" should not be exist
      The file "_test/file[tag1 tag2 tag3].ext" should be exist
    End

    It 'adds a tag to a file with an empty tag group'
      local file="_test/file[].ext"
      touch "$file"
      When call tsp file add tag "$file"
      The file "$file" should not be exist
      The file "_test/file[tag].ext" should be exist
    End

    It 'adds a tag to a file with no tag group and which has an extension'
      local file="_test/file.ext"
      touch "$file"
      When call tsp file add tag "$file"
      The file "$file" should not be exist
      The file "_test/file[tag].ext" should be exist
    End

    It 'adds a tag to a file with no tag group and no extension'
      local file="_test/file"
      touch "$file"
      When call tsp file add tag "$file"
      The file "$file" should not be exist
      The file "_test/file[tag]" should be exist
    End
  End

  Describe 'tsp file clean'
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
  End

  Describe 'tsp file has'
    It 'returns 0 if a file has the given tag'
      local file="_test/file[t u v].ext"
      touch "$file"
      When call tsp file has u "$file"
      The status should equal 0
    End

    It 'returns 1 if a file does not have the given tag'
      local file="_test/file[t].ext"
      touch "$file"
      When call tsp file has u "$file"
      The status should equal 1
    End
  End

  Describe 'tsp file list'
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

  Describe 'tsp file remove'
    It 'removes a tag from a file with a tag group'
      local file="_test/file[tag1 tag2].ext"
      touch "$file"
      When call tsp file remove tag1 "$file"
      The file "$file" should not be exist
      The file "_test/file[tag2].ext" should be exist
    End

    It 'leaves a file without the given tag unchanged'
      local file="_test/file[tag1 tag2].ext"
      touch "$file"
      When call tsp file remove tag3 "$file"
      The file "$file" should be exist
    End

    It 'leaves a file with no tag group unchanged'
      local file="_test/file.ext"
      touch "$file"
      When call tsp file remove tag "$file"
      The file "$file" should be exist
    End
  End
End
