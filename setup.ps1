#Requires -Version 7

param(
    [switch]$Git,
    [switch]$PowerShell
)

Write-Progress "Environment Setup" -Id 0

$local:IncludeAll = -not $Git.IsPresent -and `
    -not $PowerShell.IsPresent

$local:EV = @{
    Platform = switch ($true) {
        $IsWindows { 'win' }
        $IsMacOS { 'macos ' }
        $IsLinux { 'linux' }
        Default { throw "Platform not supported" }
    }
}

$local:Initializers = @{
    'Git Configurations'        = @{
        P = $Git.IsPresent
        V = (Join-Path $PSScriptRoot 'git' 'setup.ps1')
    }
    'PowerShell Configurations' = @{
        P = $PowerShell.IsPresent
        V = (Join-Path $PSScriptRoot 'powershell' 'setup.ps1')
    }
}

# TODO: set up ide's
# TODO: api keys/secrets?

foreach ($key in $local:Initializers.Keys) {
    Write-Progress -Id 1 -ParentId 0 $key

    $local:Value = $local:Initializers[$key]

    if (-not $local:IncludeAll -and -not $local:Value.P) {
        continue
    }

    . $local:Initializers[$key].V
}