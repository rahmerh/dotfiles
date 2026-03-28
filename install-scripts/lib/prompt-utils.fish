function read_confirm
  while true
    read -p 'echo "$argv[1] (y/n):"' -l confirm

    switch $confirm
      case Y y
        return 0
      case '' N n
        return 1
    end
  end
end
