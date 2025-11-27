#!/bin/bash

file="/tmp/notification-history/notifications.log"

if [ -f "$file" ]; then
  wc -l "$file" | awk '{print $1}'
else
  echo 0
fi

