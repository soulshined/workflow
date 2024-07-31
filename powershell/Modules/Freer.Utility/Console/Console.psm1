[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope = 'function', Target = 'Prompt-*')]
param()

function Prompt-Input {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [String]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrWhiteSpace()]
        [String]$Default,

        [ValidateSet('bool', 'integer', 'int', 'string', 'long', 'double')]
        [ArgumentCompletions(
            'bool', 'int', 'string', 'long', 'double'
        )]
        [string]$ExpectedDataType = 'string',

        [ValidateSet('phone', 'email', 'zipcode')]
        [ArgumentCompletions(
            'phone', 'email', 'zipcode'
        )]
        [string]$ExpectedInputFormat,
        [switch]$AllowNull
    )

    begin {
        $Message = $Message + ($Default ? " (default is `"$Default`")" : '')

        function IsExpectedDataType($data) {
            switch ($ExpectedDataType.ToLower()) {
                'string' { $true }
                'bool' { $data -imatch "^(0|1|y|yes|n|no|t|f|true|false)$" }
                'int' { $data -match "^\-?\d+$" }
                'long' { $data -match "^\-?\d+$" }
                'double' { $data -match "^\-?\d+\.?\d+$" }
                Default { $false }
            }
        }

        function IsExpectedInputFormat($data) {
            if (-not $ExpectedInputFormat) { return $true }

            switch ($ExpectedInputFormat.ToLower()) {
                'zipcode' { $data -match "^(\d{5}|\d{5}\-\d{4})$" }
                'phone' { $data -match "^(\d{0,6}\d{3}([-. ])\d{3}\2\d{4})$" }
                'email' { $data -match "^[a-zA-Z0-9][\w_]+@[\w]+\.[\w]+$" }
                Default { $false }
            }
        }

        function TypeCast($data) {
            switch ($ExpectedDataType.ToLower()) {
                'bool' { $data -imatch "^(1|y|yes|t|true)$" }
                'int' { [int]::Parse($data) }
                'long' { [long]::Parse($data) }
                'double' { [double]::Parse($data) }
                Default { $data }
            }
        }
    }

    process {
        $Result = (Read-Host $Message).Trim()

        if ([string]::IsNullOrWhiteSpace($Result) -and $Default) {
            return $AllowNull.IsPresent ? $null : $Default
        }

        if ([string]::IsNullOrWhiteSpace($Result) -and $AllowNull.IsPresent) {
            return $null
        }

        while ([string]::IsNullOrWhiteSpace($Result)) {
            $Result = (Read-Host $Message).Trim()
        }

        while (-not (IsExpectedDataType $Result)) {
            Write-Error "Invalid data type - expecting $ExpectedDataType"
            $Result = (Read-Host $Message).Trim()
        }

        while (-not (IsExpectedInputFormat $Result)) {
            Write-Error "Invalid format - expecting $ExpectedInputFormat"
            $Result = (Read-Host $Message).Trim()
        }

        TypeCast $Result
    }
}

function Prompt-Choice {
    Param(

        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [object[]]$Choices,

        [ValidateRange(0, [int32]::MaxValue)]
        [int32]$Default = -1,

        [String]$Title,
        [String]$Message
    )

    begin {
        $options = @()
    }

    process {
        $Choices | % {
            if ($_ -is [object[]]) {
                $options += New-Object System.Management.Automation.Host.ChoiceDescription $_[0].ToString(), $_[1].ToString()
            }
            elseif ($_ -is [hashtable]) {
                $options += New-Object System.Management.Automation.Host.ChoiceDescription $_.Value, $_.HelpMessage ?? $_.Help
            }
            else { $options += $_.ToString() }
        }
    }

    end {
        return $Host.UI.PromptForChoice($Title, $Message, $options, $Default)
    }
}