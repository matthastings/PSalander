# Setup initial assembly import
$path = $PSScriptRoot + "\lib\Microsoft.Diagnostics.Tracing.TraceEvent.dll"
try {
    Import-Module $path
}
catch {
    throw "Could not find TraceEvent DLL at path: $path"
}
# Verify assembly loaded
if (-Not ([appdomain]::currentdomain.getassemblies()).location -contains $path) {
    throw "Failed to load TraceEvent DLL"
}
Get-ChildItem $PSScriptRoot -Directory | 
    Where-Object { $_.Name -ne 'Tests' } | 
    Get-ChildItem -Recurse | 
    Where-Object { $_.Name -match ".*\.ps1$" } | 
    ForEach-Object { . $_.FullName }

# Start Private Functions
Function Test-IsSession
{
    Param($SessionName)

    ( Get-ETWSessionNames ).Contains( $SessionName )

} # Test-IsSession

Function Test-IsProvider
{
    Param($ProviderName)

    ( ( Get-ETWProvider ).Name ).Contains( $ProviderName )

} # Test-IsProvider

function Write-Log
{
	param (
		[Parameter(Mandatory)]
		[string]$Message,
		
		[Parameter()]
		[ValidateSet('INFO','WARN', 'VERBOSE', 'DEBUG')]
		[string]$Severity = 'INFO'
	)
	
        $DateTime = ( Get-Date -UFormat "%D %T" )
        
        if ($Severity -eq 'INFO') { Write-Host ('{0} {1}: {2}' -f $DateTime, $Severity, $Message) }

        if ($Severity -eq 'WARN') { Write-Warning ('{0} {1}: {2}' -f $DateTime, $Severity, $Message) }

        if ($Severity -eq 'VERBOSE') { Write-Verbose ('{0} {1}: {2}' -f $DateTime, $Severity, $Message) }

        if ($Severity -eq 'DEBUG') { Write-DEBUG ('{0} {1}: {2}' -f $DateTime, $Severity, $Message) }
    
} # Write-Log


# End private functions

Function New-ETWProviderConfig
{
    <#
    .SYNOPSIS

    Initialzates new ETW session object

    .DESCRIPTION

    New-ETWProviderConfig is a function that initializations and returns a new ETWProviderConfig object. 
    The object is made of three properties: Name, Guid, and Keywords.

    .EXAMPLE

    $ProviderConfig = New-ETWProviderConfig

    #>

    $Config = New-Object psobject
    # Name of ETW provider to be started (Optional if Guid property is provided)
    $Config | Add-Member -NotePropertyName 'Name' -NotePropertyValue $null
    # Guid of ETW provider to be started (Optional if Name property is provided)
    $Config | Add-Member -NotePropertyName 'Guid' -NotePropertyValue $null
    # List of ProviderDataItem objects used as session filters (optional)
    # Initializes as an empty array
    $Config | Add-Member -NotePropertyName 'Keywords' -NotePropertyValue @()
    # Optional Provider options
    $Config | Add-Member -NotePropertyName 'Options' -NotePropertyValue $null

    $Config

} # New-ETWProviderConfig


Function ConvertTo-ETWGuid
{
    <#
    .SYNOPSIS
    
    Converts an ETW provider name to a GUID

    .DESCRIPTION
    
    ConvertTo-ETWGuid is a function that takes a provider name [string] and return the its corresponding GUID

    .PARAMETER ProviderName

    Name of an ETW provider

    .EXAMPLE
    
    ConvertTo-ETWGuid -ProviderName Microsoft-Windows-Kernel-Process

    Returns GUID associated with the Microsoft-Windows-Kernel-Process provider

    #>


    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Alias("Provider")]
        [string]
        $ProviderName)

     $ProviderGuid = [Microsoft.Diagnostics.Tracing.Session.TraceEventProviders]::GetProviderGuidByName($ProviderName)
     If ($ProviderGuid -eq [System.Guid]::Empty) {

         throw "$ProviderName either does not exist or has empty GUID"
    }
    else {
        $ProviderGuid
    }

} # ConvertTo-ETWGuid

