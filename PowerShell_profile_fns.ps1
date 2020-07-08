
Function Get-CustomConfig($Value) { if ($IsMacOs) { $Value.mac } else { $Value.win } }

Function Start-NewPowershell {
    [alias("new")]
    Param(
        [Parameter()]
        [switch]$KillCurrent
    )

    Start-Process powershell

    if ($KillCurrent) {
        Start-Sleep 1
        Stop-Process -Id $pid -Force
    }
}

Function NavigateBack {
    [alias("..")]
    param(
        [Parameter(Position = 1)]
        [Int32]$Quantity = 1
    )

    Set-Location -Path ("../" * (0, $Quantity | Measure-Object -Maximum).Maximum)
}

Function New-CustomAlias([string]$Name, $Arguments) {
    if ($Arguments.StartsWith("!")) {
        # create an alias to run a win exec or mac bin dynamically
        $Arguments = $Arguments.Substring(1);
        $Arguments = "{0}{1}{2}" -f $Arguments.Substring(0, $Arguments.IndexOf(" ")),
            $(if (!$IsMacOs) { ".exe" }),
            $Arguments.Substring($Arguments.IndexOf(" "))
    }

    New-Item "Function:\global:$Name" -Value (Invoke-Command -ScriptBlock { $args } -ArgumentList $Arguments) | Out-Null
}