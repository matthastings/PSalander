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

Function ConvertTo-ETWGuid {
<#
.SYNOPSIS

Returns a provider GUID given

.DESCRIPTION

ConvertTo-ETWGuid is a function that returns the ETW GUID for a given provider. This functions requires the provider name as an input argument.
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
     else {$ProviderGuid}

} # ConvertTo-ETWGuid

Function Get-ProviderKeywords {
<#
.SYNOPSIS

Returns provider keywords

.DESCRIPTION

Get-ProviderKeywords is a function that returns a provider's keywords. This function accepts an input of either a provider name or provider GUID.
#>

    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $Provider)

        If ($Provider -is [string]) {
            $Provider = ConvertTo-ETWGuid($Provider)
        }

        [Microsoft.Diagnostics.Tracing.Session.TraceEventProviders]::GetProviderKeywords($Provider)

} # Get-ProviderKeywords

Function Get-ETWProvider {
<#
.SYNOPSIS

Returns a ProviderMetadata object for each enabled ETW provider.

.DESCRIPTION

Get-ETWProvider is a function that returns objects representing ETW provider metadata
#>

    [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.GetProviderNames() | ForEach-Object {
        try { [System.Diagnostics.Eventing.Reader.ProviderMetadata]($_) } catch {}
    }
} # Get-ETWProvider

Function Get-ETWSession {
<#
.SYNOPSIS

Returns an array of active ETW session GetProviderNames

.DESCRIPTION

Get-ETWSession is a function that returns active ETW sessions

#>
    function Get-SessionNames {
        [Microsoft.Diagnostics.Tracing.Session.TraceEventSession]::GetActiveSessionNames()
    }
    try {
        Get-SessionNames | ForEach-Object {
            [Microsoft.Diagnostics.Tracing.Session.TraceEventSession]::GetActiveSession($_)
        }
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
        [array]
        $ProviderName,

        [Parameter(Mandatory=$true)]
        [string]
        $SessionName,

        [Parameter(Mandatory=$true)]
        [string]
        $OutputFile,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ | ForEach-Object {$_ -is [Microsoft.Diagnostics.Tracing.Session.ProviderDataItem]} })]
        $Keywords
    )


    BEGIN {
        Write-Verbose "Session name set to $SessionName"
        Write-Verbose "Provider set to $ProviderName"
        $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
        Write-Verbose "Setting output file to $path"
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
        # Setting StopOnDispose to false will not end a session if powershell ends
        $session.StopOnDispose = $false
        
        # Keywords are used to filter what events are captured during an ETW session and are calculated via a bitmask
        # Adding the value for the enables to correct events. If keywords are not provided no event filters are used
        If ($Keywords) {
           $MatchAnyKeywords = $Keywords | ForEach-Object { $_.Value } | Measure-Object -Sum | Select-Object -ExpandProperty sum
        } else {
            $MatchAnyKeywords = [uint64]::MaxValue
        }

        # Set log level. Default, and only supported option at this time, is Verbose

        $TraceEventLevel = 5 # Verbose 
        # Start session
        $ProviderName | ForEach-Object {
             $result = $session.EnableProvider($_, $TraceEventLevel, $MatchAnyKeywords, $null)

        }
        # EnableProvider returns false if session if not previously exist
        If ($result -eq $False) {
            "Started session $SessionName"
        } 
        else {
            "Failed to start session $SessionName"
        }
        
        
    }

} # Start-ETWProvider

Function Stop-ETWSession {
<#
.SYNOPSIS

Stop an ETW session

.DESCRIPTION

Stop-ETWSession is a function that attaches to and stops an existing ETW session
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