Function Get-ETWProviderKeywords
{
    
    <#
    .SYNOPSIS
    
    Collects event keywords for a specified ETW provider

    .DESCRIPTION
    
    Get-ETWProviderKeywords is a function that collections keywords for a given ETW provider.
    Keywords describe events collected by the provider and can be used to restrict what events are captured.

    .PARAMETER Provider
    
    Name of an ETW provider

    .EXAMPLE
    
    Get-ETWProviderKeywords -ProviderName Microsoft-Windows-Kernel-Process

    Returns keywords associated with the Microsoft-Windows-Kernel-Process provider

    #>

    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $ProviderName)

        If ($ProviderName -is [string]) {
            $ProviderName = ConvertTo-ETWGuid($ProviderName)
        }

        [Microsoft.Diagnostics.Tracing.Session.TraceEventProviders]::GetProviderKeywords($ProviderName)

} # Get-ETWProviderKeywords

Function Get-ETWProvider {
    <#
    .SYNOPSIS

    Returns a ProviderMetadata object for each enabled ETW provider.

    .DESCRIPTION

    Get-ETWProvider is a function that returns objects representing ETW provider metadata

    .EXAMPLE

    Get-ETWProvider

    Returns list of all ETW providers

    #>

    [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.GetProviderNames() | ForEach-Object {
        try {
            [System.Diagnostics.Eventing.Reader.ProviderMetadata]($_)
        }
        catch {}
    }
} # Get-ETWProvider




Function New-ETWProviderOption 
{
    <#
    .SYNOPSIS
    
    Creates new TraceEventProviderOptions object

    .DESCRIPTION
    
    New-ETWProviderOption is a function that creates a new TraceEventProviderOptions object with the EventIDsToEnable/Disable properties set as lists.

    .EXAMPLE
    
    New-ETWProviderOption

    Creates a new TraceEventProviderOptions object with the EventIDsToEnable/Disable properties set as lists. Adding to these properties will limit what events are captured during an ETW session.

    #>

    $Options = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventProviderOptions
    $Options.EventIDsToEnable = New-Object System.Collections.Generic.List[Int]
    $Options.EventIDsToDisable = New-Object System.Collections.Generic.List[Int]

    $Options
}

Function Get-ETWSessionNames {
    <#
    .SYNOPSIS

    Generates list of ETW session names

    .DESCRIPTION

    Get-ETWSessionNames is a function that enumerates active ETW sessions and return their names in an array.

    .EXAMPLE

    Get-ETWSessionNames

    Returns all active ETW sessions

    #>

     [Microsoft.Diagnostics.Tracing.Session.TraceEventSession]::GetActiveSessionNames()
}


Function Get-ETWSessionDetails {
    <#
    .SYNOPSIS

    Returns an array of active ETW session GetProviderNames

    .DESCRIPTION

    Get-ETWSessionDetails is a function that returns a TraceEventSession object for a given session name

    .PARAMETER SessionName

    Name of ETW session

    .Example

    Get-ETWSessionDetails ProcessMonitor

    Returns session details about the "ProcessMonitor" ETW session

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $SessionName
    )
    # Verify session exists
    If ( -Not (Test-IsSession -SessionName $SessionName) ) {
        throw "Session does not exist"
    }
    try {
            [Microsoft.Diagnostics.Tracing.Session.TraceEventSession]::GetActiveSession($SessionName)
        }
    catch {
        throw "Failed to get session details"
    }

} # Get-ETWSession


