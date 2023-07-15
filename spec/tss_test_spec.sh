Describe 'tss test'
  export TSS_PATH=$(realpath src/modules); . src/functions/tss.zsh

  ExampleGroup 'Not name-only'
    BeforeEach 'rm -rf _test && mkdir _test'
    AfterEach 'rm -rf _test'

    Example
      When call tss test '_test/file'
      The status should equal 2
      The error should not equal ''
    End

    Example
      mkdir '_test/dir[a]'
      When call tss test -t a '_test/dir[a]'
      The status should equal 1
    End

    Example
      mkfifo '_test/fifo[a]'
      When call tss test -t a '_test/fifo[a]'
      The status should equal 1
    End

    Example
      touch '_test/file[a]'
      When call tss test -t a '_test/file[a]'
      The status should equal 0
    End
  End

  ExampleGroup 'Basics: simple tag'
    Example
      When call tss test -n -t a 'file[a]'
      The status should equal 0
    End

    Example
      When call tss test -n -T a 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -n -T a 'file[b]'
      The status should equal 0
    End

    Example
      When call tss test -n -t a 'dir/file[a]'
      The status should equal 0
    End

    Example
      When call tss test -n -T a 'dir/file[a]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a 'dir/file[b]'
      The status should equal 1
    End

    Example
      When call tss test -n -T a 'dir/file[b]'
      The status should equal 0
    End
  End

  ExampleGroup 'Basics: pattern'
    Example
      When call tss test -n -t '*a*' 'file[aa]'
      The status should equal 0
    End

    Example
      When call tss test -n -T '*a*' 'file[aa]'
      The status should equal 1
    End

    Example
      When call tss test -n -t '*a*' 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -n -T '*a*' 'file[b]'
      The status should equal 0
    End

    Example
      When call tss test -n -t '*a*' 'dir/file[aa]'
      The status should equal 0
    End

    Example
      When call tss test -n -T '*a*' 'dir/file[aa]'
      The status should equal 1
    End

    Example
      When call tss test -n -t '*a*' 'dir/file[b]'
      The status should equal 1
    End

    Example
      When call tss test -n -T '*a*' 'dir/file[b]'
      The status should equal 0
    End
  End

  ExampleGroup 'Special characters'
    Example
      When call tss test -n -t 'a[*]b' 'file[a*b]'
      The status should equal 0
    End

    Example
      When call tss test -n -t 'a[*]b' 'file[a?b]'
      The status should equal 1
    End

    Example
      When call tss test -n -T 'a[*]b' 'file[a*b]'
      The status should equal 1
    End

    Example
      When call tss test -n -T 'a[*]b' 'file[a?b]'
      The status should equal 0
    End
  End

  ExampleGroup 'File name structure'
    Example
      When call tss test -n -t a 'file'
      The status should equal 1
    End

    Example
      When call tss test -n -T a 'file'
      The status should equal 0
    End

    Example
      When call tss test -n -t a 'file[]'
      The status should equal 1
    End

    Example
      When call tss test -n -T a 'file[]'
      The status should equal 0
    End

    Example
      When call tss test -n -t a 'file[a].ext'
      The status should equal 0
    End

    Example
      When call tss test -n -T a 'file[a].ext'
      The status should equal 1
    End

    Example
      When call tss test -n -t a '[a]file'
      The status should equal 0
    End

    Example
      When call tss test -n -T a '[a]file'
      The status should equal 1
    End

    Example
      When call tss test -n -t a 'file.ext[a]'
      The status should equal 0
    End

    Example
      When call tss test -n -T a 'file.ext[a]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a 'file[a'
      The status should equal 1
    End

    Example
      When call tss test -n -T a 'file[a'
      The status should equal 0
    End

    Example
      When call tss test -n -t a 'file a]'
      The status should equal 1
    End

    Example
      When call tss test -n -T a 'file a]'
      The status should equal 0
    End

  End

  ExampleGroup 'The 4 tag positions'
    Example
      When call tss test -n -t a 'file[a]'
      The status should equal 0
    End

    Example
      When call tss test -n -T a 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a 'file[a b]'
      The status should equal 0
    End

    Example
      When call tss test -n -T a 'file[a b]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a 'file[b a]'
      The status should equal 0
    End

    Example
      When call tss test -n -T a 'file[b a]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a 'file[b a c]'
      The status should equal 0
    End

    Example
      When call tss test -n -T a 'file[b a c]'
      The status should equal 1
    End
  End

  ExampleGroup 'Multiple tags: one opt'
    Example
      When call tss test -n -t 'a b' 'file[a b]'
      The status should equal 0
    End

    Example
      When call tss test -n -T 'a b' 'file[a b]'
      The status should equal 1
    End

    Example
      When call tss test -n -t 'a b' 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -n -T 'a b' 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -n -t 'a b' 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -n -T 'a b' 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -n -t 'a b' 'file'
      The status should equal 1
    End

    Example
      When call tss test -n -T 'a b' 'file'
      The status should equal 0
    End
  End

  ExampleGroup 'Multiple tags: two opts'
    Example
      When call tss test -n -t a -t b 'file[a b]'
      The status should equal 0
    End

    Example
      When call tss test -n -T a -T b 'file[a b]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a -t b 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -n -T a -T b 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a -t b 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -n -T a -T b 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a -t b 'file'
      The status should equal 1
    End

    Example
      When call tss test -n -T a -T b 'file'
      The status should equal 0
    End
  End

  ExampleGroup 'Multiple tags: mixing -t and -T'
    Example
      When call tss test -n -t a -T b 'file[a b]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a -T b 'file[a]'
      The status should equal 0
    End

    Example
      When call tss test -n -t a -T b 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a -T b 'file'
      The status should equal 1
    End

    Example
      When call tss test -n -t a -T a 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -n -t a -T a 'file'
      The status should equal 1
    End
  End
End
