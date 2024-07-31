function Invoke-Kubectl {
    [Alias("kube")]
    param(

        [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
        $Arguments,

        [Parameter(HelpMessage = "Namespace target [Default dev]")]
        [ValidateNotNullOrEmpty()]
        [string]$Namespace = 'dev',

        [ValidateNotNullOrEmpty()]
        [Parameter(HelpMessage = 'Regex pattern to filter output')]
        [string]$Filter,

        [Parameter]
        [switch]$IgnoreEvicted
    )

    process {
        $Context = if (@('prod', 'prd', 'production') -icontains $Namespace) {
            $Namespace = 'prd'
            'prod'
        }
        else { 'nonprod' }

        $Arguments += @('-n', $Namespace, '--context', $Context)

        $Results = kubectl @Arguments

        if ($IgnoreEvicted.IsPresent) {
            $Results = $Results | ? { $_ -inotmatch '\d+/\d+\s+Evicted' }
        }

        if ($Filter -and $Results.Count) {
            $Results[0]
            $Results | Select-String $Filter
        }
        else {
            $Results
        }
    }
}