Function Start-ETWSession
{
    <#
    .SYNOPSIS

    Starts an event tracing session

    .DESCRIPTION

    Start-ETWSession is a function that starts an event tracing session with one or more ETW providers.
    Events from this session are written to a file at the location given by the $OutputFile argument.

    .PARAMETER ProviderConfig

    PSObject containing the name and GUID of the ETW provider to be started.
    Optionally the keyword property can restrict which events are enabled during the session.

    .PARAMETER OutputFile

    Location on disk where ETW events will be written. Full path should be provided.

    .PARAMETER SessionName

    Unique name describing the ETW session. This name will be visible from the Get-ETWSession function

    .PARAMETER MaxFileSize

    Max size of etl file before old events start being overwritten. 


    .EXAMPLE

    Start-ETWSession -ProviderConfig $Config -OutputFile C:\test.etl -SessionName TestSession -MaxBufferSize 100

    Start an ETW session named "TestSession" and write events to the file "C:\test.etl".
    The ETW provider(s) name(s) and keywords are in the predefined variable "$Config.
    The $Config variable should be a single instance or array of objects created from the New-ETWProviderConfig function.
    The output file will grow up to 50 MB before the oldest events are overwritten

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [psobject]
        $ProviderConfig,

        [Parameter(Mandatory=$true)]
        [string]
        $SessionName,

        [Parameter(Mandatory=$true)]
        [string]
        $OutputFile,

        [Parameter(Mandatory=$false)]
        [int]
        $MaxFileSize = 50
    )

    BEGIN {
        
        # Check if active session with same name already exists
        If ( (Test-IsSession -SessionName $SessionName) ) {

            throw $SessionName+ " already exists. Cannot create again"
        }
        $ProviderConfig | ForEach-Object {
            # Verify either provider Name or Guid was provided
            If ( ( $_.Name -eq $null ) -and ($_.Guid -eq $null ) ) {

                throw "Must provide either provider name or GUID"
            }

            # Check that provider name exists
            If ( -Not ( $_.Name -eq $null ) -and -Not ( Test-IsProvider -ProviderName $_.Name ) ) {

                Throw $_.Name + " is not a valid ETW Provider name"
            }
        }

        Write-Log "Session name set to $SessionName" -Severity "VERBOSE"
        Write-Log "Provider set to $ProviderName" -Severity "VERBOSE"
        $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
    }
    PROCESS {
        # Create our ETW Session options
        $options = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSessionOptions
        $options.Create
        # Create ETW session
        $session = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSession -ArgumentList @($SessionName, $path, $options)
        # Setting StopOnDispose to false will not end a session if powershell ends
        $session.StopOnDispose = $false
        # Setting max file size
        $session.CircularBufferMB = $MaxFileSize

        # Set log level. Default, and only supported option at this time, is Verbose

        $TraceEventLevel = 5 # Verbose
        # Start session
        $ProviderConfig | ForEach-Object {
            
            # Keywords are used to filter what events are captured during an ETW session and are calculated via a bitmask
            # Adding the value for the enables to correct events. If keywords are not provided no event filters are used
            If ( $_.Keywords ) {
                $MatchAnyKeywords = $_.Keywords | ForEach-Object { $_.Value } | Measure-Object -Sum | Select-Object -ExpandProperty sum
            } else {
                $MatchAnyKeywords = [uint64]::MaxValue
            }

            # Determine if provider should be enabled by GUID or name

            If ( $_.Name ) {
                $ProviderID = $_.Name
            } else {
                $ProviderID = $_.Guid
            }

            $result = $session.EnableProvider($ProviderID, $TraceEventLevel, $MatchAnyKeywords, $_.Options) 

        }

        # EnableProvider returns false if session if not previously exist
        If ( $result -eq $False ) {
            Write-Log "Successfully started ETW session $SessionName" -Severity 'INFO'
        }
        else {
            throw "Failed to start session $SessionName"
        }
    }

} # Start-ETWSession

Function Start-ETWKernelSession
{
    <#
    .SYNOPSIS
    
    Enables Windows Kernel ETW Provider

    .DESCRIPTION
    
    In ETW there is a special provider to get certain events from the Windows kernel. In some earlier Windows versions (Win7 and 2008R2) there is only one allowed kernel session with a static name.
    More recent versions allow for multiple sessions and multiple session names.

    .PARAMETER OutputFile
    
    Location on disk where Kernel ETW events will be written. Full path should be provided.
    
    .PARAMETER MaxFileSize

    Max size of etl file before old events start being overwritten. 

    .PARAMETER SessionName 
    
    Optional parameter to define a unique Kernel session name. On Win7 and 2008R2 this name has be to "NT Kernel Logger", which is the configured default value.
    The default value will work on modern Windows operating systems, but may cause issues if another session with the same name already exists.

    .EXAMPLE

    Start-ETWKernelSession -OutputFile .\kernel_events.etl

    This will start the kernel ETW provider, register a new sessin with the default name "NT Kernel Logger" and write output to the file "kernel_events.etl"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $OutputFile,

        [Parameter(Mandatory=$false)]
        [string]
        $SessionName = [Microsoft.Diagnostics.Tracing.Parsers.KernelTraceEventParser]::KernelSessionName,

        [Parameter(Mandatory=$false)]
        [int]
        $MaxFileSize = 50
    )

    # For kernel events we are mostly concerned with Process events
    $Process = 0x00000001

    $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)

    # Create ETW session options
    $options = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSessionOptions
    $options.Create

    $session = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSession -ArgumentList @($SessionName, $path)
    
    $session.StopOnDispose = $false

    # Setting max file size
    $session.CircularBufferMB = $MaxFileSize
    
    # Starts kernel session filtered to only collect process events
    $result = $session.EnableKernelProvider($Process) 

} # Start-ETWKernelSession


