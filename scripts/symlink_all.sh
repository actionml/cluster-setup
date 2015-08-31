#!/bin/bash

LOCAL_DIR=$(cd .. && pwd)

# Clear
rm $HOME/.zshrc
rm $ZSH/custom/*

#Link
ln -s $LOCAL_DIR/dotfiles/zsh/zshrc $HOME/.zshrc
ln -s $LOCAL_DIR/dotfiles/zsh/plugins/* $HOME/.oh-my-zsh/custom/plugins/
ln -s $LOCAL_DIR/dotfiles/zsh/themes $HOME/.oh-my-zsh/custom/themes
