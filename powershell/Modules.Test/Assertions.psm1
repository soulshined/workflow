#Requires -Module Pester

function Should-BeScaffoldItem {
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [psobject]$ActualValue,
        [switch]$Negate,
        [string]$Because,

        [string]$PSTypeName,
        $Name,
        [string[]]$FullName,
        [string]$Contents,

        $CallerSessionState
    )

    process {
        $ExpectedFullName = if ($FullName.Length -ge 2) {
            if ($FullName.Length -eq 2) {
                Join-Path $FullName[0] -ChildPath $FullName[1]
            }
            else {
                Join-Path $FullName[0] -ChildPath $FullName[1] -AdditionalChildPath $FullName[2..$FullName.Length]
            }
        }
        else {
            $FullName[0]
        }

        if ($ActualValue.TypeNames -contains 'Scaffold.Container') {
            $ExpectedFullName += [IO.Path]::DirectorySeparatorChar
        }



        $ActualValue.PathType | Should -BeExactly $PathType
        $ActualValue.Name | Should -BeExactly $Name
        $ActualValue.FullName | Should -BeExactly $ExpectedFullName
        if ($ActualValue.TypeNames -contains 'Scaffold.Leaf') {
            $ActualValue.Contents.Trim() | Should -BeExactly $Contents.Trim()
        }

        return [pscustomobject]@{
            Succeeded = $true
        }
    }
}

Add-ShouldOperator -Name BeScaffoldItem `
    -InternalName 'Should-BeScaffoldItem' `
    -Test ${function:Should-BeScaffoldItem}