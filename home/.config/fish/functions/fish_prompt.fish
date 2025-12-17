function fish_prompt
    set -l last_status $status
    set -l path (string replace $HOME '~' (pwd))
    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null)

    echo -n "$path"

    if test -n "$branch"
        set -l dirty_output (command git status --porcelain 2>/dev/null)
        set -l unpushed (command git rev-list --count @{u}..HEAD 2>/dev/null)

        if test -n "$dirty_output"
            set_color '#EBCB8B'
        else if test "$unpushed" -gt 0
            set_color '#B48EAD'
        else
            set_color normal
        end

        echo -n " $branch"
        set_color normal
    end

    if test $last_status -ne 0
        set_color red
    else
        set_color --bold '#E85A98'
    end

    echo -n ' ❱ '
    set_color normal
end
