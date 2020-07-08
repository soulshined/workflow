. "$((Get-Item $PROFILE).Directory.FullName)/PowerShell_profile_fns.ps1"

New-Variable -Name config -Value @{
    home   = @{ mac = "~/DEV"; win = "D:/David Freer/OneDrive/Programming"; };
    devDir = @{ mac = "~/DEV"; win = "D:/David Freer/OneDrive/Programming"; };
    mvnDir = @{ mac = "/usr/local/maven/apache-maven-3.6.3"; win = $null; };
} -Visibility Private

if ($PWD.Path -eq (Resolve-Path "~").Path) {
    #this allows IDEs to still maintain control over initial dir for integrated terminals
    Set-Location (Get-CustomConfig($config.home))
}

if ($IsMacOs) {
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Escape -Function UndoAll

    [System.Environment]::SetEnvironmentVariable('KUBECONFIG', (Resolve-Path '~/.kube/nonprod-kubectl-config'))
    [System.Environment]::SetEnvironmentVariable('M2_HOME', (Get-CustomConfig($config.mvnDir)))
    [System.Environment]::SetEnvironmentVariable('M2', "$env:M2_HOME/bin")
    [System.Environment]::SetEnvironmentVariable('mvn', "$env:M2/mvn")

    $env:PATH += ":$env:M2"

    New-Alias       start   Start-Process
    New-CustomAlias kdev    'kubectl -n dev @args'
    New-CustomAlias kdevl   'kubectl -n dev logs -f @args'
    New-CustomAlias kqa     'kubectl -n qa @args'
    New-CustomAlias kqal    'kubectl -n qa logs -f @args'
    New-CustomAlias kstg    'kubectl -n stg @args'
    New-CustomAlias kstgl   'kubectl -n stg logs -f @args'
    New-CustomAlias mvni    'mvn clean install @args'
    New-CustomAlias mvnif   'mvn clean install -f @args'
    New-CustomAlias mvnip   'mvn clean install -pl :$($args[0]) -am' #install module and only the ones it needs
    New-CustomAlias mvnis   'mvn clean install -DskipTests @args'
    New-CustomAlias mvnic   'mvn clean install -rf :$($args[0])' #continue/resume from module
    New-CustomAlias mvnit   'mvn clean -T 4 install @args'
    New-CustomAlias mvnv    'mvn versions:set -DgenerateBackupPoms=false -DnewVersion='
}

New-Alias       clip    Set-Clipboard
New-CustomAlias restart "Start-NewPowershell -KillCurrent"
New-CustomAlias dev     "cd '$(Get-CustomConfig($config.devDir))'"