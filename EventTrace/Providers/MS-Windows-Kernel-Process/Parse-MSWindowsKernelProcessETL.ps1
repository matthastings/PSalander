function ImageLoad
{
    param($Event)

    $ProcID = $Event.Properties[2].value

    $NewLoadImgObj = New-Object -TypeName psobject
    $NewLoadImgObj | Add-Member -NotePropertyName 'ImageBase' -NotePropertyValue $Event.Properties[0].value
    $NewLoadImgObj | Add-Member -NotePropertyName 'ImageSize' -NotePropertyValue $Event.Properties[1].value
    $NewLoadImgObj | Add-Member -NotePropertyName 'ImageName' -NotePropertyValue $Event.Properties[6].value


    If ( $Events.ContainsKey( [int32]$ProcID ) ) {

        If ( ($Events[[int32]$ProcID].PSObject.Properties.Name -match 'LoadedImages').Count -lt 1 ) {
            
            $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'LoadedImages' -NotePropertyValue @()

        }

        $Events[[int32]$ProcID].LoadedImages += $NewLoadImgObj
    }
    else {

        $NewProcessObject = New-Object -TypeName psobject
        $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
        $NewProcessObject | Add-Member -NotePropertyName 'LoadedImages' -NotePropertyValue @()

        $NewProcessObject.LoadedImages += $NewLoadImgObj

        $Events.Add( [int32]$ProcID, $NewProcessObject )
    }
} # ImageLoad


function ProcessStart
{   
    param($Event)
    $ParentPID = $Event.Properties[2].value
    $ProcID = $Event.Properties[0].value

    If ( $Events.ContainsKey( [int32]$ProcID ) ) {
        $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'CreateTime' -NotePropertyValue $Event.Properties[1].value
        $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'ParentPID' -NotePropertyValue $ParentPID
        $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'SessionID' -NotePropertyValue $Event.Properties[3].value
        $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'ImageName' -NotePropertyValue $Event.Properties[5].value

    }

    else {
        $NewProcessObject = New-Object -TypeName psobject
        $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
        $NewProcessObject | Add-Member -NotePropertyName 'CreateTime' -NotePropertyValue $Event.Properties[1].value
        $NewProcessObject | Add-Member -NotePropertyName 'ParentPID' -NotePropertyValue $ParentPID
        $NewProcessObject | Add-Member -NotePropertyName 'SessionID' -NotePropertyValue $Event.Properties[3].value
        $NewProcessObject | Add-Member -NotePropertyName 'ImageName' -NotePropertyValue $Event.Properties[5].value

        $Events.Add( [int32]$Event.Properties[0].value, $NewProcessObject )
    }

    # Check if parent process is known and add to list
    If ( $Events.ContainsKey( [int32]$ParentPID ) ) {

        # Check if property has been added and if not then add
         If ( ($Events[ [int32]$ParentPID ].PSObject.Properties.Name -match 'ChildProcesses').Count -lt 1 ) {

            $Events[ [int32]$ParentPID ] | Add-Member -NotePropertyName 'ChildProcesses' -NotePropertyValue @()

        }

        $Events[ [int32]$ParentPID ].ChildProcesses += $NewProcessObject
    }
    
} # ProcessStart

function ProcessStop
{

    param($Event)
    $ProcID = $Event.Properties[0].value

    

    If ( $Events.ContainsKey( [int32]$ProcId ) ) {

        $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'EndTime' -NotePropertyValue $Event.Properties[2].value
        $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'ReadOperationCount' -NotePropertyValue $Event.Properties[9].value
        $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'WriteOperationCount' -NotePropertyValue $Event.Properties[10].value
        $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'ReadTransferKiloBytes' -NotePropertyValue $Event.Properties[11].value
        $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'WriteTransferKiloBytes' -NotePropertyValue $Event.Properties[12].value

        # To account for PID reuse we have to rename process keys from PID when they are complete
        $UniqueKey = Get-Random
        # Add new entry with random number as key
        $Events.Add( [int32]$UniqueKey, $Events[[int32]$ProcID] )
        # Delete key/value with PID
        $Events.Remove( [int32]$ProcID )

    } 
    else {

        $NewProcessObject = New-Object -TypeName psobject
        $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
        $NewProcessObject | Add-Member -NotePropertyName 'EndTime' -NotePropertyValue $Event.Properties[2].value
        $NewProcessObject | Add-Member -NotePropertyName 'ReadOperationCount' -NotePropertyValue $Event.Properties[9].value
        $NewProcessObject | Add-Member -NotePropertyName 'WriteOperationCount' -NotePropertyValue $Event.Properties[10].value
        $NewProcessObject | Add-Member -NotePropertyName 'ReadTransferKiloBytes' -NotePropertyValue $Event.Properties[11].value
        $NewProcessObject | Add-Member -NotePropertyName 'WriteTransferKiloBytes' -NotePropertyValue $Event.Properties[12].value

        $Events.Add( [int32]$ProcID, $NewProcessObject )
    }
}
function KernelProcessParser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventRecord]
        $Event

    )

    $script:KernProcEvents = @{
        1 = 'ProcessStart'
        2 = 'ProcessStop'
        6 = 'ImageLoad'
    }

    If ( $script:KernProcEvents.ContainsKey($Event.Id) ) {
        &$script:KernProcEvents[$_.Id] $Event
    }

}
