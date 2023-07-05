Describe 'tss tags'
  alias tss='src/tss'
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  It 'lists tags for a file with tags'
    local file="_test/file[tag1 tag2].ext"
    touch "$file"
    When call tss tags "$file"
    The output should equal 'tag1 tag2'
  End

  It 'lists tags for a file with an empty tag group'
    local file="_test/file[].ext"
    touch "$file"
    When call tss tags "$file"
    The output should equal ''
  End

  It 'lists tags for a file with no tag group'
    local file="_test/file.ext"
    touch "$file"
    When call tss tags "$file"
    The output should equal ''
  End
End
