@{

RootModule = "PSWasp.psm1"

ModuleVersion = "0.0.0.1"

Author = "Matt Hastings & Dave Hull"

# functions to export
FunctionsToExport = @(
    'ConvertTo-ETWGuid',
    'Get-ETWForensicEventLog',
    'Get-ETWForensicGraph',
    'Get-ETWProviderKeywords',
    'Get-ETWProvider',
    'New-ETWProviderConfig',
    'Get-ETWSessionDetails',
    'Get-ETWSessionNames',
    'New-ETWProviderOption',
    'Start-ETWForensicCollection',
    'Start-ETWSession',
    'Start-ETWKernelSession',
    'Stop-ETWSession'

)

}