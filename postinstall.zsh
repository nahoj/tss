#!/usr/bin/env zsh

set -euo pipefail

local functions_dir
functions_dir=$1

if ! ((fpath[(Ie)$functions_dir])); then
	cat <<EOF
###
###  $functions_dir doesn't seem to be in your
###  fpath, at least in non-interactive mode. You need to add it, which you can
###  do by running:
###
###      echo 'fpath+=("$functions_dir")' >>"${ZDOTDIR:-$HOME}/.zshenv"
###
EOF
fi

#local zshrc
#zshrc=${ZDOTDIR:-$HOME}/.zshrc
#if ! grep -q 'autoload -U tsp' "$zshrc"; then
#  echo "Adding 'autoload -U tsp' to $zshrc."
#  echo 'autoload -U tsp' >>"$zshrc"
#fi
