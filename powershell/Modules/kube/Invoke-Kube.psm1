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
        #a better way to search for pods and such by name
        #check if first 3 arguments align with searching for something by name
        if ($query[0] -eq "get" -and $query[2] -and !($query[2].StartsWith("-"))) {
            $results = @()
  
            #initially get all results
            $result = kubectl get $query[1] ($query | Select-Object -Skip 3) --namespace $Namespace 
  
            if ($result.Count -eq 0) { return $result }
            #iterate through all the results and find similar matching names
            #$result[0] is header
            $headers = ($result[0] -split " " | Where-Object { $_ })
            for ($i = 1; $i -lt $result.Count; $i++) {
                #kubectl returns a padded string not an object
                $pod = $result[$i] -split " " | Where-Object { $_ }

                if ($pod[0] -like "*$($query[2])*") {
                    $obj = New-Object -TypeName psobject
                    for ($j = 0; $j -lt $pod.Count; $j++) {
                        $obj | Add-Member -Name $headers[$j] -Value $pod[$j] -MemberType NoteProperty
                    }
                    $results += $obj
                }
            }  
        
            if ($results.Count -gt 0) {
                return $results
            }
        
            Write-Host "Error nothing found that matched '*$($query[2])*'"
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
            Invoke-Expression "kubectl --namespace $Namespace $flags $query"
            Write-Host
        }
    }
  
}
  
Export-ModuleMember -Function Invoke-Kube