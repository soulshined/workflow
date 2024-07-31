$VerbosePreference = 'Continue'
$Env:PSModulePath += [IO.Path]::PathSeparator + (Join-Path $PSScriptRoot 'powershell' 'Modules' -Resolve)