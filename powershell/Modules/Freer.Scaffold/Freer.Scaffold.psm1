$ENV:SCAFFOLD_HOME = "$HOME/.folder-templates"
New-Item $ENV:SCAFFOLD_HOME -ItemType Directory -Force -ErrorAction Ignore

function Save-AsScaffold {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, HelpMessage = "Directory of folder you wish to duplicate for scaffold template", Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Directory = $PWD,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    process {
        Remove-Scaffold $Name
        Copy-Item $Directory -Destination (Join-Path $ENV:SCAFFOLD_HOME $Name.Trim().ToLower()) -Recurse -Force
    }
}

function Remove-Scaffold {
    [CmdletBinding()]
    param(
        [ArgumentCompleter({ (Get-Scaffolds).Name })]
        [Parameter(ValueFromPipeline = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    process {
        Remove-Item (Join-Path $ENV:SCAFFOLD_HOME $Name.Trim().ToLower()) -Recurse -Force -ErrorAction Ignore
    }
}

function Use-Scaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Name of a registered folder template you wish to mount", Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({ (Get-Scaffolds).Name })]
        [string[]]$Name,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Destination = $PWD
    )

    process {
        $Name | % {
            Copy-Item (Join-Path $ENV:SCAFFOLD_HOME $Name.Trim().ToLower()) -Destination $Destination -Recurse -Force -ErrorAction Stop
        }
    }
}

function Get-Scaffolds {
    Get-ChildItem $ENV:SCAFFOLD_HOME -Directory -Force -ErrorAction Ignore | % {
        @{
            Name  = $_.BaseName
            Value = $_
        }
    }
}