Describe 'tss location'
  export TSS_PATH=$(realpath src/modules); . src/functions/tss.zsh
  BeforeEach 'rm -rf _test && mkdir _test'
  AfterEach 'rm -rf _test'

  Describe 'of'
    It 'rejects a nonexistent file'
      When call tss location of _test/file
      The status should equal 1
      The stderr should not equal ""
    End

    It 'returns a location under the current directory'
      local loc="_test/loc"
      mkdir -p "$loc/.ts"
      touch "$loc/.ts/tsi.json"
      local file="$loc/file.ext"
      touch "$file"
      When call tss location of "$file"
      The status should equal 0
      The output should equal "$PWD/$loc"
    End

    It 'returns a location above the current directory'
      local loc="_test/loc"
      mkdir -p "$loc/.ts"
      touch "$loc/.ts/tsi.json"
      local dir="$loc/dir"
      mkdir -p "$dir"
      cd "$dir"
      local file="file.ext"
      touch "$file"
      When call tss location of "$file"
      The status should equal 0
      The output should equal "$(realpath "..")"
      cd "$OLDPWD"
    End

    It 'returns a location unrelated to the current directory'
      local test_dir="/tmp/tss_test"
      local loc="$test_dir/loc"
      mkdir -p "$loc/.ts"
      touch "$loc/.ts/tsi.json"
      local file="$loc/file.ext"
      touch "$file"
      When call tss location of "$file"
      The status should equal 0
      The output should equal "$loc"
      rm -rf "$test_dir"
    End
  End
End