Function Stop-ETWSession {
    <#
    .SYNOPSIS

    Stop an ETW session

    .DESCRIPTION

    Stop-ETWSession is a function that attaches to and stops an existing ETW session

    .PARAMETER SessionName

    Name of valid ETW Session

    .PARAMETER StopKernelSession

    Boolean parameter to also stop the default kernel provider session. Only works if kernel session name is "NT Kernel Logger"


    .EXAMPLE

    Stop-ETWSession ProcessMonitor

    Stops ETW session name "ProcessMonitor"

    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $SessionName,

        [Parameter(Mandatory=$false)]
        [switch]
        $StopKernelSession = $false


    )

    BEGIN {
        if ( -Not (Test-IsSession -SessionName $SessionName ) ) {
            throw "$SessionName is not a valid session"
        }
    }
    PROCESS {
        # Create our ETW Session options
        $options = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSessionOptions
        $options.Attach
        # Create ETW session
        $session = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSession -ArgumentList @($SessionName, "", $options)
        # Stop session
        $result = $session.stop()

        if ($result) {
            Write-Log "Successfully stopped ETW session $SessionName" -Severity 'INFO'
        } else {
            Write-Log "Failed to stop ETW session $SessionName" -Severity 'INFO'
        }

        If ($StopKernelSession) {
            $KernelName = "NT Kernel Logger"
            $session = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSession -ArgumentList @($KernelName, "", $options)
            # Stop session
            $KerResult = $session.stop()

            if ($KerResult) {
            Write-Log "Successfully stopped kernel ETW session" -Severity 'INFO'
        } else {
            Write-Log "Failed to stop kernel ETW session" -Severity 'INFO'
        }
        }
    }

} # Stop-ETWSession

