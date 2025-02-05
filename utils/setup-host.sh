# Courtesy of https://github.com/jesse-gonzalez 

## install arkade to simplify installing cloud-native tools
curl -sLS https://get.arkade.dev| sudo sh

## install utils
arkade get \
kubectx \
kubens \
krew \
stern

## set path for arkade and krew kubectl plugin binaries
export PATH="$HOME/.arkade/bin/:$HOME/.krew/bin:$PATH"

echo "alias k=$(which kubectl)" >> $HOME/.bashrc
echo "alias kns=$(which kubens)" >> $HOME/.bashrc
