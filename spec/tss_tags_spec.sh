Describe 'tss tags'
  export TSS_PATH=$(realpath src/modules); . src/functions/tss.zsh
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  ExampleGroup 'Single file'
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

  ExampleGroup 'Directory'
    It 'rejects a directory that does not exist'
      When call tss tags _test/dir
      The status should equal 1
      The stderr should not equal ""
    End

    It 'defaults to . if no argument is given'
      local file1="_test/file1[tag1]"
      touch "$file1"
      pushd _test >/dev/null
      When call tss tags
      popd >/dev/null
      The status should equal 0
      The output should equal "tag1"
    End

    It 'outputs unique, sorted tags'
      mkdir _test/dir
      local file1="_test/dir/file1[tag3 tag2]"
      local file2="_test/dir/file2[tag2 tag1].ext"
      touch "$file1" "$file2"
      When call tss tags _test/dir
      The status should equal 0
      The output should equal "tag1 tag2 tag3"
    End

    It 'outputs nothing if there are no tags'
      mkdir _test/dir
      local file1="_test/dir/file1"
      local file2="_test/dir/file2.ext"
      touch "$file1" "$file2"
      When call tss tags _test/dir
      The status should equal 0
      The output should equal ""
    End

    It 'outputs the tags of all files in the directory recursively'
      mkdir -p _test/dir1/dir2
      local file1="_test/dir1/dir2/file1[tag1 tag2]"
      local file2="_test/dir1/dir2/file2[tag3].ext"
      touch "$file1" "$file2"
      When call tss tags _test/dir1
      The status should equal 0
      The output should equal "tag1 tag2 tag3"
    End
  End
End
