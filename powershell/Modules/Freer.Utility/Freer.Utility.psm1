function Join-PSScriptRootPath {
    [Alias("jpsp")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$ChildPath,
        [Parameter(ValueFromRemainingArguments = $true, ValueFromPipeline = $true, Position = 1)]
        [string[]]$AdditionalChildPath,

        [switch]$Resolve
    )

    process {
        Join-Path -Path $MyInvocation.PSScriptRoot `
            -ChildPath $ChildPath `
            -AdditionalChildPath $AdditionalChildPath `
            -Resolve:$Resolve
    }
}