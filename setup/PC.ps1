using module Freer.Utility

[CmdletBinding()]
Param()

DynamicParam {
	$RuntimeParams = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

	$BaseAttrSet = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
	$BaseAttrSet.Add([System.Management.Automation.ParameterAttribute]@{
		Mandatory         = $true
	})

	$PCs = Get-ChildItem $PSScriptRoot -Filter PC.*.ps1 | % { ($_.Name -split '\.' | Select-Object -Skip 1 -SkipLast 1) -join '_' }
	foreach ($pc in $PCs) {
		$RuntimeParams.Add($pc, [System.Management.Automation.RuntimeDefinedParameter]::new($pc, [switch], $BaseAttrSet))
	}

	$RuntimeParams
}

Begin {
	$ErrorActionPreference = 'Stop'
}

Process {
	if (-not $Env:WORKFLOW_DIR) {
		Write-Error '$Env:WORKFLOW_DIR not set'
		exit 1
	}

	function Prompt-YesNo($title, $message) {
        Read-Choice '&No', '&Yes' -Title $title -Message $message -Default 0
	}

	function Prompt-ManualConfirmNotice($title, $message) {
		Prompt-YesNo -Title "$($PSStyle.Foreground.Red)Manual Update Required: $title$($PSStyle.Reset)" -Message "$($PSStyle.Foreground.Green)$message$($PSStyle.Reset)"
	}

	$PC = $PSBoundParameters.Keys[0] -ireplace '_', '.'
	. "$PSScriptRoot/PC.$PC.ps1"

	'git', 'nvm' | % {
		. "$PSScriptRoot/$_.ps1"
	}

}
