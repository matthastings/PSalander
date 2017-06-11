@{

RootModule = "EventTrace.psm1"

ModuleVersion = "0.0.0.1"

Author = "Matt Hastings & Dave Hull"

# functions to export
FunctionsToExport = @(
    'ConvertTo-ETWGuid',
    'Get-ETWEventLog',
    'Get-ETWProviderKeywords',
    'Get-ETWProvider',
    'New-ETWProviderConfig',
    'Get-ETWSessionDetails',
    'Get-ETWSessionNames',
    'New-ETWProviderOption',
    'Start-ETWForensicCollection',
    'Start-ETWSession',
    'Stop-ETWSession'

)

}