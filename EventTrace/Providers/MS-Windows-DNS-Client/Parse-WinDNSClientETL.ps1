function DNSResponse
{
    param($Event)
    # $IPRegex = '([0-9]{1,3}\.){3}[0-9]{1,3}'

    # Only type 28 responses contain domain to IP mappings
    # If ( $Event.Properties[1].value -eq 28 -and $Event.Properties[4].value -match $IPRegex ) {

    $ProcID = $Event.ProcessID
    
    # $IPAddress = $matches[0]
    
    $NewDNSObject = New-Object -TypeName psobject
    $NewDNSObject | Add-Member -NotePropertyName 'DomainName' -NotePropertyValue $Event.Properties[0].value
    # $NewDNSObject | Add-Member -NotePropertyName 'IPv4Address' -NotePropertyValue $IPAddress


    If ( $Events.ContainsKey( [int32]$ProcID ) ) {

        If ( ($Events[[int32]$ProcID].PSObject.Properties.Name -match 'DomainLookups').Count -lt 1 ) {
            
            $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'DomainLookups' -NotePropertyValue @()

        }

        $Events[ [int32]$ProcID ].DomainLookups += $NewDNSObject

    }

    else {
        $NewProcessObject = New-Object -TypeName psobject
        $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
        $NewProcessObject | Add-Member -NotePropertyName 'DomainLookups' -NotePropertyValue @()

        $NewProcessObject.DomainLookups += $NewDNSObject

        $Events.Add( [int32]$ProcID, $NewProcessObject )
    }
}

# }


function DNSClientParser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventRecord]
        $Event

    )

    $script:KernProcEvents = @{
        # 3008 = 'DNSResponse'
        3000 = 'DNSResponse'
    }

    If ( $script:KernProcEvents.ContainsKey($Event.Id) ) {
        &$script:KernProcEvents[$_.Id] $Event
    }

}