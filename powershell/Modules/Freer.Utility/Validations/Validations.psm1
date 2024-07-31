function Test-IsNumeric {
  [Alias("IsNumeric")]
  Param(
    [Parameter(ValueFromPipeline, Mandatory = $true, Position = 0)]
    $InputObject
  )

  process {
    if ($InputObject -is [string]) {
      return $InputObject -match "^[\s]*\-?[\s]*\d+$|^[\s]*\-?[\s]*\d+\.\d+"
    }

    foreach ($t in [int], [int[]],
                   [byte], [byte[]],
                   [sbyte],[sbyte[]],
                   [long], [long[]],
                   [decimal], [decimal[]],
                   [single], [single[]],
                   [double], [double[]]) {
      if ($InputObject -is $t) { return $true; }
    }l

    return $false;
  }
}

function Test-IsInRange {
  [Alias("IsInRange")]
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

  process {
      if ($Exclusive) {
        return ($Value -gt $Min) -and ($Value -lt $Max)
      }

      return ($Value -ge $Min) -and ($Value -le $Max)
  }
}