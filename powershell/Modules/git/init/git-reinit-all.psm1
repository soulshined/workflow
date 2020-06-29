#requires -version 5
<#
.SYNOPSIS
  Simple helper for workflow updates

.DESCRIPTION
  Simple helper for workflow updates

  It's assumed the project querying is relative to the cwd, or can use full path

  -- 
  git-templates : runs 'git init' on each repo in the directory (recursively) to
    re-initialize the repository and global template (if there is one). This is
    usually a measure to add new or remove old hooks in 1 action.

.NOTES
  Version:        1.0
  Author:         Freer
  Creation Date:  14 May 2020
  Purpose/Change: Initial script development

.EXAMPLE
  update git-templates
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Set Error Action
$ErrorActionPreference = "Stop"

#---------------------------------------------------------[Initialisations]--------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

function Update-GitInit {
    Param(
        [Parameter(HelpMessage = "Help: directory or folder name of project", Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Directory = $PWD,

        [Parameter(Position = 1)]
        [ValidateSet("git-templates", "templates")]
        [String]$Action = "git-templates"
    )
  
    $path = Resolve-Path -Path $Directory
    Write-Host "Updating $path..."

    if ($Action -eq "git-templates" -or $Action -eq "templates") {

        $confirm = Get-Choice @("&yes", "&no") -Message "This will remove ALL hooks from this directory [recursively]. Is this ok?`n"

        if ($confirm -eq 0) {

            Get-ChildItem -Force -Directory $path -Filter .git -Recurse | ForEach-Object { 
                if (Test-Path -Path "$($_.FullName)\hooks" -PathType Container) {
                    Remove-Item "$($_.FullName)\hooks" -Force -Recurse
                }
                git init $(Split-Path -Path $_.FullName)
            }

        }

        Write-Host "`nDone!" -ForegroundColor Green
    }

}

Export-ModuleMember -Function Update-GitInit