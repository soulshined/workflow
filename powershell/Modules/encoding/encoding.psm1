function Get-Charset {
  Param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Charset
  )

  begin {
    [System.Text.Encoding]$_Charset = [System.Text.Encoding]::ASCII

    switch ($Charset) {
      "UTF32" {
        $_Charset = [System.Text.Encoding]::UTF32
      }
      "UTF7" {
        $_Charset = [System.Text.Encoding]::UTF7
      }
      "UTF8" {
        $_Charset = [System.Text.Encoding]::UTF8
      }
      "BigEndianUnicode" {
        $_Charset = [System.Text.Encoding]::BigEndianUnicode
      }
      "Unicode" { 
        $_Charset = [System.Text.Encoding]::Unicode
      }
    }

    return $_Charset
  }

}
function Get-Encoded {
  [CmdletBinding()]
  [Alias("Encoded")]
  Param (
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Value,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Base64")]
    [String]
    $Type = "Base64",
    
    [Parameter()]
    [ValidateSet("Ascii", "UTF32", "UTF7", "UTF8", "BigEndianUnicode", "Unicode")] #should maybe Add-Type if DRY should be maintained universally
    [string]$Charset = "Ascii"
  )
    
  begin {
    [System.Text.Encoding]$_Charset = Get-Charset $Charset
  }
  
  process {

    switch ($Type) {
      "Base64" { 
        $bytes = $_Charset.GetBytes($Value)
        return [Convert]::ToBase64String($bytes)
      }
      default {
        return $null
      }
    }

  }
  
  end {
  }
}
function Get-Decoded {
  [CmdletBinding()]
  [Alias("Decoded")]
  Param (
    [Parameter(ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Value,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("base64")]
    [String]$Type = "base64",
    
    [Parameter()]
    [ValidateSet("Ascii", "UTF32", "UTF7", "UTF8", "BigEndianUnicode", "Unicode")]
    [string]$Charset = "Ascii"
  )
    
  begin {
    [System.Text.Encoding]$_Charset = Get-Charset $Charset
  }
  
  process {

    switch ($Type) {
      "base64" { 
        return $_Charset.GetString([System.Convert]::FromBase64String($Value))
      }
      default {
        return $null
      }
    }

  }
  
  end {
  }
}