#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [ ! -f ~/.ssh/id_rsa ]; then
    echo '@@{CRED_SSH.secret}@@' > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa

    echo '@@{CRED_SSH.public_key}@@' > ~/.ssh/id_rsa.pub
fi
