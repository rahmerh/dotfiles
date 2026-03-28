alias ls='lsd -la'
alias cat='bat'

. "$HOME/.cargo/env"

path_add() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

parse_git_branch() {
    git symbolic-ref --short HEAD 2>/dev/null
}

get_git_dirty() {
    git status --porcelain 2>/dev/null
}

get_git_unpushed() {
    git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 || return
    git rev-list --count '@{u}'..HEAD 2>/dev/null
}

set_bash_prompt() {
    local last_status=$?
    if [[ $PWD == "$HOME"* ]]; then
        path=" ~${PWD#$HOME}"
    else
        path=" $PWD"
    fi
    local branch
    branch="$(parse_git_branch)"

    local reset='\[\e[0m\]'
    local red='\[\e[31m\]'
    local pink='\[\e[38;2;232;90;152m\]'
    local bold_pink='\[\e[1;38;2;232;90;152m\]'
    local yellow='\[\e[38;2;235;203;139m\]'
    local purple='\[\e[38;2;180;142;173m\]'

    local prompt="${path}"

    if [[ -n "$branch" ]]; then
        local dirty_output
        local unpushed=0

        dirty_output="$(get_git_dirty)"
        if unpushed="$(get_git_unpushed)"; then
            :
        else
            unpushed=0
        fi

        if [[ -n "$dirty_output" ]]; then
            prompt+=" ${yellow}${branch}${reset}"
        elif [[ "$unpushed" -gt 0 ]]; then
            prompt+=" ${purple}${branch}${reset}"
        else
            prompt+=" ${branch}"
        fi
    fi

    if [[ $last_status -ne 0 ]]; then
        prompt+=" ${red}❱${reset} "
    else
        prompt+=" ${bold_pink}❱${reset} "
    fi

    PS1="$prompt"
}

PROMPT_COMMAND=set_bash_prompt

eval "$(zoxide init bash)"
