#!/bin/bash

db="/tmp/notification-history/notifications.sqlite3"

if [ -f "$db" ]; then
  sqlite3 "$db" "SELECT COUNT(*) FROM notifications;"
else
  echo 0
fi

