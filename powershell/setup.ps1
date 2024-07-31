$PEnv = [pscustomobject]@{
    PSTypeName      = 'Freer.Runtime.ProfileEnv'
    USER            = $Env:USER ?? $Env:USERNAME
    HOMES           = @{
        Dev        = [ProfileEnvItem]@{
            IsPath = $true
            Win    = "D:/David Freer/OneDrive/Programming"
            Linux  = "$HOME/Documents/Dev"
            Mac    = "$HOME/Documents/dev"
            Work   = "$HOME/DEV"
        }
        Mvn        = [ProfileEnvItem]@{
            IsPath = $true
            Mac    = "/usr/local/maven/apache-maven-3.6.3"
        }
        Kubeconfig = [ProfileEnvItem]@{
            IsPath = $true
            Work   = "~/.kube/nonprod-kubectl-config"
        }
    }
    ENV_VARS        = [ordered]@{
        KUBECONFIG = { $PEnv.HOMES.Kubeconfig.ToString() }
        M2_HOME    = { $PEnv.HOMES.Mvn.ToString() }
        M2         = [ProfileEnvItem]@{
            IsPath = $true
            All    = '"$Env:M2_HOME/bin"'
        }
        mvn        = [ProfileEnvItem]@{
            IsPath = $true
            All    = '"$Env:M2/mvn"'
        }
    }
    PATHS_TO_APPEND = { $PEnv.ENV_VARS.M2.ToString() }
    ALIASES         =
    @{
        Condition = { $PEnv.HOMES.Mvn.HasValue() }
        Value     = "New-CustomAlias 'mvn versions:set -DgenerateBackupPoms=false -DnewVersion='"
    },
    @{
        Condition = { $PEnv.HOMES.Mvn.HasValue() }
        Value     = "New-CustomAlias mvni 'mvn clean install @args'"
    },
    @{
        Condition = { $PEnv.HOMES.Mvn.HasValue() }
        Value     = "New-CustomAlias mvnip 'mvn clean install -pl :`$(`$args[0]) -am' #install module and only the ones it needs"
    },
    @{
        Condition = { $PEnv.HOMES.Mvn.HasValue() }
        Value     = "New-CustomAlias mvnis 'mvn clean install -DskipTests @args'"
    },
    @{
        Condition = { $PEnv.HOMES.Mvn.HasValue() }
        Value     = "New-CustomAlias mvnic 'mvn clean install -rf :`$(`$args[0])' #continue/resume from module"
    },
    @{
        Condition = { $PEnv.HOMES.Mvn.HasValue() }
        Value     = "New-CustomAlias mvnit 'mvn clean -T 4 install @args'"
    }
}

class ProfileEnvItem {

    [string]$All
    [string]$Win
    [string]$Mac
    [string]$Linux
    [string]$Work
    [bool]$IsPath = $false

    [string]ToString() {
        $local:val = switch ($true) {
            $global:IsMacOS { $this.All ?? $this.Mac }
            $global:IsLinux { $this.All ?? $this.Linux }
            $global:IsWindows { $this.All ?? $this.Win }
            $global:IsWork { $this.All ?? $this.Work }
            Default { $null }
        }

        if ($this.IsPath -and $null -ne $local:val) { return Resolve-Path $local:val } else { return $local:val }
    }

    [bool] HasValue() {
        return -not [string]::IsNullOrWhiteSpace($this.ToString())
    }

}

$ProfilePath = Join-Path $PSScriptRoot Microsoft.PowerShell_profile.ps1
$ProfileContents = Get-Content $ProfilePath -Raw
$EnvVarsContents = ''

$PEnv.ENV_VARS.GetEnumerator() | % {
    $Value = if ($_.Value -is [ProfileEnvItem]) {
        $_.Value.ToString()
    }
    elseif ($_.Value -is [scriptblock]) {
        $Result = $_.Value.InvokeWithContext(@{}, [psvariable]::new('PEnv', $PEnv))
        $Result.Count -gt 0 ? $Result[0] : $null
    }
    else { $_.Value }

    if (-not $Value) { return }

    $EnvVarsContents += "`n[System.Environment]::SetEnvironmentVariable('{0}', { 1 })" -f $_.Key, $Value
}

@{
    DEV          = $PEnv.Homes.Dev.ToString() | Resolve-Path -ErrorAction Stop
    PSModulePath = Join-Path $PSScriptRoot 'Modules' -Resolve
    'ENV VARS'   = "ENV VARS$EnvVarsContents"
}.GetEnumerator() | % {
    $Key = '\${0}' -f $_.Key
    $ProfileContents = $ProfileContents -ireplace "{{\s*$Key\s*}}", $_.Value
}

$ProfileContents += "`n"

$PathsToAppend = $PEnv.PATHS_TO_APPEND | % {
    $Value = if ($_ -is [scriptblock]) {
        $_.InvokeWithContext(@{}, [psvariable]::new('PEnv', $PEnv))
    }
    else {
        $_.ToString()
    }

    if (-not $Value) { return $null }
    else { $Value }
} | ? { $_ }

if ($PathsToAppend.Count -gt 0) {
    $ProfileContents += "`n`$Env:PATH += '{0}'" -f ($PathsToAppend -join ', ')
}

$PEnv.ALIASES | % {
    $Value = $_
    if ($Value -is [hashtable]) {
        if ($Value.ContainsKey('Condition') -and $Value.Condition -is [scriptblock]) {
            $Result = $Value.Condition.InvokeWithContext(@{}, [psvariable]::new('PEnv', $PEnv))
            if ($Result.Count -eq 1 && $Result[0] -ne $true) {
                return
            }
        }
        $Value = $Value.Value
    }

    if (-not $Value) { return }

    $ProfileContents += "`n$Value"
}

$ProfileContents.Trim() | Out-File $PROFILE -Force