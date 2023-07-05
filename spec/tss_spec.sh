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
End
