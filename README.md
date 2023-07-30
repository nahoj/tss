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

Supports (extended) [glob patterns](https://zsh.sourceforge.io/Doc/Release/Expansion.html#Glob-Operators):
```shell
$ tss remove 'v* a*' "IMG-2653_copy[vacation alps copy].jpg"
$ find | tss filter -t '(alps|pyrenees)'
./IMG-2653[vacation alps].jpg
```

Completion is designed as an integral part of the program. Queries are basically run as you tab-complete:
```shell
$ tss query -t tag1 <tab>           # Files with tag1
$ tss query -t tag1 path/ -t <tab>  # Tags found on files that have tag1 in path/
$ tss add tag1 <tab>                # Files that don't have tag1
```

Common tag suggestions added to `.zshrc`, which you can edit to your liking:
```shell
tss_tags_ratings=(1star 2star 3star 4star 5star)
tss_tags_media=(toread reading read towatch watched)
tss_tags_workflow=(todo draft done published)
tss_tags_life=(family friends personal school vacation work other)
```

You can declare one or more *locations* (paths where you keep tagged files) to get improved tag suggestions for files under them. I consider it a secondary feature. Requires `jq`. `tss` will detect TagSpaces locations.
```shell
$ tss location init ~/photos  # That's it
```

## Pros

A very simple, effective but zero-commitment concept:

1. By now you understand how you could tag and search your files with tools you already have: your file manager and desktop search, basic commands, `vidir`, etc. Feel free to try it by yourself and come back in a month if you like it.
2. Install `tss` (or TagSpaces for a graphical tool) and you get more efficient and powerful actions and queries.
3. Uninstall at any time without any loss of data.

## Requirements

- `zsh >=5.8`. `tss` can be run from any shell but completions are provided for zsh only.
- (recommended) `jq`
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

## FAQ
### Relation to TagSpaces

tss intends to be compatible with TagSpaces, but it does not require TagSpaces to run and is not affiliated with it in any way.
