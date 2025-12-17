function smart-tar
    if test (count $argv) -lt 1
        echo "Usage:"
        echo "  smart-tar <archive-name> <files...>      # create archive"
        echo "  smart-tar <archive> [--to <dir>]         # extract archive"
        return 1
    end

    set -l dereference false
    set -l target_dir .
    set -l args

    for i in (seq (count $argv))
        set arg $argv[$i]
        switch $arg
            case --dereference
                set dereference true
            case --to
                set i (math $i + 1)
                set target_dir $argv[$i]
            case '*'
                set -a args $arg
        end
    end

    # Detect extract mode
    set -l first $args[1]
    if test (count $args) -eq 1 -a -f $first
        switch $first
            case "*.tar" "*.tar.gz" "*.tgz" "*.tar.xz" "*.tar.bz2"
                set archive $first

                switch $archive
                    case "*.tar.gz" "*.tgz"
                        set tar_flags -xzvf
                    case "*.tar.bz2"
                        set tar_flags -xjvf
                    case "*.tar.xz"
                        set tar_flags -xJvf
                    case "*.tar"
                        set tar_flags -xvf
                    case '*'
                        echo "Unsupported archive format: $archive"
                        return 1
                end

                tar $tar_flags $archive -C $target_dir
                return $status
        end
    end

    # --- Compression path ---
    if test (count $args) -lt 2
        echo "Missing archive name or file arguments"
        return 1
    end

    set archive $args[1]
    set -e args[1]

    set -l ext
    for known in gz bz2 xz
        if string match -q "*.$known" "$archive"
            set ext $known
            break
        end
    end

    if test -z "$ext"
        set -l size (du -cs --apparent-size --block-size=1M $args | grep total | awk '{print $1}')
        if test -z "$size"
            echo "Failed to determine archive size"
            return 1
        end

        if test $size -lt 50
            set ext gz
        else if test $size -lt 200
            set ext bz2
        else
            set ext xz
        end

        set archive "$archive.tar.$ext"
    end

    switch $ext
        case gz
            set tar_flags -czvf
        case bz2
            set tar_flags -cjvf
        case xz
            set tar_flags -cJvf
        case '*'
            echo "Unknown extension: .$ext"
            return 1
    end

    if $dereference
        tar $tar_flags $archive --dereference $args
    else
        tar $tar_flags $archive $args
    end
end
