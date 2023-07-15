Describe 'tss clean'
  export TSS_PATH=$(realpath src/modules); . src/functions/tss.zsh
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  It 'rejects a directory'
    mkdir _test/dir
    When call tss clean _test/dir
    The status should equal 1
    The stderr should not equal ""
    The path "_test/dir" should be directory
  End

  It 'rejects a file with an ill-formed name'
    touch "_test/file[tag1 tag2"
    When call tss clean "_test/file[tag1 tag2"
    The status should equal 1
    The stderr should not equal ""
    The file "_test/file[tag1 tag2" should be exist
  End

  It 'ignores an invalid file, cleans a valid file, and returns 1'
    local file1="_test/file1[tag1 tag2"
    local file2="_test/file2[tag3].ext"
    touch "$file1" "$file2"
    When call tss clean "$file1" "$file2"
    The status should equal 1
    The stderr should not equal ""
    The file "$file1" should be exist
    The file "$file2" should not be exist
    The file "_test/file2.ext" should be exist
  End

  It 'removes a tag group from a file with tags'
    local file="_test/file[tag1 tag2].ext"
    touch "$file"
    When call tss clean "$file"
    The file "$file" should not be exist
    The file "_test/file.ext" should be exist
  End

  It 'removes a tag group from a file with an empty tag group'
    local file="_test/file[].ext"
    touch "$file"
    When call tss clean "$file"
    The file "$file" should not be exist
    The file "_test/file.ext" should be exist
  End

  It 'leaves a file with no tag group unchanged'
    local file="_test/file.ext"
    touch "$file"
    When call tss clean "$file"
    The file "$file" should be exist
  End

  It 'removes a tag group from several files'
    local file1="_test/file1[tag1 tag2].ext"
    local file2="_test/file2[tag3].ext"
    touch "$file1" "$file2"
    When call tss clean "$file1" "$file2"
    The file "$file1" should not be exist
    The file "_test/file1.ext" should be exist
    The file "$file2" should not be exist
    The file "_test/file2.ext" should be exist
  End
End
