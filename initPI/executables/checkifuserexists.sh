#!/bin/bash

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <name>"
  exit 1
fi

if ! grep -q "^$1:" /etc/passwd; then
  echo "You need firstly to create user $1 before executing any commands on its' behalf"
  exit 1
fi

exit 0
