function IsType {

  Param(
    [Parameter(ValueFromPipeline, Mandatory = $true, Position = 0)]
    $Value,

    [Parameter(Mandatory = $true, Position = 1)]
    [Type[]]$Types
  )

  #For debugging:
  # $Types | % { Write-Host "Testing '$_' Result: $($_ -eq $Value.GetType())" }

  return $Types -contains $Value.GetType()
}

function IsNumeric {
  Param(
    [Parameter(ValueFromPipeline, Mandatory = $true, Position = 0)]
    $Value
  )
  return (IsType $Value @([int],
      [byte],
      [sbyte],
      [long],
      [decimal],
      [single],
      [double]
    )
  )
}

function IsStringNumeric {
    
  Param(
    [Parameter(ValueFromPipeline, Mandatory = $true, Position = 0)]
    $Value
  )

  if ($Value -IsNot [String]) { throw "$Value is expected to be a string type to validate if it's numeric. Use 'IsNumeric' for all other data type values" }
  return ($Value -match "^[\s]*\-?[\s]*\d+$|^[\s]*\-?[\s]*\d+\.\d+")
}

#this does not type cast or ensure type equality intentionally
function IsInRange {
  Param(
    [Parameter(ValueFromPipeline, Mandatory = $true, Position = 0)]
    $Value,

    [Parameter(Mandatory = $true, Position = 1)]
    $Min,

    [Parameter(Mandatory = $true, Position = 2)]
    $Max,

    [Parameter()]
    [switch] $Exclusive
  )
  
  if ($Exclusive) {
    return ($Value -gt $Min) -and ($Value -lt $Max)
  }

  return ($Value -ge $Min) -and ($Value -le $Max)
}