function Get-ETWProvider {
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


<#
$LIB_LOCATION = ".\lib\Microsoft.Diagnostics.Tracing.TraceEvent.dll"

$ETW = Add-Type -Path $LIB_LOCATION -PassThru

Write-Host $ETW
$session = $ETW::TraceEventSession("Session", ".\test.etl")

$session.StopOnDispose = $True
$session.EnableProvider
#>