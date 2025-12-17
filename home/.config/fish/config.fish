abbr --add ls 'lsd -l'
abbr --add cat bat
abbr --add lg lazygit
if type -q gitlab-ci-local
    abbr --add gcl gitlab-ci-local
end

alias wg-up="sudo wg-quick up wg0"
alias wg-down="sudo wg-quick down wg0"

function reload
    exec fish
end

set fish_greeting

mcfly init fish | source
zoxide init fish | source

set -gx MCFLY_KEY_SCHEME vim
set -gx PATH "$HOME/.cargo/bin" $PATH

fish_add_path --path ~/.pub-cache/bin
fish_add_path --path ~/go/bin
fish_add_path --path ~/.local/bin
fish_add_path --path ~/.fvm_flutter/bin

if test "$TERM" = xterm-kitty
    set -x TERM xterm-256color
end

if status is-interactive
    if type -q keychain
        keychain --eval --quiet | source
    end
end
