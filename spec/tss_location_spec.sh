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

  # Paths must never be re-parsed as shell code, nor taken for command options
  Describe 'index build with special characters in paths'
    # Work inside _test so that any word of a mis-parsed path lands there
    BeforeEach 'cd _test'
    AfterEach 'cd "$SHELLSPEC_PROJECT_ROOT"'

    # Run tss with the given arguments, then print the current directory.
    # Meant for 'When run': 'When call' runs its command on the left of '&&',
    # a context in which the index build currently fails for an unrelated
    # reason (err_return triggered by '(( i++ ))' when i is 0).
    tss_then_pwd() {
      tss "$@"
      print -r -- "$PWD"
    }

    Describe 'in the location path'
      Parameters
        'a space'          'loc with space'
        'a single quote'   "loc'quote"
        'a double quote'   'loc"quote'
        'a dollar sign'    'loc$x'
        'a semicolon'      'loc;x'
        'an asterisk'      'loc*'
        'all of the above' "loc \"'\$x;*"
      End

      It "inits a location whose path contains $1"
        local loc=$2
        mkdir -- "$loc"
        touch -- "$loc/file.ext"
        When run tss_then_pwd location init "$loc"
        The status should equal 0
        The output should equal "$PWD"
        The stderr should include "Building index"
        The contents of file "$loc/.ts/tsi.json" should include '"name": "file.ext"'
        The path "$loc/.ts/tsi.json.LOCK" should not be exist
      End
    End

    Describe 'in the current directory'
      Parameters
        'a space'          'dir with space'
        'a single quote'   "dir'quote"
        'a double quote'   'dir"quote'
        'a dollar sign'    'dir$x'
        'a semicolon'      'dir;x'
        'an asterisk'      'dir*'
        'all of the above' "dir \"'\$x;*"
      End

      It "builds the index and restores the current directory if its path contains $1"
        local loc=$PWD/loc
        # The sibling dir would also be matched if "$2" were used as a glob
        mkdir -p -- "$loc/.ts" "$loc/$2" "$loc/${2}_sibling"
        print -r '[]' >"$loc/.ts/tsi.json"
        touch -- "$loc/file.ext"
        cd -- "$loc/$2"
        When run tss_then_pwd location index build "$loc"
        The status should equal 0
        The output should equal "$loc/$2"
        The stderr should include "Building index"
        The contents of file "$loc/.ts/tsi.json" should include '"name": "file.ext"'
        The path "$loc/.ts/tsi.json.LOCK" should not be exist
      End
    End

    It 'does not delete files named after parts of a location path with spaces'
      local loc='loc with space'
      mkdir -- "$loc"
      touch -- "$loc/file.ext"
      touch loc with space
      When run tss_then_pwd location init "$loc"
      The status should equal 0
      The output should equal "$PWD"
      The stderr should include "Building index"
      The contents of file "$loc/.ts/tsi.json" should include '"name": "file.ext"'
      The file loc should be exist
      The file with should be exist
      The file space should be exist
    End

    Describe 'with a leading dash or plus sign'
      Parameters
        '-1'
        '+1'
        '-'
      End

      It "builds the index of a location named '$1'"
        local loc=$1
        mkdir -p -- "$loc/.ts"
        print -r '[]' >"$loc/.ts/tsi.json"
        touch -- "$loc/file.ext"
        When run tss_then_pwd location index build "$loc"
        The status should equal 0
        The output should equal "$PWD"
        The stderr should include "Building index"
        The contents of file "$loc/.ts/tsi.json" should include '"name": "file.ext"'
        The path "$loc/.ts/tsi.json.LOCK" should not be exist
      End
    End

    Describe 'containing a command substitution'
      Parameters
        '$(touch tss_marker)'
        '`touch tss_marker`'
      End

      markers() { find "$SHELLSPEC_PROJECT_ROOT/_test" -name tss_marker; }

      It "does not execute $1 in the location path"
        local loc="loc$1"
        mkdir -- "$loc"
        When run tss_then_pwd location init "$loc"
        The status should equal 0
        The output should equal "$PWD"
        The stderr should include "Building index"
        The path "$loc/.ts/tsi.json" should be file
        The result of function markers should equal ""
      End

      It "does not execute $1 in the current directory"
        local loc=$PWD/loc
        mkdir -p -- "$loc/.ts" "$loc/dir$1"
        print -r '[]' >"$loc/.ts/tsi.json"
        cd -- "$loc/dir$1"
        When run tss_then_pwd location index build "$loc"
        The status should equal 0
        The output should equal "$loc/dir$1"
        The stderr should include "Building index"
        The result of function markers should equal ""
      End
    End
  End
End
