export M2_HOME=/usr/local/maven/apache-maven-3.6.3
export M2=$M2_HOME/bin
export mvn=$M2

export PATH=$PATH:$M2

#Aliases
alias dev='cd ~/DEV/'
alias ..='cd ..'
alias ..2='cd ../../'
alias ..3='cd ../../../'
alias cls=clear

# KUBE CONFIG (MacOS)
export KUBECONFIG=~/.kube/nonprod-kubectl-config
alias kdev="kubectl -n dev $*"
alias kdevl="kubectl -n dev logs -f $*"
alias kqa="kubectl -n qa $*"
alias kqal="kubectl -n qa logs -f $*"
alias kstg="kubectl -n stg $*"
alias kstgl="kubectl -n stg logs -f $*"

#Change startup folder
if [[ $PWD == $HOME ]]; then
    cd DEV
fi

#Functions