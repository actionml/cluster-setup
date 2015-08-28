#!/bin/bash

LOCAL_DIR=$(pwd)

ln -s $LOCAL_DIR/dotfiles/zshrc ~/.zshrc
ln -s $LOCAL_DIR/dotfiles/vimrc ~/.vimrc
ln -s $LOCAL_DIR/zsh/* $ZSH/custom/
