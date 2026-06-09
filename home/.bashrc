#!/usr/bin/env bash

[[ $- == *i* ]] || return

for file in environment options commands wireguard tools prompt; do
    source "$HOME/.bashrc.d/$file"
done
