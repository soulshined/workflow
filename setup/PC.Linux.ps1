$ErrorActionPreference = 'Stop'

sudo --shell

rm -rf ~/.profile
ln --symbolic $Env:WORKFLOW_DIR/Linux.profile ~/.profile
source ~/.profile

rm -rf $PROFILE
ln -s $Env:WORKFLOW_DIR/powershell/Microsoft.PowerShell_profile.ps1 $PROFILE
source $PROFILE

#PACMAN
Prompt-ManualConfirmNotice -Title 'pacman.conf' -message 'add HookDir = /etc/pacman.d/hooks'
vim /etc/pacman.conf

cat /etc/pacman.conf
rm -rf /etc/pacman.d/hooks
ln -s $Env:WORKFLOW_DIR/dependencies/pacman/hooks /etc/pacman.d/hooks

pacman -Syu
pacman -S --needed - < $Env:WORKFLOW_DIR/dependencies/pacman/packages.txt

#PACKAGES
rm -rf ~/.config/nvim
ln -s $Env:WORKFLOW_DIR/ides/nvim ~/.config/nvim
rustup default stable

'ghostty', 'hypr', 'waybar' | % {
	rm -rf ~/.config/$_
	ln -s $Env:WORKFLOW_DIR/$_ ~/.config/$_
}

#PACKAGES SOURCE
curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

mkdir -p ~/Downloads
cd ~/Downloads
curl -o dotnet-install.sh https://dot.net/v1/dotnet-install.sh
./dotnet-install.sh -channel STS -version latest --install-dir $HOME/.dotnet
ln -s $HOME/.dotnet/dotnet /usr/bin

curl -o grimblast https://raw.githubusercontent.com/hyprwm/contrib/refs/heads/main/grimblast/grimblast
chmod +x grimblast
Move-Item grimblast /usr/local/bin
