# Hash table mapping of supported ETW providers to parser functions
$script:Providers = @{
    'Microsoft-Windows-Kernel-Process' = 'KernelProcessParser'
}

# Global Object
$global:Events = @{}

function NewKernelProcObj
{
    param($ProcPID, $StartTime, $EndTime, $ParentPid, $ProcessPath)

    $RetProcObj = New-Object -TypeName psobject
    $RetProcObj | Add-Member -Name 'PID' -Value $ProcID -MemberType NoteProperty
    $RetProcObj | Add-Member -Name 'StartTime' -Value $StartTime -MemberType NoteProperty
    $RetProcObj | Add-Member -Name 'EndTime' -Value $EndTime -MemberType NoteProperty
    $RetProcObj | Add-Member -Name 'ParentPID' -Value $ParentProcID -MemberType NoteProperty
    $RetProcObj | Add-Member -Name 'ProcessPath' -Value $ProcPath -MemberType NoteProperty
    $RetProcObj | Add-Member -Name 'LoadedImages' -Value @() -MemberType NoteProperty

    $RetProcObj

}

function KernelProcessParser
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventRecord]
        $Event
    )


    function ImageLoad
    {
        # Example image load message
        # Process 5636 had an image unloaded with name \Device\HarddiskVolume1\Windows\System32\AppContracts.dll.
        $MessageArray = $Event.Message -split(" ")
        # PID
        $ProcID = $MessageArray[1]
        # DLLPath
        $DLLPath = (-join($MessageArray[8..$MessageArray.length])).TrimEnd(".")

        # Add DLL to events if PID there
        If ( $global:Events.ContainsKey([int32]$ProcID) ) {
            # Add DLL to process object
            ($global:Events[[int32]$ProcID]).LoadedImages += $DLLPath
        } 
        else {
            $RetProcObj = NewKernelProcObj(
                $ProcId,
                $null,
                $null,
                $null,
                $null
            )
            $RetProcObj.LoadedImages += $DLLPath

            $global:Events.Add( [int32]$ProcID, $RetProcObj )
        }

        } # ImageLoad

    function ProcessStart
    {   
        # Example process event message
        # Process 5068 started at time ‎2017‎-‎05‎-‎31T22:07:26.486024400Z by parent 852 running in session 1 with name \Device\HarddiskVolume1\Windows\System32\dllhost.exe.
        
        $MessageArray = $Event.Message -split(" ")
        # PID
        $ProcID = $MessageArray[1]
        # Start time
        $StartTime = $MessageArray[5]
        # Partent PID
        $ParentProcID = $MessageArray[8]
        # Process Path
        $ProcPath = (-join($MessageArray[15..$MessageArray.length])).TrimEnd(".")

        # Create new process object
        $RetProcObj = NewKernelProcObj(
            $ProcID,
            $StartTime,
            $null,
            $ParentProcID,
            $ProcPath)
        
        $global:Events.Add( [int32]$ProcID, $RetProcObj )
        
    } # ProcessStart

    $script:KernProcEvents = @{
        1 = 'ProcessStart'
        6 = 'ImageLoad'
    }

    If ( $script:KernProcEvents.ContainsKey($Event.Id) ) {
        &$script:KernProcEvents[$_.Id]
    } else {}

}


Get-WinEvent -Path C:\Users\mhastings\Desktop\out.etl -Oldest | Where-Object {
    $script:Providers.ContainsKey($_.ProviderName) } | ForEach-Object {
        &$script:Providers[$_.ProviderName] -Event $_ }

$global:Events
