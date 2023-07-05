Describe 'tss test'
  alias tss='src/tss'

  ExampleGroup 'Basics: simple tag'
    Example
      When call tss test -t a 'file[a]'
      The status should equal 0
    End

    Example
      When call tss test -T a 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -t a 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -T a 'file[b]'
      The status should equal 0
    End

    Example
      When call tss test -t a 'dir/file[a]'
      The status should equal 0
    End

    Example
      When call tss test -T a 'dir/file[a]'
      The status should equal 1
    End

    Example
      When call tss test -t a 'dir/file[b]'
      The status should equal 1
    End

    Example
      When call tss test -T a 'dir/file[b]'
      The status should equal 0
    End
  End

  ExampleGroup 'Basics: pattern'
    Example
      When call tss test -t '*a*' 'file[aa]'
      The status should equal 0
    End

    Example
      When call tss test -T '*a*' 'file[aa]'
      The status should equal 1
    End

    Example
      When call tss test -t '*a*' 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -T '*a*' 'file[b]'
      The status should equal 0
    End

    Example
      When call tss test -t '*a*' 'dir/file[aa]'
      The status should equal 0
    End

    Example
      When call tss test -T '*a*' 'dir/file[aa]'
      The status should equal 1
    End

    Example
      When call tss test -t '*a*' 'dir/file[b]'
      The status should equal 1
    End

    Example
      When call tss test -T '*a*' 'dir/file[b]'
      The status should equal 0
    End
  End

  ExampleGroup 'File name structure'
    Example
      When call tss test -t a 'file'
      The status should equal 1
    End

    Example
      When call tss test -T a 'file'
      The status should equal 0
    End

    Example
      When call tss test -t a 'file[]'
      The status should equal 1
    End

    Example
      When call tss test -T a 'file[]'
      The status should equal 0
    End

    Example
      When call tss test -t a 'file[a].ext'
      The status should equal 0
    End

    Example
      When call tss test -T a 'file[a].ext'
      The status should equal 1
    End

    Example
      When call tss test -t a '[a]file'
      The status should equal 0
    End

    Example
      When call tss test -T a '[a]file'
      The status should equal 1
    End

    Example
      When call tss test -t a 'file.ext[a]'
      The status should equal 0
    End

    Example
      When call tss test -T a 'file.ext[a]'
      The status should equal 1
    End

    Example
      When call tss test -t a 'file[a'
      The status should equal 1
    End

    Example
      When call tss test -T a 'file[a'
      The status should equal 0
    End

    Example
      When call tss test -t a 'file a]'
      The status should equal 1
    End

    Example
      When call tss test -T a 'file a]'
      The status should equal 0
    End

  End

  ExampleGroup 'The 4 tag positions'
    Example
      When call tss test -t a 'file[a]'
      The status should equal 0
    End

    Example
      When call tss test -T a 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -t a 'file[a b]'
      The status should equal 0
    End

    Example
      When call tss test -T a 'file[a b]'
      The status should equal 1
    End

    Example
      When call tss test -t a 'file[b a]'
      The status should equal 0
    End

    Example
      When call tss test -T a 'file[b a]'
      The status should equal 1
    End

    Example
      When call tss test -t a 'file[b a c]'
      The status should equal 0
    End

    Example
      When call tss test -T a 'file[b a c]'
      The status should equal 1
    End
  End

  ExampleGroup 'Multiple tags: one opt'
    Example
      When call tss test -t 'a b' 'file[a b]'
      The status should equal 0
    End

    Example
      When call tss test -T 'a b' 'file[a b]'
      The status should equal 1
    End

    Example
      When call tss test -t 'a b' 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -T 'a b' 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -t 'a b' 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -T 'a b' 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -t 'a b' 'file'
      The status should equal 1
    End

    Example
      When call tss test -T 'a b' 'file'
      The status should equal 0
    End
  End

  ExampleGroup 'Multiple tags: two opts'
    Example
      When call tss test -t a -t b 'file[a b]'
      The status should equal 0
    End

    Example
      When call tss test -T a -T b 'file[a b]'
      The status should equal 1
    End

    Example
      When call tss test -t a -t b 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -T a -T b 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -t a -t b 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -T a -T b 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -t a -t b 'file'
      The status should equal 1
    End

    Example
      When call tss test -T a -T b 'file'
      The status should equal 0
    End
  End

  ExampleGroup 'Multiple tags: mixing -t and -T'
    Example
      When call tss test -t a -T b 'file[a b]'
      The status should equal 1
    End

    Example
      When call tss test -t a -T b 'file[a]'
      The status should equal 0
    End

    Example
      When call tss test -t a -T b 'file[b]'
      The status should equal 1
    End

    Example
      When call tss test -t a -T b 'file'
      The status should equal 1
    End

    Example
      When call tss test -t a -T a 'file[a]'
      The status should equal 1
    End

    Example
      When call tss test -t a -T a 'file'
      The status should equal 1
    End
  End
End
