$ErrorActionPreference = 'Stop'

Get-ChildItem $Env:PWD -Directory | % {
    Get-ChildItem $_ -Filter "pre-commit.ps1" -Force -Recurse | % {
        Invoke-Command $_ -ArgumentList $args

        if (git diff --name-only --cached) {
            Write-Debug "Nothing to commit"
            exit 1
        }
    }
}

throw "From entry"
exit 1