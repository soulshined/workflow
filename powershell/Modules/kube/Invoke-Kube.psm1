function Invoke-Kube {
    [CmdletBinding()]
    Param (  
        [Parameter(HelpMessage = "Help: Namespace target [Default dev]", Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Namespace = 'dev',
  
        [Alias("pf")]
        [switch]$PortForward,
      
        [Parameter(HelpMessage = "Helper: Enter port to forward the process to. Defaults to '8090:8090'. Must include empty string to use default")]
        [ValidateNotNullOrEmpty()]
        [string]$Port = '8090:8090',

        [Parameter(ValueFromRemainingArguments, Position = 0)]
        [Object[]]$Arguments
    )
    
    begin {
        $query = $Arguments.split(" ")
    }
    
    process {
        #a better way to search for pods by name
        #check if first 3 arguments align with searching for pods by name
        if ($query[0] -eq "get" -and $query[1] -eq "pods" -and $query[2] -and !($query[2].StartsWith("-"))) {
            $pods = @()
  
            #initially get all pods
            $result = kubectl get pods ($query | Select-Object -Skip 3) --namespace $Namespace 
  
            if ($result.Count -eq 0) { return $result }
            #iterate through all the pods and find similar matching names
            #$result[0] is header
            for ($i = 1; $i -lt $result.Count; $i++) {
                #kubectl returns a padded string not an object
                $pod = $result[$i] -split " " | Where-Object { $_ }

                if ($pod[0] -like "*$($query[2])*") {
                    $pods += [PSCustomObject]@{
                        Name     = $pod[0]
                        Ready    = $pod[1]
                        Status   = $pod[2]
                        Restarts = $pod[3]
                        Age      = $pod[4]
                    }
                }
            }  
        
            if ($pods.Count -gt 0) {
                return $pods
            }
        
            Write-Host "Error no pods found that matched '*$query[2]*'"
        }
        elseif ($PortForward) {
            if (![string]::IsNullOrWhiteSpace($Port)) {
                if ($Port -notmatch "^\d{4}:\d{4}$") {
                    Throw "Port should match the following pattern: ####:#### (default is '8090:8090')"
                }
            }
            else {
                $Port = '8090:8090'
            }

            kubectl --namespace $Namespace port-forward $query $port
        }
        else {
            #getting exact pod or something

            Write-Host
            Invoke-Expression "kubectl --namespace $Namespace $query"
            Write-Host
        }
    }
  
}
  
Export-ModuleMember -Function Invoke-Kube