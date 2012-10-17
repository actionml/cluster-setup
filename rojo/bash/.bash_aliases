# BASH CMDS
alias bashconfig="vim ~/.bashrc"
alias bashaliases="vim ~/.bash_aliases"
alias bashsource="source ~/.bashrc"
alias bashprofile="vim ~/.profile"
alias profilesource="source ~/.profile"

# USER ALIASES
alias l="ls -l"
alias ll="ls -lash"
alias la="ls -la"
alias c="clear"
alias confs="cd ~/confs"

# USER CMDS
alias dev-cumplo="cd ~/Dev/Cumplo/cumplo"

# Cumplo
alias front="clear;ssh -p 2121 rojo@front"
alias back="clear; ssh -p 2222 fagar@localhost"
alias staging="clear; ssh -p 2223 rojo@localhost"

# GIT
alias git="sudo git"
alias gs="git status"
alias gcam="git commit -am"
alias gch="git checkout"
alias gchp="git checkout production;git pull origin production"
alias gchs="git checkout staging;git pull origin staging"
alias glog="git log --oneline"

# RAILS
alias rake="rvmsudo rake"
