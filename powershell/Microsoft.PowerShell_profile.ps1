Set-PSReadLineKeyHandler -Chord 'RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Key Escape -Function UndoAll
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

function Edit-Config($Config, [switch]$List) {
	switch ($Config.ToLower()) {
		'git' {
			Invoke-Expression "$Env:EDITOR $Env:WORKFLOW_DIR/git/.gitconfig"
			return
		}
	}

    $FirstResultBangSet = $Config.EndsWith('!')

    $ConfigDirectories = gci ~/.config -Directory

    if ($List.IsPresent) {
		$ConfigDirectories
		return
    }

    $Candidate = $ConfigDirectories | ? Name -ieq ($Config -replace '!$', '')

    if ($Candidate.Count -eq 0) {
		Write-Error "No matches found"
		return
    }

    $Files = gci $Candidate -Include *.ps1,*.toml,*.conf,*.css,*.lua,*.json,*.jsonc,*.yaml,*.yml,config -Recurse | Sort-Object FullName

    if ($Files.Count -eq 0) {
		Write-Error "No matches found"
		return
    }

    if ($FirstResultBangSet -or $Files.Count -eq 1) {
		Invoke-Expression "$Env:EDITOR $($Files[0])"
		return
    }

    $Choices = $Files | % -Begin { $i = 0 } -Process {
		[System.Management.Automation.Host.ChoiceDescription]('&{0} - {1}' -f $i++, $_.FullName)
    }

    $SelectedOption = $Host.UI.PromptForChoice('', 'Multiple file types matched - select one to edit', $Choices, 0)

    Invoke-Expression ('{0} {1}' -f $Env:EDITOR, $Files[$SelectedOption])
}

New-Variable DEV -Value ~/Programming -Description 'Path to development specific directory' -Option AllScope, Constant, ReadOnly -Visibility Public -Force -ErrorAction Ignore -Scope Global
[System.Environment]::SetEnvironmentVariable('DEV', $DEV);

New-Variable DIR_SEP -Value ([IO.Path]::DirectorySeparatorChar) `
    -Description 'Freer.Runtime.Constants' `
    -Option AllScope, Constant, ReadOnly `
    -Visibility Public `
    -Force `
    -ErrorAction Ignore

New-Variable PATH_SEP -Value ([IO.Path]::PathSeparator) `
    -Description 'Freer.Runtime.Constants' `
    -Option AllScope, Constant, ReadOnly `
    -Visibility Public `
    -Force `
    -ErrorAction Ignore

$Env:PSModulePath += $PATH_SEP + "$Env:WORKFLOW_DIR/powershell/Modules"

Set-Alias vim -Value nvim
Set-Alias Set-Clipboard -Value wl-copy
Set-Alias ec -Value Edit-Config
