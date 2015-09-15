#
# Provides Git aliases and functions.
#
# Authors:
#   Feña Agar <fernando.agar@gmail.com>
#

# Return if requirements are not found.
if (( ! $+commands[git] )); then
  return 1
fi

# Source module files.
source "${0:h}/alias.zsh"
