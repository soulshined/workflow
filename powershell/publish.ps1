param(
    [Parameter(Mandatory = $true)]
    [ArgumentCompletions('Prerelease', 'Major', 'Minor', 'Patch')]
    [ValidateNotNullOrWhiteSpace()]
    [string]$ReleaseType,
    [switch]$Scaffold
)

$DebugPreference = 'Continue'
$ErrorActionPreference = 'Stop'

if (-not $Env:NuGetApiKey) {
    throw 'NuGetApiKey not found in env vars'
}

$Date = Get-Date
$ReleaseTypes = 'Prerelease', 'Major', 'Minor', 'Patch'
$DefaultReleaseType = 3

for ($i = 0; $i -lt $ReleaseTypes.Count; $i++) {
    if ($ReleaseTypes[$i] -ieq $ReleaseType) {
        $DefaultReleaseType = $i
        break
    }
}

$Prerelease = $DefaultReleaseType -eq 0 ? ('update' + $Date.Day + $Date.Month + $Date.Year)  : $null

$Choice = $ReleaseType ? $DefaultReleaseType : $Host.UI.PromptForChoice('Update Manifest', 'Release Type', $ReleaseTypes, $DefaultReleaseType)

function New-ManifestData {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true)]
        [string]$Guid,

        [ValidateNotNullOrWhiteSpace()]
        [string]$WikiHome,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$Description,

        [string[]]$Tags,

        [string]$PowerShellVersion = '7.4',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string[]]$FunctionsToExport,

        [Parameter(Mandatory = $false)]
        [string[]]$RequiredModules,

        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $false)]
        [string[]]$ExternalModuleDependencies

    )
    process {
        $path = Join-Path $PSScriptRoot 'Modules' $ModuleName "${ModuleName}.psd1"

        $Current = Invoke-Expression (gc $path -raw)

        [version]$CurrentVersion = $Current.ModuleVersion

        $NewVersion = switch ($Choice) {
            1 { [version]::new(($CurrentVersion.Major + 1), 0, 0) }
            2 { [version]::new($CurrentVersion.Major, ($CurrentVersion.Minor + 1), 0) }
            3 { [version]::new($CurrentVersion.Major, $CurrentVersion.Minor, ($CurrentVersion.Build + 1)) }
            Default { $CurrentVersion }
        }

        $md = @{
            Path              = $path
            RootModule        = "$ModuleName.psm1"
            Author            = 'David Freer'
            PowerShellVersion = $PowerShellVersion
            GUID              = $Guid
            Description       = $Description
            Tags              = $Tags
            FunctionsToExport = $FunctionsToExport
            ProjectUri        = "https://github.com/soulshined/workflow/tree/master/powershell/Modules/$ModuleName"
            ReleaseNotes      = "https://github.com/soulshined/workflow/tree/master/powershell/Modules/$ModuleName/CHANGELOG.md"
            Prerelease        = $Prerelease ?? ''
            ModuleVersion     = $NewVersion
        }

        if ($WikiHome) {
            $md.HelpInfoUri = "https://github.com/soulshined/workflow/wiki/$WikiHome"
        }

        if ($ExternalModuleDependencies) {
            $md.ExternalModuleDependencies = $ExternalModuleDependencies
            $md.RequiredModules += $RequiredModules
        }

        if ($RequiredModules) {
            $md.RequiredModules += $RequiredModules
        }

        if ($md.RequiredModules) {
            $md.RequiredModules = $md.RequiredModules | Sort-Object -Unique
        }

        $md
    }
}

function Publish-MyModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        [version]$ModuleVersion
    )

    process {
        'Publishing {0} v{1}' -f $ModuleName, $ModuleVersion | Write-Host
        Publish-Module -Path (Join-Path $PSScriptRoot 'Modules' $ModuleName) -NuGetApiKey $Env:NuGetApiKey -Confirm
    }
}

if ($Scaffold.IsPresent) {
    $MD = New-ManifestData Scaffold `
        -WikiHome 'Scaffold-%E2%80%90-PowerShell-Module' `
        -Guid 'fe3272d3-406f-490a-a84a-f5e7d535e605' `
        -Description 'Scaffold is project/directory orchestration utility for creating similiar/frequently created folder & file layouts' `
        -Tags 'Template', 'Scaffold', 'Orchestrate', 'Layout', 'Duplicate' `
        -FunctionsToExport 'ConvertTo-Scaffold', 'Get-Scaffolds',
    'Mount-Scaffold',
    'Remove-Scaffold',
    'SaveAs-Scaffold' `
        -ExternalModuleDependencies powershell-yaml `
        -RequiredModules powershell-yaml

    Update-ModuleManifest @MD
    Invoke-Formatter (Get-Content $MD.Path -Raw) | Out-File $MD.Path -Force -NoNewline
    Publish-MyModule Scaffold $MD.ModuleVersion
}