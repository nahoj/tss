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

  Describe 'index build'
    BeforeEach 'cd _test && make_location'
    AfterEach 'cd "$SHELLSPEC_PROJECT_ROOT"'

    make_location() {
      mkdir -p loc/.ts
      print -r '[]' >loc/.ts/tsi.json
      touch loc/a.ext loc/b.ext loc/c.ext
    }

    # Sorted names in the index, on one line
    index_names() { jq -r '[.[].name] | sort | join(" ")' loc/.ts/tsi.json; }
    ts_contents() { ls -A loc/.ts; }

    # Run tss in the given context, keeping its status (or 1 for 'if'). zsh
    # applies err_return differently in a function called on the left of '||'
    # or '&&' or as an 'if' condition, e.g. in the completion function.
    tss_in() {
      local context=$1
      shift
      case $context in
        '||') tss "$@" || return ;;
        '&&') tss "$@" && : ;;
        if) if tss "$@"; then :; else return 1; fi ;;
      esac
    }

    Describe 'in a condition'
      Parameters
        'on the left of ||'   '||'
        'on the left of &&'   '&&'
        'as an if condition'  if
      End

      It "builds the complete index when run $1"
        When run tss_in "$2" location index build loc
        The status should equal 0
        The stderr should include "Building index"
        The result of function index_names should equal ". a.ext b.ext c.ext"
        The result of function ts_contents should equal tsi.json
      End

      It "inits a location with a complete index when run $1"
        rm -r loc/.ts
        When run tss_in "$2" location init loc
        The status should equal 0
        The stderr should include "Building index"
        The result of function index_names should equal ". a.ext b.ext c.ext"
        The result of function ts_contents should equal tsi.json
      End
    End

    It 'inits a location with no files'
      rm -r loc/.ts loc/*.ext
      When run tss location init loc
      The status should equal 0
      The stderr should include "Building index"
      The result of function index_names should equal "."
      The result of function ts_contents should equal tsi.json
    End
  End

  # Paths must never be re-parsed as shell code, nor taken for command options
  Describe 'index build with special characters in paths'
    # Work inside _test so that any word of a mis-parsed path lands there
    BeforeEach 'cd _test'
    AfterEach 'cd "$SHELLSPEC_PROJECT_ROOT"'

    # Run tss with the given arguments, then print the current directory
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

  # The contents of .ts may come from an untrusted source: writes there must
  # never go through a symlink, which could point to any file
  Describe 'with symlinks in .ts'
    # Symlinks point to 'target' and 'missing', outside the location
    BeforeEach 'cd _test && make_location && print -r original >target'
    AfterEach 'cd "$SHELLSPEC_PROJECT_ROOT"'

    make_location() {
      mkdir -p loc/.ts
      print -r '[]' >loc/.ts/tsi.json
      touch loc/file.ext
    }

    ts_contents() { ls -A loc/.ts; }
    other_contents() { ls -A other; }

    # Run tss with a 'find' command that fails
    tss_with_failing_find() {
      mkdir bin
      printf '#!/bin/sh\nexit 1\n' >bin/find
      chmod +x bin/find
      PATH="$PWD/bin:$PATH" tss "$@"
    }

    # Run tss on the left of '||'
    tss_or_true() {
      tss "$@" || true
    }

    Describe 'at tsi.json.NEW'
      Parameters
        'an existing file'    target
        'a nonexistent file'  missing
      End

      It "builds the index without writing to $1 it points to"
        ln -s "$PWD/$2" loc/.ts/tsi.json.NEW
        When run tss location index build loc
        The status should equal 0
        The stderr should include "Building index"
        The contents of file loc/.ts/tsi.json should include '"name": "file.ext"'
        The result of function ts_contents should equal tsi.json
        The contents of file target should equal original
        The path missing should not be exist
      End
    End

    It 'builds the index despite a leftover tsi.json.NEW'
      print -r garbage >loc/.ts/tsi.json.NEW
      When run tss location index build loc
      The status should equal 0
      The stderr should include "Building index"
      The contents of file loc/.ts/tsi.json should include '"name": "file.ext"'
      The result of function ts_contents should equal tsi.json
    End

    Describe 'at tsi.json.LOCK'
      Parameters
        'an existing file'    target
        'a nonexistent file'  missing
      End

      It "reports the lock without writing to $1 it points to"
        ln -s "$PWD/$2" loc/.ts/tsi.json.LOCK
        When run tss location index build loc
        The status should equal 1
        The stderr should include "File is locked"
        The path loc/.ts/tsi.json.LOCK should be symlink
        The contents of file loc/.ts/tsi.json should equal '[]'
        The contents of file target should equal original
        The path missing should not be exist
      End
    End

    It 'reports the lock if tsi.json.LOCK is a file'
      touch loc/.ts/tsi.json.LOCK
      When run tss location index build loc
      The status should equal 1
      The stderr should include "File is locked"
      The path loc/.ts/tsi.json.LOCK should be file
      The contents of file loc/.ts/tsi.json should equal '[]'
    End

    Describe 'replacing .ts'
      BeforeEach 'mkdir other && rm -r loc/.ts && ln -s "$PWD/other" loc/.ts'

      It 'refuses to build the index'
        print -r '[]' >other/tsi.json
        When run tss location index build loc
        The status should equal 1
        The stderr should include "symbolic link"
        The result of function other_contents should equal tsi.json
        The contents of file other/tsi.json should equal '[]'
      End

      It 'refuses to init a location'
        When run tss location init loc
        The status should equal 1
        The stderr should include "symbolic link"
        The result of function other_contents should equal ""
      End
    End

    It 'does not init a location by writing to a nonexistent file tsi.json points to'
      rm loc/.ts/tsi.json
      ln -s "$PWD/missing" loc/.ts/tsi.json
      When run tss location init loc
      The status should equal 1
      The stderr should include "loc/.ts/tsi.json"
      The path missing should not be exist
    End

    It 'leaves no temporary file in .ts after a successful build'
      When run tss location index build loc
      The status should equal 0
      The stderr should include "Building index"
      The result of function ts_contents should equal tsi.json
    End

    It 'leaves no temporary file in .ts after a failed build'
      When run tss_with_failing_find location index build loc
      The status should equal 1
      The stderr should include "Building index"
      The result of function ts_contents should equal tsi.json
      The contents of file loc/.ts/tsi.json should equal '[]'
    End

    It 'leaves no temporary file in .ts after a build run on the left of ||'
      touch loc/file2.ext
      When run tss_or_true location index build loc
      The status should equal 0
      The stderr should include "Building index"
      The result of function ts_contents should equal tsi.json
    End
  End

  # On SIGINT, the index build must undo what it set up (lock file, current
  # directory, temporary file), then let SIGINT reach its caller, once
  Describe 'interrupted by SIGINT'
    BeforeEach 'cd _test'
    AfterEach 'cd "$SHELLSPEC_PROJECT_ROOT"'

    # Run the given zsh code in a child zsh process where tss is loaded, and
    # where 'interrupt' sends SIGINT to the current process, as an external
    # command does below. SIGINT kills the process unless the code traps it.
    run_zsh() {
      zsh -f -c '
        . "$1/src/functions/tss.zsh"
        interrupt() {
          sh -c "kill -s INT \$PPID"
          print -r "continued after SIGINT"
        }
        eval "$2"
      ' zsh "$SHELLSPEC_PROJECT_ROOT" "$1"
    }

    Describe 'in nested blocks with a cleanup'
      # Run tss with the modules of tss plus one overriding 'tss util' to run
      # the given internal command, with tss's options and modules loaded
      BeforeEach 'make_modules && mkdir dir'

      make_modules() {
        mkdir modules
        ln -s "$TSS_PATH"/*.zsh modules/
        print -r 'tss_util() { "$@" }' >modules/zz_spec.zsh
      }

      run_zsh_with_modules() {
        TSS_PATH=$PWD/modules run_zsh "
          tmp_setup=(create_new_file tmp)
          tmp_cleanup=(rm -f -- tmp)
          $1
        "
      }

      Describe 'in the innermost command'
        # Nested as in the index build: lock file, current directory,
        # temporary file (in dir)
        Parameters
          1 'with_lock_file file interrupt'
          2 'with_lock_file file with_cd dir interrupt'
          3 'with_lock_file file with_cd dir always_with_trap_INT tmp_setup tmp_cleanup interrupt'
        End

        It "dies from SIGINT received at depth $1, after every cleanup"
          When run run_zsh_with_modules "
            tss util $2
            print -r \"returned \$?\"
          "
          The status should equal 130
          The output should equal ""
          The path file.LOCK should not be exist
          The path dir/tmp should not be exist
        End

        It "lets the caller trap SIGINT received at depth $1, once, after every cleanup"
          When run run_zsh_with_modules "
            trap 'print -r \"caller trap\"' INT
            tss util $2
            print -r \"returned \$? in \${PWD:t}\"
          "
          The status should equal 0
          The line 1 of output should equal "caller trap"
          The line 2 of output should equal "returned 130 in _test"
          The lines of output should equal 2
          The path file.LOCK should not be exist
          The path dir/tmp should not be exist
        End
      End

      It 'completes the innermost cleanup if SIGINT is received then, and dies from it after every cleanup'
        When run run_zsh_with_modules "
          tmp_cleanup=(eval 'interrupt; rm -f -- tmp')
          tss util with_lock_file file with_cd dir always_with_trap_INT tmp_setup tmp_cleanup true
          print -r \"returned \$?\"
        "
        The status should equal 130
        The output should equal "continued after SIGINT"
        The path file.LOCK should not be exist
        The path dir/tmp should not be exist
      End

      It 'lets the caller trap SIGINT even if the cleanup fails'
        When run run_zsh_with_modules "
          tmp_cleanup=(eval 'rm -f -- tmp; false')
          trap 'print -r \"caller trap\"' INT
          tss util always_with_trap_INT tmp_setup tmp_cleanup interrupt
          print -r \"returned \$?\"
        "
        The status should equal 0
        The line 1 of output should equal "caller trap"
        The line 2 of output should equal "returned 130"
        The lines of output should equal 2
        The path tmp should not be exist
      End
    End

    Describe 'during an index build'
      # 'find' interrupts tss, which runs it in the build's innermost block
      BeforeEach 'make_location && make_interrupting_find'

      make_location() {
        mkdir -p loc/.ts
        print -r '[]' >loc/.ts/tsi.json
        touch loc/file.ext
      }

      make_interrupting_find() {
        mkdir bin
        printf '#!/bin/sh\nkill -s INT $PPID\n' >bin/find
        chmod +x bin/find
      }

      ts_contents() { ls -A loc/.ts; }

      Parameters
        'run'                'tss location index build loc'
        'run on the left of ||' 'tss location index build loc || print -r "failed: $?"'
      End

      It "dies from SIGINT, leaving the index unchanged and no lock or temporary file, when $1"
        When run run_zsh "
          PATH=\$PWD/bin:\$PATH
          $2
          print -r \"returned \$?\"
        "
        The status should equal 130
        The output should equal ""
        The stderr should include "Building index"
        The result of function ts_contents should equal tsi.json
        The contents of file loc/.ts/tsi.json should equal '[]'
      End
    End
  End
End
