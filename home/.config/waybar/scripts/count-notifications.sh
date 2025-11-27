#!/bin/bash

file="$HOME/.local/share/notify-history/notifications.log"

if [ -f "$file" ]; then
  wc -l "$file" | awk '{print $1}'
else
  echo 0
fi

