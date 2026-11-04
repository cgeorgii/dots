# vim-surround: ys{motion}{char}, yss{char}, cs{old}{new}, css{old}{new},
# ds{char}, visual S{char}

autoload -Uz surround select-quoted select-bracketed add-zle-hook-widget
zle -N stock-change-surround surround
zle -N delete-surround surround
zle -N select-quoted
zle -N select-bracketed

# Stock add-surround wraps the trailing space of `aw` and misplaces the text
# when the selection starts in the second column.
function add-surround {
  setopt localoptions extendedglob
  local -A left=( '(' '( ' '[' '[ ' '{' '{ ' '<' '< ' ')' '(' ']' '[' '}' '{' '>' '<' )
  local -A right=( '(' ' )' '[' ' ]' '{' ' }' '<' ' >' ')' ')' ']' ']' '}' '}' '>' '>' )
  local saved_cut=$CUTBUFFER start char text

  zle -f vichange
  zle .vi-change || return
  start=$CURSOR text=$CUTBUFFER
  CUTBUFFER=$saved_cut

  # Keep the text on screen while waiting for the surround character
  RBUFFER=$text$RBUFFER
  zle .vi-cmd-mode
  CURSOR=$start
  zle -R
  read -k 1 char
  [[ $char == $'\e' ]] && return

  local body=${text%%[[:space:]]##}
  local trailing=${text:$#body}
  RBUFFER=${left[$char]:-$char}$body${right[$char]:-$char}$trailing${RBUFFER:$#text}
}
zle -N add-surround

# Accepts css'" as well as cs'"
function change-surround {
  local char
  read -k 1 char
  [[ $char == s ]] && read -k 1 char
  zle -U -- $char
  zle stock-change-surround
}
zle -N change-surround

# The motion behind yss: the whole line the cursor is on
function select-current-line {
  local before=${LBUFFER##*$'\n'} after=${RBUFFER%%$'\n'*}
  MARK=$(( CURSOR - $#before ))
  CURSOR=$(( CURSOR + $#after ))
  REGION_ACTIVE=1
}
zle -N select-current-line

bindkey -a ys add-surround
bindkey -a cs change-surround
bindkey -a ds delete-surround
bindkey -M visual S add-surround
bindkey -M viopp s select-current-line

# Quote and bracket text objects, which zsh leaves unbound
() {
  local keymap key
  for keymap in visual viopp; do
    for key in {a,i}{\',\",\`}; do
      bindkey -M $keymap $key select-quoted
    done
    for key in {a,i}${(s::)^:-'()[]{}<>bB'}; do
      bindkey -M $keymap $key select-bracketed
    done
  done
}

# zsh-syntax-highlighting and zsh-autosuggestions wrap y, c and d in user
# widgets, and with those bound ys, cs and ds never fire. Bind the builtins.
bindkey -a y .vi-yank
bindkey -a c .vi-change
bindkey -a d .vi-delete

# Nothing repaints for the builtins above or the widgets defined here, which
# load after the highlighter and so aren't wrapped by it.
function surround-rehighlight { _zsh_highlight }
add-zle-hook-widget line-pre-redraw surround-rehighlight
