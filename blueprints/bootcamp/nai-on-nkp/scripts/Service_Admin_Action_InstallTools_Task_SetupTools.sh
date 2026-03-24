#!/usr/bin/env bash
set -euo pipefail
set -x
IFS=$'\n\t'

export APT_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew"

# Wait for any apt locks to be free
wait_for_apt() {
  echo "Waiting for apt + cloud-init..."

  # Wait for cloud-init (very important on fresh VMs)
  if command -v cloud-init >/dev/null 2>&1; then
    sudo cloud-init status --wait
  fi

  # Wait for apt systemd services to finish
  while systemctl is-active --quiet apt-daily.service \
     || systemctl is-active --quiet apt-daily-upgrade.service; do
    echo "Waiting for apt systemd services..."
    sleep 2
  done

  # Final safety: wait for locks
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
     || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 \
     || sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    echo "Waiting for apt locks..."
    sleep 2
  done
}

wait_for_apt

if [[ @@{ERAG}@@ != "true" ]]; then
    echo "eRAG marked False or unset, not installing eRAG dependencies"
else
	echo "Installing ERAG dependencies"
	sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS -y update
	sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS -y install ansible python3-venv
fi

## install jq
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS -y install jq

curl -sLS https://get.arkade.dev| sudo sh
sudo chown -R nutanix:nutanix /usr/local/bin/arkade

## install utils
arkade get \
kubectx \
kubens \
krew \
stern

## install yq
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chown -R nutanix:nutanix /usr/bin/yq
sudo chmod +x /usr/bin/yq

## install k9s
curl -sS https://webinstall.dev/k9s | bash

## install kubie for context switching
wget https://github.com/sbstp/kubie/releases/download/v0.26.0/kubie-linux-amd64
sudo mv kubie-linux-amd64 /usr/local/bin/kubie
chmod +x /usr/local/bin/kubie

## set path for arkade and krew kubectl plugin binaries
export PATH="$HOME/.arkade/bin/:$HOME/.krew/bin:$PATH"

echo "alias k=$(which kubectl)" >> $HOME/.bashrc
echo "alias kns=$(which kubens)" >> $HOME/.bashrc