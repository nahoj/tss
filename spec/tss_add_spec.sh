Describe 'tss add'
  export TSS_PATH=$(realpath src/modules); . src/functions/tss.zsh
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  It 'rejects an invalid tag'
    local file="_test/file.ext"
    touch "$file"
    When call tss add '[' "$file"
    The status should equal 1
    The stderr should not equal ""
    The file "$file" should be exist
  End

  It 'rejects a directory'
    local dir="_test/dir"
    mkdir "$dir"
    When call tss add tag "$dir"
    The status should equal 1
    The stderr should not equal ""
    The path "$dir" should be directory
  End

  It 'adds a tag to a file with a tag group'
    local file="_test/file[tag1 tag2].ext"
    touch "$file"
    When call tss add tag3 "$file"
    The file "$file" should not be exist
    The file "_test/file[tag1 tag2 tag3].ext" should be exist
  End

  It 'adds a tag to a file with an empty tag group'
    local file="_test/file[].ext"
    touch "$file"
    When call tss add tag "$file"
    The file "$file" should not be exist
    The file "_test/file[tag].ext" should be exist
  End

  It 'adds a tag to a file with no tag group and which has an extension'
    local file="_test/file.ext"
    touch "$file"
    When call tss add tag "$file"
    The file "$file" should not be exist
    The file "_test/file[tag].ext" should be exist
  End

  It 'adds a tag to a file with no tag group and no extension'
    local file="_test/file"
    touch "$file"
    When call tss add tag "$file"
    The file "$file" should not be exist
    The file "_test/file[tag]" should be exist
  End

  It 'adds a tag to several files'
    local file1="_test/file1[tag1 tag2].ext"
    local file2="_test/file2.ext"
    touch "$file1" "$file2"
    When call tss add tag3 "$file1" "$file2"
    The file "$file1" should not be exist
    The file "_test/file1[tag1 tag2 tag3].ext" should be exist
    The file "$file2" should not be exist
    The file "_test/file2[tag3].ext" should be exist
  End

  It 'adds several tags to a file, normalizing spaces'
    local file="_test/file[tag1 tag2].ext"
    touch "$file"
    When call tss add ' tag3   tag4 ' "$file"
    The file "$file" should not be exist
    The file "_test/file[tag1 tag2 tag3 tag4].ext" should be exist
  End

  It 'only adds missing tags to a file'
    local file="_test/file[tag1 tag2].ext"
    touch "$file"
    When call tss add 'tag1 tag3' "$file"
    The file "$file" should not be exist
    The file "_test/file[tag1 tag2 tag3].ext" should be exist
  End

  ExampleGroup 'Special characters'
    Example
      local file="_test/file[a].ext"
      touch "$file"
      When call tss add '*' "$file"
      The status should equal 0
      The file "_test/file[a *].ext" should be exist
    End

    Example
      local file="_test/file[a *].ext"
      touch "$file"
      When call tss add '*' "$file"
      The status should equal 0
      The file "$file" should be exist
    End
  End
End
