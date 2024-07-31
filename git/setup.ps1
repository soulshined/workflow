$ErrorActionPreference = 'Stop'

$local:IncludeForCopyFilter = '.gitconfig.*', '.gitignore_global'

$local:Config = Get-Content (Join-Path $PSScriptRoot .gitconfig) -Raw
$local:PlatformPath = ".gitconfig.{0}" -f $EV.Platform

Write-Debug "Including $local:PlatformPath git config"

$local:Config += @"
`n`n[include]
    path = ${local:PlatformPath}
"@

$local:IncludeForCopyFilter | % {
    Get-ChildItem (Join-Path $PSScriptRoot $_) -Force | Copy-Item -Destination $HOME -Recurse -Force
}
$local:Config | Out-File "$HOME/.gitconfig"

Get-ChildItem "$PSScriptRoot/custom commands" -Filter 'git-*' -Force -Recurse | % -Begin {
    if ($IsWindows) {
        Remove-Item "$HOME/.git-commands" -Force -Recurse -ErrorAction SilentlyContinue
        New-Item "$HOME/.git-commands" -Force -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    }
} -Process {
    $BaseName = $_.BaseName

    if ($IsWindows) {
        $local:AliasName = $BaseName.Substring(4)
        $local:Destination = "$HOME/.git-commands/${BaseName}.sh"

        Copy-Item -Path $_ -Destination $local:Destination -Force
        git.exe config --global alias."$local:AliasName" ('!f() { bash \"' + (Resolve-Path $local:Destination) + '\" $@; };f')
    }
    else {
        chmod +x $_
        sudo cp $_ '/usr/local/bin'
    }
}

Remove-Item "$HOME/.git-templatedir" -Force -Recurse -ErrorAction Ignore
if (-not $IsWindows) {
    '.git-templatedir/hooks/pre-commit' | % {
        $Path = Resolve-Path "$PSScriptRoot/$_"
        chmod +x $Path
    }
}
Copy-Item (Join-Path $PSScriptRoot '.git-templatedir') -Destination $HOME -Recurse -Force
