Describe 'tss files'
  alias tss='src/tss'
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  It 'lists files with the given tag'
    local file1="_test/file1[tag1 tag2].ext"
    local file2="_test/file2[tag1].ext"
    local file3="_test/file3[tag2].ext"
    touch "$file1" "$file2" "$file3"
    When call tss files -t tag1 "_test"
    The status should equal 0
    The output should equal "$file1
$file2"
  End

  It 'lists a file from a subdirectory'
    local subdir="_test/subdir"
    mkdir "$subdir"
    touch "$subdir/file1[tag1].ext"
    When call tss files -t tag1 "_test"
    The status should equal 0
    The output should equal "$subdir/file1[tag1].ext"
  End

  It "lists files that don't match the given tag patterns"
    local file1="_test/file1[tag1 tag2].ext"
    local file2="_test/file2[tag3].ext"
    local file3="_test/file3[tag4].ext"
    touch "$file1" "$file2" "$file3"
    When call tss files -T 'tag1 tag3' "_test"
    The status should equal 0
    The output should equal "$file3"
  End
End
