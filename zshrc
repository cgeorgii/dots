#!/usr/bin/env zsh

# Exports {{{
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ZSH=~/.oh-my-zsh
export EDITOR='nvim'
export VISUAL='nvim'
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="/usr/local/heroku/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export SSH_KEY_PATH="~/.ssh/"
export FZF_DEFAULT_COMMAND='ag -g ""'
export NNN_BMS='d:~/Downloads;~:~;c:~/code'
export NNN_USE_EDITOR=1
# }}}

# Plugins
# plugins=(git ssh-agent vi-mode tmuxinator zsh-autosuggestions)
plugins=(git ssh-agent vi-mode tmuxinator zsh-autosuggestions)

# Ruby
eval "$(rbenv init -)"

# User configuration {{{
ZSH_THEME="robbyrussell"
source $ZSH/oh-my-zsh.sh
bindkey "^P" up-line-or-beginning-search # Make ctrl-p work like up arrow
bindkey "^N" down-line-or-beginning-search # Make ctrl-n work like down arrow
bindkey -s "^_" 'nnn^M'
DISABLE_UNTRACKED_FILES_DIRTY="true"
# }}}

# Aliases {{{
alias bc="bin/console"
alias be="bundle exec"
alias br="bundle exec rspec -t '~integration' -t '~pdf'"
alias bu="br spec/unit"
alias dc="docker-compose"
alias dots="~/dots"
alias git=hub
alias gitconfig="vim ~/.gitconfig"
alias ls=exa
alias mux="tmuxinator"
alias scheme="rlwrap -c -r -f ~/mit_scheme_bindings.txt scheme"
alias se="stack exec"
alias t=bin/test
alias there='tmux new-session -As $(basename "$PWD" | tr . -)'
alias tmuxconfig="vim ~/.tmux.conf"
alias vi="vim"
alias vim="nvim"
alias vimconfig="vim ~/.vimrc"
alias zshconfig="vim ~/.zshrc"
disable r
# }}}

source `brew --prefix`/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        eval "$("$BASE16_SHELL/profile_helper.sh")"

# autojump
[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
