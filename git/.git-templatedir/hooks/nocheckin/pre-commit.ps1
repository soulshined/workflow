param(
    [Parameter(Mandator=$true)]
    [string]$GitDir
)

$script:NO_CHECKIN_PATTERN = '(?:^|\s+)@NOCHECKIN(?:\s*$)'

git diff --name-only --cached | % {

    $local:Result = Join-Path $GitDir $_ | Select-String -Pattern $script:NO_CHECKIN_PATTERN -Context 2
    # echo -e "\033[1;33mWARNING: ${s_file} contains the ""@NOCHECKIN flag\033[0m\n"

    if ($local:Result.Count -gt 0) {
        Write-Debug "`@NOCHECKIN flag found in $_"
        $local:Result | Write-Verbose
        git reset $_
    }

}

if (git diff --name-only --cached) {
    Write-Debug "Nothing to commit"
    exit 1
}