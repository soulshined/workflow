Set-PSReadLineKeyHandler -Chord 'RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Key Escape -Function UndoAll
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

New-Variable DEV -Value ~/DEV -Description 'Path to development specific directory' -Option AllScope, Constant, ReadOnly -Visibility Public -Force -ErrorAction Ignore -Scope Global
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

$Env:PSModulePath += $PATH_SEP + '~/DEV/personal/workflow/powershell/Modules'

$DebugPreference = 'Continue'

if ($PWD.Path -eq (Resolve-Path '~').Path) {
	Set-Location '~DEV'
}

#region FUNCTIONS
function UseJava17() {
	[System.Environment]::SetEnvironmentVarible('JAVA_HOME', '/opt/homebrew/Cellar/openjdk@17/17.0.15/libexec/openjdk.jdk/Contents/Home');
}
function New-CustomAlias([string]$Name, $Args) {
	if ($Args.StartsWith('!')) {
		$Args = $Args.Substring(1);
		$Args = '{0}{1}{2}' -f $Args.Substring(0, $Args.IndexOf(' ')),
			$(if (!$IsMacOs) { '.exe' }),
			$Args.Substring($Args.IndexOf(' '))
	}

	New-Item "Function:\global:$Name" -Value (Invoke-Command -ScriptBlock { $args } -ArgumentList $Args) | Out-Null
}
#endregion FUNCTIONS

#region ENV VARS
if (-not (Test-Path 'env:JAVA_HOME') {
	[System.Environment]::SetEnvironmentVariable('JAVA_HOME', '/Users/dwf9649/Library/Java/JavaVirtualMachines/zulu-8.jdk/Contents/Home');
}

[System.Environment]::SetEnvironmentVariable('KUBECONFIG', (Resolve-Path '~/.kube/nonprod-kubectl-config'))
[System.Environment]::SetEnvironmentVariable('M2_HOME', '/usr/local/maven/apache-maven-3.9.4')
[System.Environment]::SetEnvironmentVariable('M2', "$Env:M2_HOME/bin")
[System.Environment]::SetEnvironmentVariable('mvn', "$Env:M2/mvn")

[System.Environment]::SetEnvironmentVariable('VAULT_HOST', 'vault.dev.sfg.corp.local')
[System.Environment]::SetEnvironmentVariable('VAULT_PORT', '8200')
[System.Environment]::SetEnvironmentVariable('VAULT_ADDR', "https://${Env:VAULT_HOST}:${Env:VAULT_PORT}")
[System.Environment]::SetEnvironmentVariable('VAULT_SKIP_VERIFY', 'true')

[System.Environment]::SetEnvironmentVariable('brew', '/opt/homebrew/bin/brew')
[System.Environment]::SetEnvironmentVariable('nvm', '~/.nvm')

$Env:PATH += ":/usr/local/bin:$Env:M2"
#endregion ENV VARS

Set-Alias vim -Value nvim

'dev', 'qa', 'stg', 'prd' | % {
	New-CustomAlias "k$_" "kubectl -n $_ @args"
	New-CustomAlias "k{$_}l" ('kubectl logs -l app=$args --since 10m --prefix --follow --namespace {0}' -f $_)
	New-CustomAlias "k{$_}d" "watch ""kubectl get pods --namespace=$_ --selector app.kubernetes.io/part-of=core"""
}

New-CustomAlias mvni	'mvn clean install'
New-CustomAlias mvnit	'mvn clean install -T 4 @args'
New-CustomAlias mvnis	'mvn clean install -DskipTests @args'
New-CustomAlias mvnic	'mvn clean install -rf :$($args[0])' #continue/resume from module
New-CustomAlias mvnics	'mvn clean install -DskipTests -rf :$($args[0])' #like ^ + skip tests
New-CustomAlias mvnif	'mvn clean install -f @args'
New-CustomAlias mvnip	'mvn clean install -pl :$($args[0]) -am' #install module and only the ones it needs
New-CustomAlias mvnips	'mvn clean install -DskipTests -pl :$($args[0]) -am' #like ^ + skip tests
New-CustomAlias mvnv	'mvn versions:set -DgenerateBackupPoms=false -DnewVersion='
New-CustomAlias mvnds	'mvn dependency:tree "-Dincludes=$($args[0])"' # dependency search
New-CustomAlias mvnadoc	'mvn com.sfg.ent.core.plugins:asciidoc-backend-plugin:generate'

#test an explicit class or class method or pattern
#examples:
#mvnte *ModelTest
#mvnte MyTestClass
#mvnte MyTestClass#MyTestMethod
#https://maven.apache.org/surefire/maven-surefire-plugin/examples/single-test.html
New-CustomAlias mvnte 'mvn clean test "-Dtest=$($args[0])"'

New-CustomAlias ij idea
New-CustomAlias kube Invoke-Kube
