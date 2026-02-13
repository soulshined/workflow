if ($IsWindows) {
	winget install -e --id CoreyButler.NVMforWindows
} else {
	/bin/bash
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
	source ~/.profile
}

nvm --version
nvm install node
npm install -g $(cat $Env:WORKFLOW_DIR/dependencies/node/packages.txt)
