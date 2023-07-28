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
  cat zshrc_common_tags.zsh >>$zshrc
else
  print -r "Common tag suggestions already present in ${(q-)zshrc}."
fi
