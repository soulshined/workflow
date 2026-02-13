param([switch]$Help)

$ErrorActionPreference = 'Stop'

if ($Help.IsPresent) {
	Write-Host @'
Pre-hook that automatically resets files that contains a @NOCHECKIN annotation based on the following pattern: `(#|//|/*)\s+@NOCHECKIN`

- If the file only contains one staged hunk (as in only 1 change near the annotation) the file will simply git reset and the commit will continue
- If the file contains more than 1 change in addition to the annotation, the commit will cancel and suggest to stage changes interactively
'@
	exit 0
}

$StagedFiles = git diff --name-only --cached --diff-filter=d
$StagedFiles | Get-Item -Force | % {
	$Hunks = ((git diff --cached --unified=0 $_) -join [System.Environment]::NewLine) -split "`n@@" | Select-Object -Skip 1

	$HunksWithAnnotation = $Hunks | ? {
		$_ | Select-String -Pattern "(#|//|/*)\s+@NOCHECKIN"
	}

	if ($HunksWithAnnotation.Count -eq 0) { return }

	git reset $_

	if ($Hunks.Count -eq 1) {
		Write-Warning "$_ contains @NOCHECKIN annotation - unstaging"
	}
	else {
		Write-HOST "WARNING: $_ contains @NOCHECKIN annotation with additional patches; using interactive staging" -ForegroundColor DarkYellow
		bash -c "git add --patch $_ < /dev/tty"
	}
}
