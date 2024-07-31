[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    <#Category#>'PSUseApprovedVerbs', <#CheckId#>'',
    Scope = 'function',
    Target = 'SaveAs-*'
)]
param()

if (-not $Env:SCAFFOLD_HOME) {
    $ENV:SCAFFOLD_HOME = "$HOME/.scaffolds"
}

New-Item $ENV:SCAFFOLD_HOME -ItemType Directory -ErrorAction Ignore

#region PRIVATE
function New-ScaffoldLeaf {
    [OutputType('Scaffold.Leaf')]
    param(
        [string]$Name,
        [PSTypeName('Scaffold.Container')]$Container,
        [string]$Contents
    )
    process {
        $o = [pscustomobject]@{
            Name              = $Name
            FullName          = $Container.FullName ? (Join-Path $Container.FullName $Name) : $Name
            Contents          = [string]::IsNullOrWhiteSpace($Contents) ? $null : $Contents
            ParameterizedVars = ($Contents | sls -Pattern '{{\s*(?<var>[a-zA-Z][a-zA-Z0-9\-_ ]+)\s*}}' -AllMatches).Matches
        }

        'Block', 'Leaf' | % {
            $o.PSObject.TypeNames.Insert(0, "Scaffold.$_")
        }

        $o
    }
}

function New-ScaffoldContainer {
    [OutputType('Scaffold.Container')]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$FullName
    )
    process {
        $o = [pscustomobject]@{
            Name     = $Name
            FullName = $FullName
            Folders  = @{}
            Files    = @()
            Scaffold = @()
        }

        'Block', 'Container' | % {
            $o.PSObject.TypeNames.Insert(0, "Scaffold.$_")
        }

        $o
    }
}

function Read-ScaffoldLeaf {
    param(
        [System.Collections.Generic.List[object]]$Leaf,
        [PSTypeName('Scaffold.Container')]$ParentContainer
    )

    process {
        $Result = @()

        $Leaf | % {
            if ($_ -is [string]) {
                $Result += New-ScaffoldLeaf $_ $ParentContainer
            }
            elseif ($_ -is [hashtable]) {
                $Keys = $_.Keys

                if ($Keys.Count -ne 1) {
                    throw 'Invalid scaffold syntax for file. Only expecting 1 key and 1 string, optional, value'
                }

                $V = $_.Values | Select -First 1

                if ($V -is [string]) {
                    $Result += New-ScaffoldLeaf $Keys[0] $ParentContainer $V
                }
                else {
                    throw 'Invalid scaffold syntax for file. Only expecting 1 key and 1 string, optional, value'
                }
            }
        }

        $Result
    }
}

function Read-ScaffoldContainer {
    param(
        [hashtable]$Container,
        [string]$ParentPath = ''
    )

    process {
        $Result = New-ScaffoldContainer -Name '' -FullName $ParentPath

        $Scaffold = @{
            Files   = @()
            Folders = @()
        }

        $Container.GetEnumerator() | % {
            $Key = $_.Key.Trim()

            if ($Key -ieq '[files]') {
                $Leaf = Read-ScaffoldLeaf $_.Value $Result
                $Result.Files += $Leaf
                $Scaffold.Files += $Leaf
            }
            elseif ($_.Value -is [hashtable]) {
                if ($Key.EndsWith('/')) {
                    $Key = $Key.Substring(0, $Key.Length - 1)
                }

                $pp = $ParentPath ? (Join-Path $ParentPath $Key) : $Key
                $Read = Read-ScaffoldContainer $_.Value -ParentPath $pp
                $Result.Folders += @{ $Key = $Read }
                $Scaffold.Folders += $Read.Scaffold.Folders
                $Scaffold.Files += $Read.Scaffold.Files
            }
            elseif ($Key.EndsWith('/')) {
                $FolderName = $Key.Substring(0, $Key.Length - 1)
                $FullName = $ParentPath ? (Join-Path $ParentPath $FolderName) : $FolderName
                $ScaffoldContainer = New-ScaffoldContainer -Name $FolderName -FullName $FullName
                $Result.Folders += @{ $FolderName = $ScaffoldContainer }
                $Scaffold.Folders += $ScaffoldContainer
            }
            else {
                throw "Invalid scaffold snytax for key=${Key}"
            }
        }

        @{
            Result   = $Result
            Scaffold = $Scaffold
        }
    }
}
function Read-Directory {
    param(
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo]$Directory = $PWD
    )

    process {
        Get-ChildItem $Directory -Recurse -Force | % -Begin { $Result = [ordered]@{} } -Process {
            $Relative = Resolve-Path $_.FullName -Relative -RelativeBasePath $Directory

            [string[]]$s = $Relative -split ("\{0}" -f [IO.Path]::DirectorySeparatorChar) | ? { $_ }
            $Q = [System.Collections.Generic.Queue[string]]::new($s)

            $Current = $Result
            while ($Q.Count -gt 1) {
                $i = $Q.Dequeue()
                if ($i -eq '.') { continue }
                if ($Current.Keys -inotcontains $i) {
                    $Current[$i] = [ordered]@{ }
                    $Current = $Current[$i]
                }
                else {
                    $Current = $Current[$i]
                }
            }

            if ($_.Attributes.HasFlag([System.IO.FileAttributes]::Directory)) {
                $Current[$Q.Dequeue()] = [ordered]@{  }
            }
            else {
                if (-not $Current['[files]']) {
                    $Current.'[files]' = @()
                }
                $Name = $Q.Dequeue()
                $Current['[files]'] += @{ "$Name" = "{0}" -f (gc $_.FullName -raw) }
            }
        } -End { $Result }
    }
}
#endregion PRIVATE

