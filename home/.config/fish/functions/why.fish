function why
    set -l code $status

    if test $code -eq 0
        echo "Why what? Nothing went wrong."
        return 0
    end

    echo -n (set_color red)"$code"(set_color normal)

    switch $code
        case 1
            echo " – general error (e.g. test failed)"
        case 2
            echo " – misuse of shell builtins"
        case 126
            echo " – permission denied or not executable"
        case 127
            echo " – command not found"
        case 128
            echo " – invalid exit value or repo error"
        case 130
            echo " – terminated by Ctrl-C (SIGINT)"
        case 139
            echo " – segmentation fault"
        case '*'
            if test $code -ge 129 -a $code -le 255
                set -l signal (math $code - 128)
                switch $signal
                    case 9
                        echo " – killed (SIGKILL)"
                    case 15
                        echo " – terminated (SIGTERM)"
                    case '*'
                        echo " – exited via signal $signal"
                end
            else
                echo " – unknown or uncommon error"
            end
    end

    set -l last_cmd (history --max=1 | string trim | string replace -ra '^"|"$' '')
    set -l max_len 50
    if test (string length -- $last_cmd) -gt $max_len
        set shown_cmd (string sub -l $max_len $last_cmd)'... [truncated]'
    else
        set shown_cmd $last_cmd
    end

    echo "↳ \"$shown_cmd\""
end
