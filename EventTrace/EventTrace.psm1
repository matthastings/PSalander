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

    .EXAMPLE

    Start-ETWSession -ProviderConfig $Config -OutputFile C:\test.etl -SessionName TestSession

    Start an ETW session named "TestSession" and write events to the file "C:\test.etl".
    The ETW provider(s) name(s) and keywords are in the predefined variable "$Config.
    The $Config variable should be a single instance or array of objects created from the New-ETWProviderConfig function.

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
        $OutputFile
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

        Write-Verbose "Session name set to $SessionName"
        Write-Verbose "Provider set to $ProviderName"
        $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
        Write-Verbose "Setting output file to $path"
    }
    PROCESS {
        # Create our ETW Session options
        $options = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSessionOptions
        $options.Create
        # Create ETW session
        $session = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSession -ArgumentList @($SessionName, $OutputFile, $options)
        # Setting StopOnDispose to false will not end a session if powershell ends
        $session.StopOnDispose = $false


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
            Write-Verbose "Started session $SessionName"
        }
        else {
            throw "Failed to start session $SessionName"
        }
        return $true
    }

} # Start-ETWSession

Function Stop-ETWSession {
    <#
    .SYNOPSIS

    Stop an ETW session

    .DESCRIPTION

    Stop-ETWSession is a function that attaches to and stops an existing ETW session

    .PARAMETER SessionName

    Name of valid ETW Session

    .EXAMPLE

    Stop-ETWSession ProcessMonitor

    Stops ETW session name "ProcessMonitor"

    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $SessionName
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
        $session.stop()
    }

} # Stop-ETWSession

Function Get-ETWEventLog
{
    <#
    .SYNOPSIS

    Parses ETL event log for forensically significant events

    .DESCRIPTION
    
    Get-ETWEventLog is a function tha parses an ETW event trace log for forensically significant information.
    The raw log can be read using the builtin Get-WinEvent cmdlet. 

    .PARAMETER Path
    
    Path of the etl file to parse

    .EXAMPLE
    
    Get-ETWEventLog -Path C:\logs\process.etl

    Converts process.etl for forensically significant ETW events for supported providers and returns objects representing the forenically signifant information. 


    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    # Hash table mapping of supported ETW providers to parser functions
    $script:Providers = @{
    'Microsoft-Windows-Kernel-Process' = 'KernelProcessParser'
    'Microsoft-Windows-Kernel-Network' = 'KernelNetworkParser'
    }

    $Events = @{}

    Get-WinEvent -Path $Path -Oldest | Where-Object {
        $script:Providers.ContainsKey($_.ProviderName) } | ForEach-Object {
            &$script:Providers[$_.ProviderName] -Event $_ }

    $Events.Values

} # Get-ETWEventLog

Function Start-ETWForensicCollection
{
    <#
    .SYNOPSIS

    Initiates an ETW session to collect forensically significant events

    .DESCRIPTION
    
    Start-ETWForensicCollection is a function that initiates pre-defined event tracing providers and filters. This configuration was designed to enable forensically important providers and event types.

    .PARAMETER OutputFile

    Location on disk where ETW events will be written. Full path should be provided.

    .PARAMETER SessionName

    Unique name describing the ETW session. This name will be visible from the Get-ETWSession function

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
        $OutputFile
    )

    $ProviderConfigs = @()

    # Build config for kernel Process
    $KernelProcessName = 'Microsoft-Windows-Kernel-Process'

    $KernelProcessConfig = New-ETWProviderConfig
    $KernelProcessConfig.Name = $KernelProcessName

    # Only want to enable process start/stop and DLL load events
    $ProcessRegex = '_PROCESS$|_IMAGE$'

    Get-ETWProviderKeywords -ProviderName $KernelProcessConfig.Name |
        Where-Object { $_.Name -match $ProcessRegex } |
        ForEach-Object { $KernelProcessConfig.Keywords += $_ } 

    $ProviderConfigs += $KernelProcessConfig

    # Build config for network events
    $KernelNetworkName = 'Microsoft-Windows-Kernel-Network'

    $KernelNetworkConfig = New-ETWProviderConfig
    $KernelNetworkConfig.Name = $KernelNetworkName

    # List of event IDs to capture
    $IDs = @( 12 ) # IPv4 connection attempted

    $NetOptions = New-ETWProviderOption

    $IDs |
        ForEach-Object { $NetOptions.EventIDsToEnable.Add( $_ ) }

    $KernelNetworkConfig.Options = $NetOptions

    $ProviderConfigs += $KernelNetworkConfig

    # Start ETW Session

    try 
    {
        Start-ETWSession -SessionName $SessionName -OutputFile $OutputFile -ProviderConfig $ProviderConfigs
    } catch {

        throw "Failed to start ETW forensic collection"
    }

} # Start-ETWForensicCollection