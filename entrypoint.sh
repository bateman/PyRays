#!/bin/bash
# this script is used to boot the Docker container

echo "Running ... (Press CTRL-c to terminate)" && exec python -m pyrays "$@"
