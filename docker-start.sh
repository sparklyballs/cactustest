#!/usr/bin/env bash

# shellcheck disable=SC2154
cactus start "${service}"

trap "echo Shutting down ...; cactus stop all -d; exit 0" SIGINT SIGTERM

# shellcheck disable=SC2154
if [[ ${log_to_file} == 'true' ]]; then
  # Ensures the log file actually exists, so we can tail successfully
  touch "$CACTUS_ROOT/log/debug.log"
  tail -F "$CACTUS_ROOT/log/debug.log" &
fi

while true; do sleep 1; done
