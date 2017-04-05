# Setup initial assembly import
$path = $PSScriptRoot + "\lib\Microsoft.Diagnostics.Tracing.TraceEvent.dll"
try {
    Add-Type -Path $path
}
catch {
    throw "Could not find TraceEvent DLL at path: $path"
}
# Verify assembly loaded
if (-Not ([appdomain]::currentdomain.getassemblies()).location -contains $path) {
    throw "Failed to load TraceEvent DLL"
}

Function Get-ETWProvider {
<#
.SYNOPSIS

Returns a ProviderMetadata object for each enabled ETW provider.

.DESCRIPTION

Get-ETWProvider is a function that returns objects representing ETW provider metadata
#>
    ForEach ($Name in [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.GetProviderNames()) {
        try { [System.Diagnostics.Eventing.Reader.ProviderMetadata]($name) } catch {}
    }
} # Get-ETWProvider

Function Get-ETWSession {
<#
.SYNOPSIS

Returns an array of active ETW session GetProviderNames

.DESCRIPTION

Get-ETWSession is a function that returns active ETW sessions

#>

    try {
        [Microsoft.Diagnostics.Tracing.Session.TraceEventSession]::GetActiveSessionNames()
    } 
    catch {
        "Failed to list active sessions"
    }

} # Get-ETWSession

Function Start-ETWProvider {
<#
.SYNOPSIS

Returns a boolean representing if 

.DESCRIPTION

Start-ETWProvider is a function that starts an ETW provider and will write output
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Alias("Provider")]
        [string]
        $ProviderName,

        [Parameter(Mandatory=$true)]
        [string]
        $SessionName,

        
        [Parameter(Mandatory=$true)]
        [string]
        $OutputFile
    )

    BEGIN {
        # Verify assembly loaded
        if (-Not ([appdomain]::currentdomain.getassemblies()).location -contains $path) {
            throw "Failed to load TraceEvent DLL"
        }
    }
    PROCESS {
        # Create our ETW Session options
        $options = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSessionOptions
        $options.Create
        # Create ETW session
        $session = New-Object -TypeName Microsoft.Diagnostics.Tracing.Session.TraceEventSession -ArgumentList @($SessionName, $OutputFile, $options)
        # Start session
        $session.EnableProvider(@($ProviderName))
        $session.StopOnDispose = $false
    }

} # Start-ETWProvider

Function Stop-ETWSession {
<#
.SYNOPSIS

Stops an ETW session

.DESCRIPTION

Stope-ETWSession is a function that stops an ETW session
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $SessionName
    )

    BEGIN {
        # Verify assembly loaded
        if (-Not ([appdomain]::currentdomain.getassemblies()).location -contains $path) {
            throw "Failed to load TraceEvent DLL"
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
