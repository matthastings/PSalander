
function CmdletRun
{
    param($Event)
    $ProcID = [int32]$Event.ProcessID
    $MessageArray = ($Event.Properties[2].Value) -split " "
    
    # CmdletRun can have many different events for this we just want to capture what cmdlets were run
    If ( $MessageArray[0] -eq "Command" -and $MessageArray[3].Trim() -eq "Started." ) {
          If ( $Events.ContainsKey( $ProcID ) ) {
            
            If ( ($Events[$ProcID].PSObject.Properties.Name -match 'Commands').Count -lt 1 ) {
                
                $Events[$ProcID] | Add-Member -NotePropertyName 'Commands' -NotePropertyValue @()
    
            }

            $Events[$ProcID].Commands += $MessageArray[1]
        }
    }
}

function ScriptBlock
{
    param($Event)
    $ProcID = [int32]$Event.ProcessID
    If ( $Events.ContainsKey( $ProcID ) ) {

        If ( ($Events[$ProcID].PSObject.Properties.Name -match 'ScriptBlocks').Count -lt 1 ) {
            
            $Events[$ProcID] | Add-Member -NotePropertyName 'ScriptBlocks' -NotePropertyValue @()

        }

        $Events[$ProcID].ScriptBlocks += $Event.Properties[2].Value
    }
}

function PowerShellParser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventRecord]
        $Event

    )

    $script:KernProcEvents = @{
        7937 = 'CmdletRun'
        4104 = 'ScriptBlock'
    }

    If ( $script:KernProcEvents.ContainsKey($Event.Id) ) {
        &$script:KernProcEvents[$_.Id] $Event
    }

}