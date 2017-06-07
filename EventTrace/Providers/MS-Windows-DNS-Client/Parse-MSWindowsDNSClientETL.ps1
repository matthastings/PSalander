# Define events as objects
function Convert-DNSEventProperties {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord]
        $Event
    )

    switch ( $Event.Id ) {
        1002 { 
            $Event | Foreach-Object {
                $Obj = New-Object psobject
                $Obj | Add-Member -NotePropertyName 'TimeCreated' -NotePropertyValue $_.TimeCreated
                $Obj | Add-Member -NotePropertyName 'Id' -NotePropertyValue $_.Id
                $Obj | Add-Member -NotePropertyName 'Message' -NotePropertyValue $_.Message
                $Obj | Add-Member -NotePropertyName 'Interface' -NotePropertyValue $_.Properties[0].value
                $Obj | Add-Member -NotePropertyName 'DNSServer' -NotePropertyValue $_.Properties[2].value
                $Obj
                break
            }
        }

        1026 {}
        3001 {}
        3002 {}
        3003 {}
        3004 {}
        3005 {}

        3006 {
            $Event | Foreach-Object {
                $Obj = New-Object psobject
                $Obj | Add-Member -NotePropertyName 'TimeCreated' -NotePropertyValue $_.TimeCreated
                $Obj | Add-Member -NotePropertyName 'Id' -NotePropertyValue $_.Id
                $Obj | Add-Member -NotePropertyName 'Message' -NotePropertyValue $_.Message                
                $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_.Properties[0].value
                $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_.Properties[1].value
                $Obj | Add-Member -NotePropertyName 'Options' -NotePropertyValue $_.Properties[2].value
                $Obj | Add-Member -NotePropertyName 'ServerList' -NotePropertyValue $_.Properties[3].value
                $Obj | Add-Member -NotePropertyName 'isNetworkQuery' -NotePropertyValue $_.Properties[4].value
                $Obj | Add-Member -NotePropertyName 'NetworkIndex' -NotePropertyValue $_.Properties[5].value
                $Obj | Add-Member -NotePropertyName 'InterfaceIndex' -NotePropertyValue $_.Properties[6].value
                $Obj | Add-Member -NotePropertyName 'Asynchronous' -NotePropertyValue $_.Properties[7].value
                $Obj
                break
            }
        }

        3007 {}
        3008 {}
        3009 {}
        3010 {}
        3011 {}
        3012 {}
        3013 {}
        3014 {}
        3015 {}
        3016 {}
        3018 {}
        3019 {}
        3020 {}
    }
    
}
# Parse event log for events of interest