Function Get-ETWForensicEventLog
{
    <#
    .SYNOPSIS

    Parses ETL event log for forensically significant events

    .DESCRIPTION
    
    Get-ETWForensicEventLog is a function tha parses an ETW event trace log for forensically significant information.
    The raw log can be read using the builtin Get-WinEvent cmdlet. 

    .PARAMETER Path
    
    Path of the etl file to parse

    .EXAMPLE
    
    Get-ETWForensicEventLog -Path C:\logs\process.etl

    Converts process.etl for forensically significant ETW events for supported providers and returns objects representing the forenically signifant information. 


    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    if (-not (Test-Path $path )) {
        $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
    }
    # Hash table mapping of supported ETW providers to parser functions
    $script:Providers = @{
    'Microsoft-Windows-Kernel-Process'  = 'KernelProcessParser'
    'Microsoft-Windows-Kernel-Network'  = 'KernelNetworkParser'
    'Microsoft-Windows-Kernel-File'     = 'KernelFileParser'
    'Microsoft-Windows-DNS-Client'      = 'DNSClientParser'
    'Microsoft-Windows-PowerShell'      = 'PowerShellParser'
    }

    $Events = @{}
    Write-Log "Found etw output file at: $path" -Severity 'INFO'
    Get-WinEvent -Path $Path -Oldest | Where-Object {
        $script:Providers.ContainsKey($_.ProviderName) } | ForEach-Object {
            &$script:Providers[$_.ProviderName] -Event $_ }

    # Check if kernel output exists

    $KernelSessPath = -join([IO.Path]::GetDirectoryName($path) + '\' +  [IO.Path]::GetFileNameWithoutExtension($Path) + "_kernelsession" + [IO.Path]::GetExtension($Path))
    If ( Test-Path $KernelSessPath )  {
        Write-Log "Found kernel session etw file at: $KernelSessPath" -Severity 'INFO'
        Get-WinEvent -Path $KernelSessPath -Oldest |
            # Filter out any event that does not contain command line in eventpayload
            ForEach-Object { 
                KernelSessionParser -EventPayload (([xml]$_.toxml()).Event.ChildNodes.EventPayload)[1] 
            }
    }

    $Events.Values
} # Get-ETWForensicEventLog

Function Get-ETWForensicGraph
{
    <#
    .SYNOPSIS

    Visualizes parent and child process relationships

    .DESCRIPTION
    
    Get-ETWForensicGraph is a function that parses the output from Get-ETWForensicEventLog and visualizes parent and child relationships

    .PARAMETER ETWObject
    
    Output from Get-ETWForensicEventLog

    .PARAMETER ParentProcessID
    
    Starting process ID. Function will enumerate 5 layers of child processes from this starting point.

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        $ETWObject,

        [Parameter(Mandatory=$True)]
        $ParentProcessID
    )
    $ImageName = $ETWObject | Where-Object { $_.ProcessId -eq $ParentProcessID } | ForEach-Object {

        If ($_.ImageName) {
            $_.ImageName
        } else {"Unknown"}
    }

    $ChildProcs = $ETWObject | Where-Object { $_.ProcessId -eq $ParentProcessID } | Select-Object -ExpandProperty ChildProcesses

    $IMG = @"
`t||
`t||
`t||

"@
    $2IMG = @"
`t`t||
`t`t||
`t`t||

"@

    $3IMG = @"
`t`t`t||
`t`t`t||
`t`t`t||

"@

    $4IMG = @"
`t`t`t`t||
`t`t`t`t||
`t`t`t`t||

"@

    $5IMG = @"
`t`t`t`t`t||
`t`t`t`t`t||
`t`t`t`t`t||

"@

    Write-Host `n`n$ImageName "($ParentProcessID)" -ForegroundColor Green
    $IMG
    $ChildProcs |
        ForEach-Object {
            $Proc = $_.ProcessID
            Write-Host `t $_.ImageName "($Proc)" -ForegroundColor Green
            If ($_.ChildProcesses) {
                $2IMG
                $_.ChildProcesses | ForEach-Object {
                    $Proc = $_.ProcessId
                    Write-Host `t`t $_.ImageName "($Proc)" -ForegroundColor Green

                    If ($_.ChildProcesses) {
                        $3IMG
                        $_.ChildProcesses | ForEach-Object {
                            $Proc = $_.ProcessID
                            Write-Host `t`t`t $_.ImageName "($Proc)" -ForegroundColor Green
                            
                            If ($_.ChildProcesses) {
                                $4IMG
                                $_.ChildProcesses | ForEach-Object {
                                    $Proc = $_.ProcessID
                                    Write-Host `t`t`t`t $_.ImageName "($Proc)" -ForegroundColor Green
                                    
                                    If ($_.ChildProcesses) {
                                        $5IMG
                                        $_.ChildProcesses | ForEach-Object {
                                            $Proc = $_.ProcessID
                                            Write-Host `t`t`t`t`t $_.ImageName "($Proc)" -ForegroundColor Green
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }

}
Function Start-ETWForensicCollection
{
    <#
    .SYNOPSIS

    Initiates an ETW session to collect forensically significant events

    .DESCRIPTION
    
    Start-ETWForensicCollection is a function that initiates pre-defined event tracing providers and filters. 
    This configuration was designed to enable forensically important providers and event types.

    .PARAMETER OutputFile

    Location on disk where ETW events will be written. Full path should be provided.

    .PARAMETER SessionName

    Unique name describing the ETW session. This name will be visible from the Get-ETWSession function

    .PARAMETER EnableVerbose

    Enables verbose event capture (ex. all file writes). Should only be enabled for short event captures.

    .PARAMETER DisableKernelProvider

    Disables kernel session during forensic capture. Disabling this provider results in command lines not being captured.

    .EXAMPLE
    
    Start-ETWForensicCollection -OutputFile C:\test\out.etl -SessionName collection

    Starts ETW session named collection and captured events are writen to the path 'C:\test\out.etl'. 


    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $SessionName,

        [Parameter(Mandatory=$true)]
        [string]
        $OutputFile,

        [Parameter(Mandatory=$False)]
        [switch]
        $EnableVerbose = $false,

        [Parameter(Mandatory=$False)]
        [switch]
        $DisableKernelProvider = $false

    )

    # Resolve full path of output file
    $OutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)

    $ProviderConfigs = @()

    # Build config for kernel Process
    $KernelProcessName = 'Microsoft-Windows-Kernel-Process'

    $KernelProcessConfig = New-ETWProviderConfig
    $KernelProcessConfig.Name = $KernelProcessName

    # Only want to enable process start/stop and DLL load events
    $ProcessRegex = '_PROCESS$|_IMAGE$|_THREAD$'

    Get-ETWProviderKeywords -ProviderName $KernelProcessConfig.Name |
        Where-Object { $_.Name -match $ProcessRegex } |
        ForEach-Object { $KernelProcessConfig.Keywords += $_ } 

    $ProviderConfigs += $KernelProcessConfig

    # Build config for PowerShell events
    $PowerShellName = "Microsoft-Windows-PowerShell"
    $PowerShellConfig = New-ETWProviderConfig
    $PowerShellConfig.name = $PowerShellName

    $ProviderConfigs += $PowerShellConfig

    # Build config for network events
    $KernelNetworkName = 'Microsoft-Windows-Kernel-Network'

    $KernelNetworkConfig = New-ETWProviderConfig
    $KernelNetworkConfig.Name = $KernelNetworkName

    # List of event IDs to capture
    $IDs = @( 12 ) # IPv4 connection attempted

    $NetOptions = New-ETWProviderOption

    $IDs | ForEach-Object {
         $NetOptions.EventIDsToEnable.Add( $_ ) 
    }

    $KernelNetworkConfig.Options = $NetOptions

    $ProviderConfigs += $KernelNetworkConfig

    # Build config for file events

    $KernelFileName = 'Microsoft-Windows-Kernel-File'

    $KernelFileConfig = New-ETWProviderConfig
    $KernelFileConfig.Name = $KernelFileName

    # Only capturing file create, write, and delete events
    If ( $EnableVerbose ) {
         $FileRegex = "CREATE|WRITE|DELETE"
    }
    else { $FileRegex = "CREATE|DELETE" }
    
    Get-ETWProviderKeywords -ProviderName $KernelFileConfig.Name |
        Where-Object { $_.Name -match $FileRegex } |
        ForEach-Object { $KernelFileConfig.Keywords += $_ } 

    $ProviderConfigs += $KernelFileConfig
    
    # Build config for DNS capture
    $DNSClientName = 'Microsoft-Windows-DNS-Client'
    $DNSConfig = New-ETWProviderConfig
    $DNSConfig.Name = $DNSClientName

    # List of event IDs to capture
    $IDs = @(3000, 3008)
    $DNSOptions = New-ETWProviderOption
    $IDs | ForEach-Object {
        $DNSOptions.EventIDsToEnable.Add( $_ )
    }
    $DNSConfig.Options = $DNSOptions
    # End DNS capture config

    $ProviderConfigs += $DNSConfig

    # Start ETW Session

    try 
    {
        Write-Log "Starting ETW forensic collection." -Severity 'INFO'
        Write-Log "Output will be written to: $OutputFile" -Severity 'INFO'

        Start-ETWSession -SessionName $SessionName -OutputFile $OutputFile -ProviderConfig $ProviderConfigs
    } catch {

        throw "Failed to start ETW forensic collection"
    }

    If (-not $DisableKernelProvider) {
        try {
            $KerProviderFName = [IO.Path]::GetFileNameWithoutExtension($OutputFile) + "_kernelsession" `
                + [IO.Path]::GetExtension($OutputFile)

            $KernelFullPath = Join-Path (Split-Path $OutputFile) $KerProviderFName

            Write-Log "Writing kernel output to: $KernelFullPath" -Severity 'INFO'
            
            Start-ETWKernelSession -OutputFile $KernelFullPath
        } catch {
            throw "Failed to start ETW kernel session"
        }
    }

} # Start-ETWForensicCollection