A command-line tool to manage files with `[tags]` in their name such as `IMG-2653[vacation alps].jpg`, with completion provided for zsh. Compatible with [TagSpaces](https://www.tagspaces.org/).

**Status:** I consider it completed. I intend to fix bugs if I find any.

**Feedback welcome.** Anyone is welcome to send me an email or open an issue for any reason or just to say hi.

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

Common tag suggestions added to `.zshrc`, that you can edit to your liking:
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

## Why?

Most tagging systems are either system-specific (the one provided by your OS) or specific to certain file types (audio/video and image tags).

In contrast, putting `[tags]` in filenames works for any file, on any system, and instantly integrates with tools you already have: your file manager and desktop search, basic commands, `fzf`, `vidir`, etc. `tss` (or TagSpaces for a graphical tool) only comes as a bonus for more efficient and powerful actions and queries, and you can uninstall it without any loss of data.

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