function SaveAs-Scaffold {
    <#
    .SYNOPSIS
        Save a directory in it's current state (file content included) to then be used to create the same state somewhere else
    .DESCRIPTION
        Save a directory in it's current state (file content included) to then be used to create the same state somewhere else

        For example, assume you need to create a new PowerShell module you want to publish to the powershell gallery.

        You could simply create a scaffold of that type of project so it can be mounted in future directories that don't have those contents.

        Now for the next module you want to create you would simply navigate to a directory and type `Mount-Scaffold pwsh:gallery`

        Additionally provide a brief description about the scaffold for `Get-Scaffolds` output
    .NOTES
        Additionally provide a brief description about the scaffold for `Get-Scaffolds` output
    .EXAMPLE
        PS> SaveAs-Scaffold './path/to/directory' -Name pwsh:gallery -About 'A scaffold for new powershell modules that are published to gallery'
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            HelpMessage = 'Directory of folder to take a scaffold snapshot',
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo]$Directory = $PWD,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 1,
            HelpMessage = 'Identifier of the scaffold to refer as later in scaffold snytax: `<category>:<name>'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(
            Position = 2,
            HelpMessage = 'Description of the scaffold'
        )]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$About,

        [switch]$Confirm
    )

    process {
        if ($Name.Trim() -inotmatch '[a-zA-Z]+\:[a-zA-Z0-9-_]') {
            throw "$Name is not valid scaffold syntax: <category>:<name>"
        }

        $FileName = '{0}.scaffold' -f $Name.Trim().ToLower() -replace ':', '-'

        Remove-Scaffold $Name

        ConvertTo-Yaml ([ordered]@{
                name     = $Name
                about    = $About
                scaffold = Read-Directory $Directory
            }) | Out-File (Join-Path $ENV:SCAFFOLD_HOME $FileName) -Confirm:$Confirm -Force
    }
}

