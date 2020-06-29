# SETS UP DEV ENVIRONMENT[S]
[CmdletBinding()]
param (
    [Parameter(HelpMessage = "Identifies if the setup is just an update or not. If not, a full install is done for dependencies and such and override existing")]
    [switch] $Update
)

# SCRIPT SETUP
New-Variable -Name usrbin -Value "~" -Visibility Private
New-Variable -Name PWSHModuleParentDir -Value "C:\Program Files\WindowsPowerShell" -Visibility Private

if ($IsMacOS) { 
    $usrbin = "/usr/local/bin"
    $PWSHModuleParentDir = "$usrbin/.local/share/powershell"
}
#END OF SCRIPT SETUP

# FUNCTIONS
Function Update-ItemsToExec($Items) {
    New-Variable -Name item -Visibility Private
    New-Variable -Name target -Visibility Private

    $Items | ForEach-Object -Process {
        $item = Get-ChildItem $_ -ErrorAction SilentlyContinue
    
        if (![String]::IsNullOrWhiteSpace($item.Extension)) { return }
        
        if ($IsMacOS) {
            #make executable
            $target = Get-Item -Path $item.FullName
            Write-Debug "New location target: $($target.FullName)"
            chmod 755 $target.FullName
        }
        
    }

    Remove-Variable item
    Remove-Variable target
}

#Step 1. Move git templates to user home and make the hooks executable
Copy-Item ./git/.git-templates $usrbin -Force -Recurse -Container 
New-Variable -Name gitExecs -Value $(Get-ChildItem -Path "$usrbin/.git-templates" -Recurse -File) -Visibility Private -Option Constant
Update-ItemsToExec -Items $gitExecs

#Step 2. Download terminal specific dependencies
if ($IsMacOS -and !$Update) {
    #make zsh default
    chsh -s $(which zsh)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/master/tools/install.sh)"
    sh -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    sh -c "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k"
}

#Step 3. Move dotfiles to user home
New-Variable -Name dotFileNames -Value @('./git/.gitconfig', './git/.gitignore_global');
if ($IsMacOS) { $dotFileNames += @('./.bash_profile', './.zshrc') }

New-Variable -Name dotFiles -Value $(Get-ChildItem -Path $dotFileNames -File -Hidden) -Visibility Private -Option Constant
$dotFiles | ForEach-Object -Process { Copy-Item $_ $usrbin -Force }

    #3.1 Powershell (PS Modules are OS agnostic)
    Copy-Item ./powershell/Modules $PWSHModuleParentDir -Force -Recurse -Container
    Copy-Item ./Microsoft.PowerShell_profile.ps1 $PROFILE -Force

#Step 4. Move all execs to /usr/local/bin and make them executable if needed
New-Variable -Name binItems -Value $(Get-ChildItem -Path ./bin, './git/custom commands' -Recurse -File) -Visibility Private -Option Constant
Update-ItemsToExec -Items $binItems
$binItems | ForEach-Object { 
    if ($IsMacOS) {
        Copy-Item -Path $_.FullName -Destination $usrbin -Force 
    }
    elseif ($_.BaseName.StartsWith("git-")) {
        Copy-Item -Path $_.FullName -Destination "$usrbin/.git-commands/$($_.BaseName).sh" -Force 

        $ResolvedPath = Resolve-Path "$usrbin/.git-commands/$($_.BaseName).sh"
        git.exe config --global alias."$($_.BaseName.substring(4))" ('!f() { bash \"' + $ResolvedPath + '\" $@; };f')
    }
}