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
    Describe 'tags'
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

  Describe 'tag'
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
  End
End
