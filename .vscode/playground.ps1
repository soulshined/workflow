$Env:SCAFFOLD_HOME = Join-Path $PSScriptRoot scaffolds

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

$Env:PSModulePath += [IO.Path]::PathSeparator + (Join-Path $PSScriptRoot '..' 'powershell' 'Modules' -Resolve)