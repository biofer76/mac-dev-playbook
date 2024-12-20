#!/bin/bash
#
#  Use it with this in MacOS Terminal (not iTerm2 if already installed, as iTerm will be quit ;-) ) 
#    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/biofer76/mac-dev-playbook/master/init.sh)"
#
# set -e

SOURCE_DIR=~/Workspace/github/biofer76/mac-dev-playbook

_step_counter=0
function step() {
        _step_counter=$(( _step_counter + 1 ))
        printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}

function installcli() {
  # https://gist.github.com/ChristopherA/a598762c3967a1f77e9ecb96b902b5db
  echo "Update MacOS & Install Command Line Interface. If this fails, do it manually."
  sudo /usr/sbin/softwareupdate -l
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  sudo /usr/sbin/softwareupdate -ia
  rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  echo "Sleep 20"
  sleep 20
  xcode-select --install
}

step "Check prerequisites"
echo "Are you logged into Mac Appstore?"
read -p "Press enter to continue"
echo ""
echo "Enter the hostname: "  
read newhostname  
echo ""
echo "Sudo magic, please enter sudo-password if asked"
# Sudo Magic :)
sudo -v

# Keep-alive: update existing `sudo` time stamp until we have finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

[ ! -d "/Library/Developer/CommandLineTools" ] && installcli

step "Preparing system"
echo "- Creating Workspace folder"
mkdir -p $SOURCE_DIR

echo " - Cloning Repo"
git clone https://github.com/biofer76/mac-dev-playbook.git $SOURCE_DIR || exit 1

echo " - Upgrading PIP"
/Library/Developer/CommandLineTools/usr/bin/pip3.9 install --upgrade pip || exit 1

echo " - Installing Ansible and required Python packages"
/Library/Developer/CommandLineTools/usr/bin/pip3.9 install --user --requirement $SOURCE_DIR/requirements.txt || exit 1
PATH="/usr/local/bin:$(/Library/Developer/CommandLineTools/usr/bin/python3 -m site --user-base)/bin:$PATH"
export PATH

echo " - Installing Ansible requirements"
ansible-galaxy install -r $SOURCE_DIR/requirements.yml || exit 1

if [ -n "${newhostname}" ]; then
  sudo scutil --set HostName ${newhostname}
  sudo scutil --set LocalHostName ${newhostname}
  sudo scutil --set ComputerName ${newhostname}
  sudo dscacheutil -flushcache
else
  newhostname="$(hostname)"
fi

step "Switch to source folder"
cd $SOURCE_DIR

echo 'Running full installation'
echo '  ansible-playbook main.yml --ask-become-pass'
echo 'Running a specific set of tagged tasks'
echo '  ansible-playbook main.yml -K --tags "dotfiles,homebrew"'
