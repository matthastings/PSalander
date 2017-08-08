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
        
        $ProcID = [int32]$Event.ProcessId
        $BytesWrite = $Event.Properties[5].value
        $Action = "WRITE"

        $NewFileObj = New-Object -TypeName psobject

        $NewFileObj | Add-Member -NotePropertyName 'FilePath' -NotePropertyValue $OpenFiles[ $FileID ]
        $NewFileObj | Add-Member -NotePropertyName 'Action' -NotePropertyValue $Action
        $NewFileObj | Add-Member -NotePropertyName 'BytesWritten' -NotePropertyValue $BytesWrite
        $NewFileObj | Add-Member -NotePropertyName 'ThreadID' -NotePropertyValue $Event.ThreadID

        If ( $Events.ContainsKey( $ProcID ) ) {

            If ( ($Events[$ProcID].PSObject.Properties.Name -match 'FileIO').Count -lt 1 ) {
                
                $Events[$ProcID] | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()

            }

            $Events[$ProcID].FileIO += $NewFileObj

            $Events[$ProcID].Threads | 
                Where-Object { $_.threadID -eq $Event.ThreadID } |
                ForEach-Object {
                    If ( ($_.PSObject.Properties.Name -match 'FileIO').Count -lt 1 ) {
                        $_ | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()
                    }
                    $_.FileIO += $NewFileObj
            }
        }
        else {
            $NewProcessObject = New-Object -TypeName psobject
            $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
            $NewProcessObject | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()

            $NewProcessObject.FileIO += $NewFileObj

            $Events.Add( $ProcID, $NewProcessObject )

        }
    }
    
} # FileWrite

function FileCreateDelete
{
    param($Event)

    $ProcID = [int32]$Event.ProcessId
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
    $NewFileObj | Add-Member -NotePropertyName 'ThreadID' -NotePropertyValue $Event.ThreadID


    If ( $Events.ContainsKey( $ProcID ) ) {

        If ( ($Events[$ProcID].PSObject.Properties.Name -match 'FileIO').Count -lt 1 ) {
            
            $Events[$ProcID] | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()

        }
        $Events[$ProcID].FileIO += $NewFileObj
        
        $Events[$ProcID].Threads | 
            Where-Object { $_.threadID -eq $Event.ThreadID } |
            ForEach-Object {
                If ( ($_.PSObject.Properties.Name -match 'FileIO').Count -lt 1 ) {
                    $_ | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()
                }
                $_.FileIO += $NewFileObj
            }
    }
    else {
        $NewProcessObject = New-Object -TypeName psobject
        $NewProcessObject | Add-Member -NotePropertyName 'ProcessID' -NotePropertyValue $ProcID
        $NewProcessObject | Add-Member -NotePropertyName 'FileIO' -NotePropertyValue @()

        $NewProcessObject.FileIO += $NewFileObj

        $Events.Add( $ProcID, $NewProcessObject )

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