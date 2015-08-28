function git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_PREFIX$(current_branch)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

function hg_prompt_info {
    hg prompt --angle-brackets "\
<%{$fg_bold[blue]%}hg:(%{$fg_bold[red]%}<branch>><:<tags|, >%{$fg_bold[blue]%})>\
%{$fg[yellow]%}<status|modified|unknown><update>\
<patches: <patches|join( → )>>%{$reset_color%}" 2>/dev/null
}


function get_pwd() {
  print -D $PWD
}

function battery_charge() {
  if [ -e ~/.bin/batcharge.py ]
  then
    echo `python ~/.bin/batcharge.py`
  else
    echo ''
  fi
}

function put_spacing() {
  #local bat=$(battery_charge)
  #if [ ${#bat} != 0 ]; then
  #  ((bat = ${#bat} - 18))
  #else
  #  bat=0
  #fi

  local git=$(git_prompt_info)
  if [ ${#git} != 0 ]; then
    ((git=${#git} - 16))
  else
    git=0
  fi

  #local mercurial=$(hg_prompt_info)
  #if [ ${#mercurial} != 0 ]; then
  #  ((mercurial=${#mercurial} - 60))
  #else
  #  mercurial=0
  #fi

  local termwidth
  (( termwidth = ${COLUMNS} - 27 - i${#HOST} - ${#$(get_pwd)} - ${git}))
  #(( termwidth = ${COLUMNS} - 10 - i${#HOST} - ${#$(get_pwd)} - ${git}))

  local spacing=""
  for i in {1..$termwidth}; do
    spacing="${spacing} "
  done
  echo $spacing
}

function precmd() {
print -rP '
$fg[cyan]%m: $fg[yellow]$(get_pwd)$(git-radar --zsh --fetch)'
#$fg[cyan]%m: $fg[yellow]$(get_pwd)$(put_spacing)$(git)'
}

PROMPT='%{$reset_color%}→ '

ZSH_THEME_GIT_PROMPT_PREFIX="[git:"
ZSH_THEME_GIT_PROMPT_SUFFIX="]$reset_color"
ZSH_THEME_GIT_PROMPT_DIRTY="$fg[red]+"
ZSH_THEME_GIT_PROMPT_CLEAN="$fg[green]"
