#Requires -Version 7

# SETS UP DEV ENVIRONMENT[S]

# SCRIPT SETUP
Function Get-CustomConfig($Value) { if ($IsMacOs) { $Value.mac } else { $Value.win } }

New-Variable -Name usrDirs -Value @{
    bin                 = @{ win = "~"; mac = "/usr/local/bin"; };
    pwshModuleParentDir = @{ win = "C:/Program Files/WindowsPowershell"; mac = "/usr/local/bin/.local/share/powershell"; };
} -Visibility Private
#END OF SCRIPT SETUP

# FUNCTIONS
Function Update-ItemsToExec($Items) {
    if (!$IsMacOs) { return }

    New-Variable -Name item -Visibility Private
    New-Variable -Name target -Visibility Private

    $Items | ForEach-Object -Process {
        $item = Get-ChildItem $_ -ErrorAction SilentlyContinue
    
        if (![String]::IsNullOrWhiteSpace($item.Extension)) { return }
        
        #make executable
        $target = Get-Item -Path $item.FullName
        Write-Debug "New location target: $($target.FullName)"
        chmod 755 $target.FullName
    }

    Remove-Variable item
    Remove-Variable target
}

#Step 1. Move git templates to user home and make the hooks executable
Copy-Item ./git/.git-templates (Get-CustomConfig($usrDirs.bin)) -Force -Recurse -Container 
New-Variable -Name gitExecs -Value $(Get-ChildItem -Path "$(Get-CustomConfig($usrDirs.bin))/.git-templates" -Recurse -File) -Visibility Private -Option Constant
Update-ItemsToExec -Items $gitExecs

#Step 2. terminal specific
if ($IsMacOS) {
    #make powershell default
    chsh -s $(which pwsh)
}

#Step 3. Move dotfiles to user home
New-Variable -Name dotFileNames -Value @('./git/.gitconfig','./git/.gitignore_global');
New-Variable -Name dotFiles -Value $(Get-ChildItem -Path $dotFileNames -File -Hidden) -Visibility Private -Option Constant
$dotFiles | ForEach-Object -Process { Copy-Item $_ (Get-CustomConfig($usrDirs.bin))-Force }

if (!(Test-Path $PROFILE)) { New-Item $PROFILE -Force }
Copy-Item ./Microsoft.PowerShell_profile.ps1 $PROFILE -Force
Copy-Item ./PowerShell_profile_fns.ps1 (Get-Item $PROFILE).Directory.FullName -Force

    #3.1 Powershell (PS Modules are OS agnostic)
    Copy-Item ./powershell/Modules (Get-CustomConfig($usrDirs.pwshModuleParentDir)) -Force -Recurse -Container

#Step 4. Move all execs to $usrDirs.bin and make them executable if needed
New-Variable -Name binItems -Value $(Get-ChildItem -Path ./bin,'./git/custom commands' -Recurse -File) -Visibility Private -Option Constant
Update-ItemsToExec -Items $binItems
$binItems | ForEach-Object { 
    if ($IsMacOS) {
        Copy-Item -Path $_.FullName -Destination (Get-CustomConfig($usrDirs.bin))-Force 
    }
    elseif ($_.BaseName.StartsWith("git-")) {
        #on windows (presumably), so we will copy with .sh extension and add a global git alias
        Copy-Item -Path $_.FullName -Destination "$(Get-CustomConfig($usrDirs.bin))/.git-commands/$($_.BaseName).sh" -Force 

        $ResolvedPath = Resolve-Path "$(Get-CustomConfig($usrDirs.bin))/.git-commands/$($_.BaseName).sh"
        git.exe config --global alias."$($_.BaseName.substring(4))" ('!f() { bash \"' + $ResolvedPath + '\" $@; };f')
    }
}