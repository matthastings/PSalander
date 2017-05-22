Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

$TestDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$RootModuleDir = Resolve-Path "$TestDir\.."
$Module = "$RootModuleDir\EventTrace.psd1"

$ProviderName = "Microsoft-Windows-Kernel-Process"

Import-Module $Module -Force -ErrorAction Stop

Describe 'ConvertTo-ETWGuid' {
    Context 'input validation' {
        It 'Should should accept string input' {
            { ConvertTo-ETWGuid -ProviderName $ProviderName } | Should Not Throw
        }

        It "Should error on non-existent provider" {
            { ConvertTo-ETWGuid -ProviderName "DOES NOT EXIST" } | Should Throw
        }

        It 'Should require input' {
            { ConvertTo-ETWGuid -ProviderName } | Should Throw
        }
    }

    Context 'output validation' {
        It 'Should return type GUID' {
            { ConvertTo-ETWGuid -ProviderName $ProviderName -is [System.Guid] } | Should Be $true
        }
    }
}

Describe 'Get-ProviderKeywords' {
    Context 'input validation' {
        It 'Should require input' {
            { Get-ProviderKeywords -Provider } | Should Throw
        }

        It 'Should accept string input' {
            { Get-ProviderKeywords -Provider $ProviderName }
        }

        It "Should error on non-existent provider" {
            { Get-ProviderKeywords -ProviderName "DOES NOT EXIST" } | Should Throw
        }
    }
    Context 'output validation'{
        It 'Should return properly formatted ProviderDataItem objects' {
            $Result = Get-ProviderKeywords -Provider $ProviderName

            $Result[0].PSObject.TypeNames[0] | Should be 'Microsoft.Diagnostics.Tracing.Session.ProviderDataItem'
        }
    }
}

Describe 'Get-ETWProvider' {
    Context 'output validation' {
        It 'Should generate output'{ 
            { Get-ETWProvider } | Should Not BeNullOrEmpty
        }
        It 'Should return properly formatted ProviderMetadata objects' {
            $Result = Get-ETWProvider

            $Result[0].PSObject.TypeNames[0] | Should be 'System.Diagnostics.Eventing.Reader.ProviderMetadata'
        }
    }
}

Describe 'Get-ETWSession' {
    Context 'output validation' {
        It 'Should generate output' {
            { Get-ETWSession } | Should Not BeNullOrEmpty
        }

        It 'Should return properly formatted TraceEventSession objects' {
            $Result = Get-ETWSession

            $Result[0].PSObject.TypeNames[0] | Should be 'Microsoft.Diagnostics.Tracing.Session.TraceEventSession'
        }
    }
}