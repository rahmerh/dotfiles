#!/usr/bin/env fish

function mt_is_valid
    test -f machine-type; or return 1

    set v (string trim (cat machine-type))

    test "$v" = Work -o "$v" = Personal
end

function mt_is_personal
    set v (string trim (cat machine-type))

    if test "$v" = Personal
        return 0
    else
        return 1
    end
end

function mt_is_work
    set v (string trim (cat machine-type))

    if test "$v" = Work
        return 0
    else
        return 1
    end
end
