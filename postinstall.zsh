#!/usr/bin/env zsh

set -euo pipefail

local functions_dir=$1

if ! ((fpath[(Ie)$functions_dir])); then
	cat <<EOF
###
###  ${(qqq)functions_dir} doesn't seem to be in your
###  fpath, at least in non-interactive mode. You need to add it, which you can
###  do by running:
###
###      print -r ${(qq):-fpath+=(${(qqq)functions_dir})} >>${(q-)ZDOTDIR:-$HOME}/.zshenv
###
EOF
fi

local zshrc=${ZDOTDIR:-$HOME}/.zshrc

if ! grep -q 'autoload -U tss' $zshrc; then
  print -r "Adding 'autoload -U tss' to ${(q-)zshrc}."
  print '\nautoload -U tss' >>$zshrc
else
  print -r "'autoload -U tss' already present in ${(q-)zshrc}."
fi

if ! grep -q 'tss_tags_' $zshrc; then
  print -r "Adding common tag suggestions to ${(q-)zshrc}. You may want to edit them."
  {
    print -r '# Array variables named tss_tags_* are added to tag suggestions for tss add'
    print -r 'local tss_tags_ratings=(1star 2star 3star 4star 5star)'
    print -r 'local tss_tags_media=(toread reading read towatch watched)'
    print -r 'local tss_tags_workflow=(todo draft done published)'
    print -r 'local tss_tags_life=(family friends personal school vacation work other)'
  } >>$zshrc
else
  print -r "Common tag suggestions already present in ${(q-)zshrc}."
fi
