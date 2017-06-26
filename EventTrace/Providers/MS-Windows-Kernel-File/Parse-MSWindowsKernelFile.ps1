$OpenFiles = @{}

function FileOpen
{   
    param($Event)

    $FileID = $Event.Properties[0].value
    $FilePath = $Event.Properties[6].value

    if ( -Not $OpenFiles.ContainsKey( $FileID ) ){
        $OpenFiles.Add( $FileID, $FilePath )
    }

} # FileOpen

function FileWrite
{
    param($Event)

    $FileID = $Event.Properties[1].value

    # Confirm file object is known
    If ( $OpenFiles.ContainsKey( $FileID ) ) {
        
        $ProcID = $Event.ProcessId
        $BytesWrite = $Event.Properties[5].value
        $Action = "WRITE"

        $NewFileObj = New-Object -TypeName psobject

        $NewFileObj | Add-Member -NotePropertyName 'FilePath' -NotePropertyValue $OpenFiles[ $FileID ]
        $NewFileObj | Add-Member -NotePropertyName 'Action' -NotePropertyValue $Action
        $NewFileObj | Add-Member -NotePropertyName 'BytesWritten' -NotePropertyValue $BytesWrite

        If ( $Events.ContainsKey( [int32]$ProcID ) ) {

            If ( ($Events[[int32]$ProcID].PSObject.Properties.Name -match 'FileIO').Count -lt 1 ) {
                
                $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()

            }

            $Events[[int32]$ProcID].FileIO += $NewFileObj
        }
        else {
            $NewProcessObject = New-Object -TypeName psobject
            $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
            $NewProcessObject | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()

            $NewProcessObject.FileIO += $NewFileObj

            $Events.Add( [int32]$ProcID, $NewProcessObject )

        }
    }
    
    # If we can't map the open handle then there is no way to identify the file path
    else {}
    
} # FileWrite

function FileCreateDelete
{
    param($Event)

    $ProcID = $Event.ProcessId
    $FilePath = $Event.Properties[6].value

    If ( $Event.Id -eq 26 ) {
        $Action = "DELETE"
    }
    Elseif ($Event.Id -eq 30) {
        $Action = "CREATE"
    }


    $NewFileObj = New-Object -TypeName psobject

    $NewFileObj | Add-Member -NotePropertyName 'FilePath' -NotePropertyValue $FilePath
    $NewFileObj | Add-Member -NotePropertyName 'Action' -NotePropertyValue $Action

    If ( $Events.ContainsKey( [int32]$ProcID ) ) {

        If ( ($Events[[int32]$ProcID].PSObject.Properties.Name -match 'FileIO').Count -lt 1 ) {
            
            $Events[[int32]$ProcID] | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()

        }

        $Events[[int32]$ProcID].FileIO += $NewFileObj
    }
    else {
        $NewProcessObject = New-Object -TypeName psobject
        $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
        $NewProcessObject | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()

        $NewProcessObject.FileIO += $NewFileObj

        $Events.Add( [int32]$ProcID, $NewProcessObject )

    }

} # FileCreateDelete

function KernelFileParser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventRecord]
        $Event

    )

    $script:KernProcEvents = @{
        12 = 'FileOpen'
        16 = 'FileWrite'
        26 = 'FileCreateDelete'
        30 = 'FileCreateDelete'
    }

    If ( $script:KernProcEvents.ContainsKey($Event.Id) ) {
        &$script:KernProcEvents[$_.Id] $Event
    }

}