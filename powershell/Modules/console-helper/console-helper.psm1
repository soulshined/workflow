#requires -version 5
<#
.SYNOPSIS
  CLI helper for user input

.DESCRIPTION
  User input helper. This module helps manipulate and prompt for user input, and like 
  usual it's additional syntax sugar for known methods like Get-Choices

.NOTES
  Version:        1.0
  Author:         Freer
  Creation Date:  11 Sept 2019
  Purpose/Change: Initial script development

.EXAMPLE
  Get-Choices <choices> -default <default> -Title <title> -Message <message>

  Get-Input <message> -ExpectedDataType "int" -AllowNull
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Set Error Action
$ErrorActionPreference = "Stop"

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#-----------------------------------------------------------[Execution]------------------------------------------------------------

function Get-Input {
  [CmdletBinding()]
  [Alias("Prompt")]
  Param (    
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [String]$Message,
  
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$Default,

    [Parameter(Mandatory = $false)]
    [switch]$AllowNull,

    [Parameter()]
    [ValidateSet("bool", "boolean", "number", "integer", "int", "string", "long")]
    [string]$ExpectedDataType = "string",

    [Parameter()]
    [string]$ExpectedDataTypeErrorMessage = $null,

    [Parameter()]
    [ValidateSet("phone", "email", "zipcode")]
    [string]$ExpectedInputFormat,

    [Parameter()]
    [string]$ExpectedInputFormatErrorMessage = $null
  )
  
  begin {
    $_message = $Message + (?: $Default ? " (default is `"$Default`")" : "")

    switch ($ExpectedDataType) {
      'string'  { [string] $_expectedDataType = $null }
      'number'  { [double] $_expectedDataType = $null }
      'long'    { [long] $_expectedDataType = $null }
      'int'     { [int] $_expectedDataType = $null }
      'integer' { [int] $_expectedDataType = $null }
      'bool'    { [boolean] $_expectedDataType = $false }
      'boolean' { [boolean] $_expectedDataType = $false }
      default   {
        throw "Uncaught ExpectedDataType"
      }
    }

    function IsExpectedDataType($data) {
      if ($_expectedDataType.GetType() -eq [string]) { return $true }

      if (IsType $_expectedDataType @([int], [long])) {
        $isMatch = $data -match "^\-?\d+$"
        # Write-Host "matches [int],[long] = $isMatch"
        return $isMatch
      }

      if (IsType $_expectedDataType @([boolean])) {
        $isMatch = $data -imatch "^(0|1|y|yes|n|no|t|f|true|false)$"
        # Write-Host "matches [boolean] = $isMatch"
        return $isMatch
      }

      if (IsType $_expectedDataType @([double])) {
        $isMatch = $data -match "^\-?\d+\.?\d+$"
        # Write-Host "matches [double] = $isMatch"
        return $isMatch
      }
    }

    function IsExpectedInputFormat($data) {
      if (!$ExpectedInputFormat) { return $true }
      
      if ($ExpectedInputFormat -ieq 'zipcode') {
        return $data -match "^(\d{5}|\d{5}\-\d{4})$"
      }

      if ($ExpectedInputFormat -ieq 'phone') {
        return $data -match "^(\d{0,6}\d{3}([-. ])\d{3}\2\d{4})$"
      }

      if ($ExpectedInputFormat -ieq 'email') {
        return $data -match "^[a-zA-Z0-9][\w_]+@[\w]+\.[\w]+$"
      }
    }

    function Get-TypeCastedInput($data) {
      $type = $_expectedDataType.GetType()

      if ($type -eq [int]) { return [int]$data }
      if ($type -eq [long]) { return [long]$data }
      if ($type -eq [boolean]) {
        if ($data -imatch "^(1|y|yes|t|true)$") {
          return $true
        }

        return $false
      }
      if ($type -eq [double]) { return [double]::Parse($data) }

      return $data
    }
  }
  
  process {    
    
    $result = (Read-Host $_message).Trim()

    if ([string]::IsNullOrWhiteSpace($result) -and $Default) {
      return $Default
    }
    
    if ([string]::IsNullOrWhiteSpace($result) -and !$AllowNull) {
      #prompt user that nulls aren't allowed
      do {
        $result = (Read-Host $_message).Trim()
      } until (![string]::IsNullOrWhiteSpace($result))
    }

    $msg = ?: $ExpectedDataTypeErrorMessage ?? "Invalid data type; expecting $($_expectedDataType.GetType().FullName)"
    while (-not (IsExpectedDataType($result))) {
      $result = (Read-Host $msg).Trim()
    }
    
    $msg = ?: $ExpectedInputFormatErrorMessage ?? "Invalid format type; expecting $ExpectedInputFormat"
    while (-not (IsExpectedInputFormat($result))) {
      $result = (Read-Host $msg).Trim()
    }
    
    return Get-TypeCastedInput($result)
  }
  
  end {
  }
}

function Get-Choice {
  [Alias("PromptChoice")]
  Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [Object[]]$Choices,

    [ValidateRange(0, [int32]::MaxValue)]
    [int32]$Default,

    [String]$Title,
    [String]$Message
  )

  begin {
    $options = $Choices | ForEach-Object {
      if (IsType $_ @([Object[]])) {
        return New-Object System.Management.Automation.Host.ChoiceDescription $_[0], $_[1]
      }
      return $_
    }
  }

  process {
    return $Host.UI.PromptForChoice($Title, $Message, $options, $Default)
  }

  end {

  }
}

Export-ModuleMember -Function Get-Input, Get-Choice -Alias @("Prompt", "PromptChoice")