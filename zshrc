#!/usr/bin/env zsh

# Exports {{{
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ZSH=~/.oh-my-zsh
export EDITOR='nvim'
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="/usr/local/heroku/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export SSH_KEY_PATH="~/.ssh/"
export FZF_DEFAULT_COMMAND='ag -g ""'
# }}}

# Plugins
plugins=(git ssh-agent vi-mode tmuxinator zsh-autosuggestions)

# Ruby
eval "$(rbenv init -)"

# User configuration {{{
ZSH_THEME="robbyrussell"
source $ZSH/oh-my-zsh.sh
bindkey "^P" up-line-or-beginning-search # Make ctrl-p work like up arrow
bindkey "^N" down-line-or-beginning-search # Make ctrl-n work like down arrow
DISABLE_UNTRACKED_FILES_DIRTY="true"
# }}}

# Aliases {{{
alias vim="nvim"
alias vi="vim"
alias be="bundle exec"
alias br="bundle exec rspec -t '~integration' -t '~pdf'"
alias bu="br spec/unit"
alias bc="bin/console"
alias mux="tmuxinator"
alias zshconfig="vim ~/.zshrc"
alias vimconfig="vim ~/.vimrc"
alias tmuxconfig="vim ~/.tmux.conf"
alias dots="~/dots"
alias there='tmux new-session -As $(basename "$PWD" | tr . -)'
alias git=hub
alias scheme="rlwrap -c -r -f ~/mit_scheme_bindings.txt scheme"
disable r
# }}}

source `brew --prefix`/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        eval "$("$BASE16_SHELL/profile_helper.sh")"