function Remove-Scaffold {
    <#
    .SYNOPSIS
        Remove the scaffold and it's files from device by it's scaffold identifier
    #>
    [CmdletBinding()]
    param(
        [ArgumentCompleter({ (Get-Scaffolds).Name })]
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Identifier of the scaffold to refer as later in scaffold snytax `<category>:<name>'
        )]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name
    )

    process {
        $FileName = '{0}.scaffold' -f $Name.Trim().ToLower() -replace ':', '-'
        Remove-Item (Join-Path $ENV:SCAFFOLD_HOME $FileName) -Force -ErrorAction Ignore
    }
}

function Get-Scaffolds {
    [OutputType('Scaffold.Leaf', 'Scaffold.Container')]
    param()

    process {
        Get-ChildItem $ENV:SCAFFOLD_HOME -Include *.scaffold -File -Recurse -ErrorAction Ignore | % {
            ConvertTo-Scaffold -Path $_
        }
    }
}

function Mount-Scaffold {
    <#
    .SYNOPSIS
        Mount one to many scaffolds to a given destination
    .DESCRIPTION
        Mount one to many scaffolds to a given destination

        Mounting scaffolds effectively means you want to take a scaffold (layout/wireframe) of a directory and apply that layout to any directory of choice

        When mounting, you can do it silently or interactively

        When mounting silently:
        The folders defined in the scaffold (empty or not) are applied to the given destination, overwriting
        The files defined in the scaffold are applied to it's given destination via `Out-File -Force`,
            including any content in the file

        When mounting interactively:
        The folders defined in the scaffold (empty or not) are applied to the given destination, overwriting
        for each file defined in the scaffold:
            1. Template vars are searched for with the pattern: \{\{\s*(?<var>[a-zA-Z][a-zA-Z0-9\-_ ]+)\s*\}\}
            2. Duplicate matches are removed
            3. for each match:
                1. get value from user via `Read-Host`
                2. replace all of group 'var' with value
                3. update file content with replacements
            4. Apply file with `Out-File -Force -NoNewLine`
    .EXAMPLE
        Mount-Scaffold pwsh:gallery
        Mounts a scaffold of a directory created to publish powershell modules
    .EXAMPLE
        Mount-Scaffold pwsh:gallery, pwsh:cmdlet
        Mounts a scaffold of a directory created to publish powershell modules and also mounts a scaffold
        of a directory created to create a dll module
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "Name of a registered scaffold you wish to mount",
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({ (Get-Scaffolds).Name })]
        [string[]]$Name,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("Directory")]
        [String]$Destination = $PWD,

        [Parameter(
            HelpMessage = "When a file has template syntax all the parameters found will be prompted for values to be supplied"
        )]
        [switch]$Interactive
    )

    process {

        if (-not $Interactive.IsPresent) {
            Write-Progress -Id 0 -Activity 'Scaffold Mount'
        }

        $Name | % {
            $Target = '{0}.scaffold' -f (Join-Path $ENV:SCAFFOLD_HOME ($_.Trim().ToLower() -replace ':', '-'))
            if (-not (Test-Path $Target -PathType Leaf)) {
                Write-Error "'$_' scaffold not registered"
                return
            }

            Write-Progress -Id 1 -ParentId 0 -Activity $_.Trim().ToLower()

            ConvertTo-Scaffold (Get-Content $Target -Raw) | ? {
                $_.Scaffold | % {
                    $tns = $_.PSObject.TypeNames
                    if ($_.PSObject.TypeNames -contains 'Scaffold.Leaf') {
                        New-Item (Join-Path $Destination $_.FullName) -Force -ErrorAction Stop | Out-Null

                        if ($_.Contents) {
                            if ($Interactive.IsPresent) {
                                $PVars = $_.ParameterizedVars | Select-Object @{
                                    L = 'Var'
                                    E = { $_.Groups[1].ToString().Trim() }
                                } -Unique

                                for ($i = 0; $i -lt $PVars.Count; $i++) {
                                    $var = $PVars[$i].Var
                                    $stdin = Read-Host ("Scaffold Parameters [{0}] ({1}/{2})`n{3}" -f $_.Name, ($i + 1), $PVars.Count, $var)
                                    $_.Contents = $_.Contents -replace "\{\{\s*$var\s*\}\}", $stdin
                                }
                            }

                            $_.Contents.Trim() | Out-File (Join-Path $Destination $_.FullName) -Force -NoNewline
                        }
                    }
                    else {
                        New-Item (Join-Path $Destination $_.FullName) -ItemType Directory -Force
                    }
                }
            } | Out-Null

            Write-Progress -Id 1 -ParentId 0 -Completed
        }
    }
}

function ConvertTo-Scaffold {
    <#
    .SYNOPSIS
        Convert a scaffold yaml file or string to a custom object
    #>
    [CmdletBinding()]
    [OutputType('Scaffold.Document')]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Yaml,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.IO.FileInfo]$Path
    )

    process {
        $Document = if ($Path) {
            if ($Path.Attributes.HasFlag([System.IO.FileAttributes]::Directory)) {
                [pscustomobject]@{
                    name     = $null
                    about    = $null
                    scaffold = Read-Directory $Path
                }
            }
            else {
                ConvertFrom-Yaml (Get-Content $Path -Raw)
            }
        }
        else { ConvertFrom-Yaml $Yaml }

        $Read = Read-ScaffoldContainer $Document.Scaffold
        $Scaffold = @()
        $Scaffold += $Read.Scaffold.Folders | Sort-Object FullName
        $Scaffold += $Read.Scaffold.Files | Sort-Object FullName
        [pscustomobject][ordered]@{
            PSTypeName = 'Scaffold.Document'
            Name       = $Document.Name
            About      = $Document.About
            Scaffold   = $Scaffold
        }
    }
}