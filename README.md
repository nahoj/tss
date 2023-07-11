A command-line tool to manage files with tags, with completion provided for zsh.

**tss** manages [TagSpaces](https://www.tagspaces.org/)-style tags, i.e., tags in file names such as `IMG-2653[vacation alps].jpg`.

## Basic features

```shell
$ ls
IMG-2653.jpg
$ tss add 'vacation alps' IMG-2653.jpg
$ tss files -t 'alps' *
IMG-2653[vacation alps].jpg
$ cp "IMG-2653[vacation alps].jpg" "IMG-2653_copy[vacation alps copy].jpg"
$ tss files -t 'alps' -T 'copy' *  # or --tags 'alps' --not-tags 'copy'
IMG-2653[vacation alps].jpg
```

Supports [glob patterns](https://zsh.sourceforge.io/Doc/Release/Expansion.html#Glob-Operators):
```shell
$ tss remove 'v* a*' "IMG-2653_copy[vacation alps copy].jpg"
$ find | tss filter -t '(alps|pyrenees)'
./IMG-2653[vacation alps].jpg
```

## Pros

A very simple, powerful but zero-commitment concept:

1. By now you understand how you could tag and search your files with tools you already have: your file manager, basic commands, `vidir`, etc. Feel free to try it by yourself and come back in a month if you like it.
2. Install `tss` (or TagSpaces for a graphical tool) and you get more efficient and powerful actions and queries.
3. **(still under development)** Define a *location* (root directory where your tagged files are) and queries/completion get faster.
4. Uninstall at any time without any loss of data.

## Requirements

- `zsh >=5.8`. `tss` can be run from any shell but completions are provided for zsh only.
- `jq`
- (to install) `make`
- (to test) `shellspec`

## Install

```shell
make install
```

To update:

```shell
git pull
make install
```
