$PERSONAL_DIR = ~/Progamming/personal

mkidr -p ~/packages/source
mkidr -p $PERSONAL_DIR

pacman -Syu
pacman -S git base-devel

git clone https://aur.archlinux.org/powershell-bin.git ~/packages/source/powershell-bin
cd ~/packages/source/powershell-bin

makepkg -si
chsh -s /usr/bin/pwsh

echo "Powershell installed. Cloning workflow to $PERSONAL_DIR"

cd $PERSONAL_DIR

git clone https://github.com/soulshined/workflow

cd workflow

/usr/bin/pwsh ./setup/PC.ps1
