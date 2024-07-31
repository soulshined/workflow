using module Freer.Utility

function Test-GitRepository {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(HelpMessage = "Directory or folder name of repository", ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Directory = $PWD
    )

    process {
        $Target = Get-Item (Join-Path $Directory '.git' -Resolve) -Force
        if (-not $Target) {
            return $false
        }

        git -C $Directory status 2>&1 | Out-Null
        return $LASTEXITCODE -eq 0
    }
}

function Reset-GitRepository {
    [CmdletBinding()]
    [Alias('Reset-Git')]
    param(
        [Parameter(ValueFromPipeline = $true, HelpMessage = "Directory or folder name of repository", Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Directory = $PWD
    )

    process {
        $Directory = Resolve-Path $Directory
        $Repositories = if (Test-GitRepository $Directory) {
            , (Get-Item $Directory)
        }
        else {
            $Directory | Get-ChildItem -Directory | ? Test-GitRepository
        }

        $Message = "{0} Repositor{1} found" -f $Repositories.Count, ($Repositories.Count -gt 1 ? 'ies' : 'y')

        if (-not $Repositories.Count) {
            Write-Host "No repositories found for directory $Directory"
            return
        }
        elseif ($Repositories.Count -eq 1) {
            $Message = "Reinitialize {0}" -f $Repositories[0]
        }

        $Election = Prompt-Choice '&No', '&Yes' -Title "Reinitialize Git [🔍 $Directory]" -Message "$Message`n`e[1;31mContinue?`e[0m" -Default 0

        if ($Election -eq 1) {
            $Repositories | % {
                Remove-Item (Join-Path $_ '.git' 'hooks') -Recurse -Force -ErrorAction Ignore
                git -C $_ init
            }
        }
    }
}