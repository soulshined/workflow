if [ ! -S ~/.ssh/ssh_auth_sock ]; then
	eval `ssh-agent`
	ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
fi

export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock

export EDITOR=nvim
export POWERSHELL_TELEMETRY_OPTOUT=1
export WORKFLOW_DIR=~/Programming/personal/workflow

export PATH="$PATH:$HOME/.local/bin:$WORKFLOW_DIR/git/custom commands"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

ssh-add ~/.ssh/gh
