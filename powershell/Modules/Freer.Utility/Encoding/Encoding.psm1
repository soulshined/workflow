function ConvertTo-Base64 {
    [Alias("base64")]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -is [string] -or $_ -is [byte[]] -or $_ -is [byte] })]
        $Value,

        [ValidateNotNull()]
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
    )

    process {
        [Convert]::ToBase64String( `
                $Value -is [byte[]] -or $Value -is [byte] `
                ? $Value `
                : $Encoding.GetBytes($Value) `
        )
    }
}

function ConvertFrom-Base64 {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -is [string] -or $_ -is [byte[]] -or $_ -is [byte] })]
        $Value,

        [ValidateNotNull()]
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
    )

    process {
        $Encoding.GetString([Convert]::FromBase64String( `
                    $Value -is [byte] -or $Value -is [byte[]] `
                    ? $Encoding.GetString($Value) `
                    : $Value `
            ))
    }
}

function ConvertTo-Encoding {
    [Alias("encode")]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('Base64', 'BasicAuth')]
        [string]$Type,

        [Parameter()]
        [ValidateNotNull()]
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
    )

    dynamicparam {
        $RuntimeParams = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        switch ($Type.ToLower()) {
            basicauth {
                $BaseAttrSet = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
                $BaseAttrSet.Add([System.Management.Automation.ParameterAttribute]@{
                        Mandatory         = $true
                        ValueFromPipeline = $true
                    })

                $RuntimeParams.Add('Username', [System.Management.Automation.RuntimeDefinedParameter]::new('Username', [string], $BaseAttrSet))

                $RuntimeParams.Add('Password', [System.Management.Automation.RuntimeDefinedParameter]::new('Password', [string], $BaseAttrSet))
            }
            Default {
                $BaseAttrSet = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
                $BaseAttrSet.Add([System.Management.Automation.ParameterAttribute]@{
                        Mandatory                       = $true
                        ValueFromPipeline               = $true
                        ValueFromPipelineByPropertyName = $true
                    })

                $RuntimeParams.Add("Value", [System.Management.Automation.RuntimeDefinedParameter]::new('Value', [string], $BaseAttrSet))
            }
        }

        $RuntimeParams
    }

    process {
        switch ($Type.ToLower()) {
            base64 {
                ConvertTo-Base64 -Value $PSBoundParameters.Value -Encoding $Encoding
            }
            basicauth {
                $Username = $PSBoundParameters.Username
                $Password = $PSBoundParameters.Password
                ConvertTo-Base64 -Value "${Username}:${Password}" -Encoding $Encoding
            }
            Default {}
        }
    }
}