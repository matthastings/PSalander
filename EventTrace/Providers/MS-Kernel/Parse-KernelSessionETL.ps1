function Get-KernelProcPath 
{
    
    param($HexString)
    # Struct immediately preceeding image name and path is a variable length array
    # Count identifies the numer of items in array
    $Count = [convert]::ToUInt32($HexString[53], 16)
    # Fixed length per item
    $Length = 4
    # Start of image name and command line message
    $Start = ($Count * $Length) + 60
    $Length = 0
    $NullByte = $false
    $InString = $true

    If (-not ($Start -gt $HexString.length) ){ 
        Do
        {
            $HexString[$start..$HexString.length] |
                ForEach-Object {
                    $char = [char][convert]::ToUInt32($_, 16)
                    If ($NullByte -eq $true -and ($char -eq 0)) {
                        $InString = $false
                    }
                    elseif ($char -eq 0) {
                        $length = $length + 1
                        $NullByte = $true
                    }
                    else {
                        $length = $length + 1
                        $NullByte = $false
                    }
                }
        } While ($InString)
    }
    $CommandBytes = -join($HexString[$Start..($Start + $Length)] | 
        ForEach-Object { [char][convert]::ToUInt32($_, 16)  } |
        Where-Object { $_ } )

    # Remove image name
    $FullCommand = ($CommandBytes -split '\.exe')[1..7]
    # Bring everything back together
    $FullCommand -join '.exe'
}

function Get-FullPathFromCommandLine
{
    param($CommandLine)

    If ($CommandLine[0] -eq '"' ) {

        ( $CommandLine -split '"' )[1]
    }
    else {
        ( $CommandLine -split ' ' )[0]
    }
}

function KernelSessionParser
{
    param($EventPayload)

    $t = $EventPayload
    # Convert string to byte array
    $EventPayload = $EventPayload |
        ForEach-Object { $_ -split '(..)' } |
        Where-Object { $_ }
        # ForEach-Object { [char][convert]::ToUInt32($_, 16) }
    try {
        $ProcID = [convert]::ToUInt32(-join($EventPayload[11..8]), 16)
    } catch {$ProcID = $null}        
    try { 
        $CommandLine = Get-KernelProcPath -HexString $EventPayload
    } catch {$CommandLine = $null}


    If ( $ProcID -and $CommandLine ) {
        # Grab image name for comparison to events dictionary
       try {
            $ImageName = [IO.Path]::GetFileNameWithoutExtension( (Get-FullPathFromCommandLine -CommandLine $CommandLine) ) 
       } catch { $ImageName = $null }

        $Events.Values |
            # Check if process id and process full path match entry in events output
            Where-Object { $_.ImageName -and $_.ProcessId -eq $ProcID -and [IO.Path]::GetFileNameWithoutExtension($_.ImageName).ToLower() -eq $ImageName.ToLower() } |
            # Confirm property does not already exist
            ForEach-Object {
                If ( ($_.PSObject.Properties.Name -match 'CommandLine').Count -lt 1 ) {
                    $_ |  Add-Member -NotePropertyName "CommandLine" -NotePropertyValue $CommandLine
                }
            }
    }
}

