function IPv4Connection
{
    param($Event)

    $ProcID = $Event.Properties[0].value

    $DestIP = [System.Net.IPAddress]$Event.Properties[2].value

    # Ports are returned in BIG-IP system encoding
    # Converts the decimal port value to the equivalent 2-byte hexadecimal value.
    # Reverses the order of the two hexadecimal bytes.
    # Converts the resulting 2-byte hexadecimal value to its decimal equivalent.
    # https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm-concepts-11-5-0/10.html

    $DestPort = "{0:x}" -f [int]$Event.Properties[4].value | 
                    ForEach-Object { $_ -split '(..)' } |
                    Where-Object { $_ }

    [array]::Reverse($DestPort)

    $DestPort = [Convert]::ToInt32( -join( $DestPort ), 16 )

    $NewNetworkObj = New-Object -TypeName psobject
    $NewNetworkObj | Add-Member -NotePropertyName 'DestinationIP' -NotePropertyValue $DestIP.IPAddressToString
    $NewNetworkObj | Add-Member -NotePropertyName 'DestinationPort' -NotePropertyValue $DestPort
    $NewNetworkObj | Add-Member -NotePropertyName 'Count' -NotePropertyValue 1


    If ( $Events.ContainsKey( [int32]$ProcID ) ) {

        If ( ($Events[[int32]$ProcID].PSObject.Properties.Name -match 'NetConnections').Count -lt 1 ) {
            
            $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'NetConnections' -NotePropertyValue @()

        }

        # This will only add connection if an identical one (port and IP) has not already been added

        $found =  $Events[ [int32]$ProcID ].NetConnections | 
            Where-Object { $_.DestinationIP -eq $NewNetworkObj.DestinationIP -and $_.DestinationPort -eq $NewNetworkObj.DestinationPort } |
            ForEach-Object { $true }
        

        If ( -Not $found ) {

            $Events[ [int32]$ProcID ].NetConnections += $NewNetworkObj
        } else {
            # If connection does exist increment count by 1
            $Events[ [int32]$ProcID ].NetConnections | 
            Where-Object { $_.DestinationIP -eq $NewNetworkObj.DestinationIP -and $_.DestinationPort -eq $NewNetworkObj.DestinationPort } |
            ForEach-Object { $_.Count = $_.Count + 1 } 

        }
    }

    else {

        $NewProcessObject = New-Object -TypeName psobject
        $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
        $NewProcessObject | Add-Member -NotePropertyName 'NetConnections' -NotePropertyValue @()

        $NewProcessObject.NetConnections += $NewNetworkObj

        $Events.Add( [int32]$ProcID, $NewProcessObject )
    }
} # IPv4Connection


function KernelNetworkParser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventRecord]
        $Event

    )

    $script:KernProcEvents = @{
        12 = 'IPv4Connection'
    }

    If ( $script:KernProcEvents.ContainsKey($Event.Id) ) {
        &$script:KernProcEvents[$_.Id] $Event
    }

}