#
# Display currently active git branch at the top-right corner of your terminal at all times.
#
# include in your ~/.bashrc
#

# prompt setting callback function
# see: http://unix.stackexchange.com/questions/124407/what-color-codes-can-i-use-in-my-ps1-prompt
set_prompt() {
  local last_command=$? # Must come first!
  # prompt colors
  local txtrst='\[\e[0m\]'    # Text Reset
  local txtblu='\[\e[0;34m\]' # Blue
  local txtgrn='\[\e[0;32m\]' # Green
  local txtred='\[\e[0;31m\]' # Red
  local txtpur='\[\e[0;35m\]' # Purple
  local savcur='\[\033[s\]' # save cursor position
  local rstcur='\[\033[u\]' # restore saved cursor position
  local fancy_x='\342\234\227' # unicode for fancy x mark

  # default action to set some env vars
  # required at least on Fedora
  __vte_prompt_command

  # build a label for top-right corner
  local label=""
  local gitbra=`git rev-parse --abbrev-ref HEAD 2> /dev/null`
  if [[ $gitbra != "" ]]; then
    # we reserve 38 characters for the label and two for brackets
    padlen=`echo $gitbra | awk -v cols=$COLUMNS '{ print (40-length($1)-2) }'`
    # output some padding at the beginning to erase possible previous longer label
    pad=""
    for ((i=0; i < $padlen; i++)); do
      pad+=' '
    done
    # There is some weird escaping here, because we are inside special cursor position (top-right corner).
    # The whole label is wrapped in literal brackets, which are not escaped.
    # Every character that is displayed in the top-right corner, has to be inside escaped brackets.
    # Otherwise the characters would be included in the prompt-length counter, and that would screw up 
    # the cursor start position for new lines in terminal.
    label="\[$pad[\]$txtgrn\[$gitbra\]$txtrst\[]\]"
  else
    padlen=40
    pad=""
    for ((i=0; i < $padlen; i++)); do
      pad+=' '
    done
    label="\[$pad\]"
  fi
  PS1=""
  # add a marker if last command failed
  if [[ $last_command != 0 ]]; then
      PS1+="$txtred$fancy_x$txtrst"
  fi
  PS1+="["
  # include (green) username
  if [[ $EUID == 0 ]]; then
      PS1+="${txtred}root"
  else
      PS1+="$txtgrn\\u"
  fi
  # shorten home dir
  shortpwd=`pwd | sed -e "s,^$HOME,~," -e "s,^/store$HOME,~,"`
  # append (blue) hostname and purple working directory
  PS1+="${txtrst}@$txtblu\\h$txtpur \\W$txtrst]"
  # set terminal window title with "user@host cwd"
  PS1+="\[\033]0;\\u@\\h $shortpwd\007\]"
  # print git branch label to first line, starting from column (terminalWidth-40)
  label_start=`expr $COLUMNS - 40 + 1`
  PS1+="$savcur\[\033[1;${label_start}f\]$label$rstcur\\$ "
}


# use crazy prompt only for capable terminals
if [[ "$TERM" =~ 256color ]]; then
   PROMPT_COMMAND='set_prompt'
else
    # fall back to simple black and white for simple terminals
    PS1="[\u@\h \W]\$ "
fi
