function Win10DNSResponse
{
    param($Event)
    $IPRegex = '([0-9]{1,3}\.){3}[0-9]{1,3}'

    # Only type 28 responses contain domain to IP mappings
    If ( $Event.Properties[1].value -eq 28 -and $Event.Properties[4].value -match $IPRegex ) {

        $ProcID = [int32]$Event.ProcessID
        
        $IPAddress = $matches[0]
        
        $NewDNSObject = New-Object -TypeName psobject
        $NewDNSObject | Add-Member -NotePropertyName 'DomainName' -NotePropertyValue $Event.Properties[0].value
        $NewDNSObject | Add-Member -NotePropertyName 'IPv4Address' -NotePropertyValue $IPAddress
        $NewDNSObject | Add-Member -NotePropertyName 'ThreadID' -NotePropertyValue $Event.ThreadID

        If ( $Events.ContainsKey( $ProcID ) ) {

            If ( ($Events[$ProcID].PSObject.Properties.Name -match 'DomainLookups').Count -lt 1 ) {
                
                $Events[$ProcID] | Add-Member -NotePropertyName 'DomainLookups' -NotePropertyValue @()

            }

            $Events[ $ProcID ].DomainLookups += $NewDNSObject

            $Events[$ProcID].Threads | 
                Where-Object { $_.threadID -eq $Event.ThreadID } |
                ForEach-Object {
                    If ( ($_.PSObject.Properties.Name -match 'DomainLookups').Count -lt 1 ) {
                        $_ | Add-Member -NotePropertyName 'DomainLookups' -NotePropertyValue @()
                    }
                    $_.DomainLookups += $NewDNSObject
            }

        }

        else {
            $NewProcessObject = New-Object -TypeName psobject
            $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
            $NewProcessObject | Add-Member -NotePropertyName 'DomainLookups' -NotePropertyValue @()

            $NewProcessObject.DomainLookups += $NewDNSObject

            $Events.Add( $ProcID, $NewProcessObject )
        }
    }

}

function Win2012DNSResponse
{
    param($Event)


    $ProcID = [int32]$Event.ProcessID
    
    $NewDNSObject = New-Object -TypeName psobject
    $NewDNSObject | Add-Member -NotePropertyName 'DomainName' -NotePropertyValue $Event.Properties[0].value

    If ( $Events.ContainsKey( [int32]$ProcID ) ) {

        If ( ($Events[$ProcID].PSObject.Properties.Name -match 'DomainLookups').Count -lt 1 ) {
            
            $Events[$ProcID] | Add-Member -NotePropertyName 'DomainLookups' -NotePropertyValue @()

        }

        $Events[ $ProcID ].DomainLookups += $NewDNSObject

        $Events[$ProcID].Threads | 
            Where-Object { $_.threadID -eq $Event.ThreadID } |
            ForEach-Object {
                If ( ($_.PSObject.Properties.Name -match 'DomainLookups').Count -lt 1 ) {
                    $_ | Add-Member -NotePropertyName 'DomainLookups' -NotePropertyValue @()
                }
                $_.FileIO += $NewDNSObject
            }

    }

    else {
        $NewProcessObject = New-Object -TypeName psobject
        $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
        $NewProcessObject | Add-Member -NotePropertyName 'DomainLookups' -NotePropertyValue @()

        $NewProcessObject.DomainLookups += $NewDNSObject

        $Events.Add( $ProcID, $NewProcessObject )
    }

}


function DNSClientParser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventRecord]
        $Event

    )

    $script:KernProcEvents = @{
        3008 = 'Win10DNSResponse'
        3000 = 'Win2012DNSResponse'
    }

    If ( $script:KernProcEvents.ContainsKey($Event.Id) ) {
        &$script:KernProcEvents[$_.Id] $Event
    }

}