oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json"  | Invoke-Expression -ErrorAction Ignore

if ($IsMacOs) {
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Escape -Function UndoAll
}

function New-CustomAlias([string]$Name, $Arguments) {
    if ($Arguments.StartsWith("!")) {
        $Arguments = $Arguments.Substring(1);
        $Arguments = "{0}{1}{2}" -f $Arguments.Substring(0, $Arguments.IndexOf(" ")),
        $(if ($IsWindows) { ".exe" }),
        $Arguments.Substring($Arguments.IndexOf(" "))
    }

    New-Item "Function:\global:$Name" -Value (Invoke-Command -ScriptBlock { $args } -ArgumentList $Arguments) | Out-Null
}

New-Variable DEV -Value '{{ $DEV }}' -Description 'Path to development specific directory' -Option AllScope, Constant, ReadOnly -Visibility Public -Force -ErrorAction Ignore -Scope Global
[System.Environment]::SetEnvironmentVariable('DEV', $DEV);

New-Variable DIR_SEP -Value ([IO.Path]::DirectorySeparatorChar) `
    -Description 'Freer.Runtime.Constants' `
    -Option AllScope, Constant, ReadOnly `
    -Visibility Public `
    -Force `
    -ErrorAction Ignore

New-Variable PATH_SEP -Value ([IO.Path]::PathSeparator) `
    -Description 'Freer.Runtime.Constants' `
    -Option AllScope, Constant, ReadOnly `
    -Visibility Public `
    -Force `
    -ErrorAction Ignore

New-Variable IsWorkOS `
    -Value ($IsMacOS -and ($Env:USER ?? $Env:USERNAME) -ieq 'dwf9649') `
    -Description 'Platform-like; To be used similar to $IsWindows / $IsLinux' `
    -Option AllScope, Constant, ReadOnly `
    -Visibility Public

if ($PWD.Path -eq (Resolve-Path "~").Path) {
    #this allows IDEs to still maintain control over initial dir for integrated terminals
    Set-Location $DEV
}

$Env:PSModulePath += $PATH_SEP + '{{ $PSModulePath }}'

# region {{ $ENV VARS }}
# endregion ENV VARS