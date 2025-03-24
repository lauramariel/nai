# Courtesy of https://github.com/jesse-gonzalez

## install arkade to simplify installing cloud-native tools
curl -sLS https://get.arkade.dev| sudo sh

## install utils
arkade get \
kubectx \
kubens \
krew \
stern

## install yq
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq

## install k9s
curl -sS https://webinstall.dev/k9s | bash

## set path for arkade and krew kubectl plugin binaries
export PATH="$HOME/.arkade/bin/:$HOME/.krew/bin:$PATH"

echo "alias k=$(which kubectl)" >> $HOME/.bashrc
echo "alias kns=$(which kubens)" >> $HOME/.bashrc
source $HOME/.bashrc
