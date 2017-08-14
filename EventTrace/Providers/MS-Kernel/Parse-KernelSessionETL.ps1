function Get-KernelProcPath 
{
    param($HexString)
    $Start = 64
    $Length = 0
    $NullByte = $false
    $InString = $true
    $reg = '(("){0,1}\w:.*$)'
    Do
    {
        $HexString[$start..$HexString.length] |
            ForEach-Object {
                If ($NullByte -eq $true -and ([uint16]$_ -eq 0)) {
                    $InString = $false
                }
                elseif ([uint16]$_ -eq 0) {
                    $length = $length + 1
                    $NullByte = $true
                }
                else {
                    $length = $length + 1
                    $NullByte = $false
                }
            }
    } While ($InString)
    
    # Need to parse out command line from imagepath and commandline string
    -join($HexString[$Start..($Start + $Length)] | Where-Object { $_ }) |
        Where-Object { $_ -match $reg} | 
        ForEach-Object {$matches[1]}
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

    # Convert string to byte array
    $EventPayload = $EventPayload |
        ForEach-Object { $_ -split '(..)' } |
        Where-Object { $_ } |
        ForEach-Object { [char][convert]::ToUInt32($_,16) }

    $ProcID = [bitconverter]::ToInt32($EventPayload[8..11], 0)
    $CommandLine = Get-KernelProcPath -HexString $EventPayload
    
    If ( $ProcID -and $CommandLine ) {
        # Grab image name for comparison to events dictionary
        $ImageName = [IO.Path]::GetFileName( (Get-FullPathFromCommandLine -CommandLine $CommandLine) ) 
        $Events.Values |
            # Check if process id and process full path match entry in events output
            Where-Object { $_.ImageName -and $_.ProcessId -eq $ProcID -and ([IO.Path]::GetFileName($_.ImageName)).ToLower() -eq $ImageName.ToLower() } |
            # Confirm property does not already exist
            ForEach-Object {
                If ( ($_.PSObject.Properties.Name -match 'CommandLine').Count -lt 1 ) {
                    $_ |  Add-Member -NotePropertyName "CommandLine" -NotePropertyValue $CommandLine
                }
            }
    }
}

