abbr --add ls 'lsd -l'
abbr --add cat bat
abbr --add lg lazygit

alias wg-up="sudo wg-quick up wg0"
alias wg-down="sudo wg-quick down wg0"

function reload
    exec fish
end

set fish_greeting

source ~/.config/fish/functions/dotctl.fish
source ~/.config/fish/functions/prompt.fish
source ~/.config/fish/functions/manpages.fish
source ~/.config/fish/functions/utility.fish

mcfly init fish | source
zoxide init fish | source

set -gx MCFLY_KEY_SCHEME vim
set -gx PATH "$HOME/.cargo/bin" $PATH

fish_add_path --path ~/.pub-cache/bin
fish_add_path --path ~/go/bin

if test "$TERM" = xterm-kitty
    set -x TERM xterm-256color
end
