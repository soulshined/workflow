@"
[include]
	path = $Env:WORKFLOW_DIR/git/.gitconfig

[core]
	excludesfile = $Env:WORKFLOW_DIR/git/.gitconfig

[init]
	templatedir = $Env:WORKFLOW_DIR/git/.git-templatedir
"@ | Out-File ~/.gitconfig

Get-ChildItem "$Env:WORKFLOW_DIR/git/custom commands" | % {
	if (-not $IsWindows) {
		chmod +x $_.FullName
	}
	else {
		 '!f() { bash "{0}" $@; };f' -f $_.BaseName.Substring(4) | Add-Content $Env:WORKFLOW_DIR/git/.gitconfig.win
	}
}

if (-not $IsWindows) {
	chmod +x $Env:WORKFLOW_DIR/git/.git-templatedir/hooks/pre-commit
}
