Describe 'tss remove'
  export TSS_PATH=$(realpath src/modules); . src/functions/tss.zsh
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  It "rejects tag pattern '*'"
    When call tss remove '*' '_test/file'
    The status should equal 1
    The stderr should not equal ""
  End

  It 'rejects a directory'
    local dir="_test/dir"
    mkdir "$dir"
    When call tss remove tag "$dir"
    The status should equal 1
    The stderr should not equal ""
    The path "$dir" should be directory
  End

  It 'removes a tag matching a pattern from a file with a tag group'
    local file="_test/file[tag11 tag22].ext"
    touch "$file"
    When call tss remove 'tag1*' "$file"
    The file "$file" should not be exist
    The file "_test/file[tag22].ext" should be exist
  End

  It 'leaves a file without the given tag unchanged'
    local file="_test/file[tag1 tag2].ext"
    touch "$file"
    When call tss remove tag3 "$file"
    The file "$file" should be exist
  End

  It 'leaves a file with no tag group unchanged'
    local file="_test/file.ext"
    touch "$file"
    When call tss remove tag "$file"
    The file "$file" should be exist
  End

  It 'removes a tag from several files'
    local file1="_test/file1[tag1 tag2].ext"
    local file2="_test/file2[tag1 tag2].ext"
    touch "$file1" "$file2"
    When call tss remove tag1 "$file1" "$file2"
    The file "$file1" should not be exist
    The file "_test/file1[tag2].ext" should be exist
    The file "$file2" should not be exist
    The file "_test/file2[tag2].ext" should be exist
  End

  It 'removes several tags from a file'
    local file="_test/file[tag1 tag2 tag3 tag4].ext"
    touch "$file"
    When call tss remove 'tag1 tag3' "$file"
    The file "$file" should not be exist
    The file "_test/file[tag2 tag4].ext" should be exist
  End

  ExampleGroup 'Special characters'
    Example
      local file="_test/file[a *].ext"
      touch "$file"
      When call tss remove '*[*]*' "$file"
      The status should equal 0
      The file "_test/file[a].ext" should be exist
    End

    Example
      local file="_test/file[a].ext"
      touch "$file"
      When call tss remove '*[*]*' "$file"
      The status should equal 0
      The file "$file" should be exist
    End
  End
End
