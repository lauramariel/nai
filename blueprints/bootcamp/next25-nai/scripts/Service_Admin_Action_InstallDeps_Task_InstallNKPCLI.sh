#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

cat <<EOF >~/.env
export NKP_BINARY_URL='@@{NKP_BINARY_URL}@@'
EOF

source ~/.env

# Download and install DKP binary
# curl "https://downloads.d2iq.com/dkp/${DKP_VERSION}/dkp_${DKP_VERSION}_linux_amd64.tar.gz" -o dkp.tar.gz


# Download and install NKP binary
curl -fsSL "${NKP_BINARY_URL}" | sudo tar xz -C /usr/local/bin -- nkp

nkp version