# PSWasp

PSWasp is a PowerShell project that enables users to easily interact with Event Tracing for Windows (ETW); specifically designed for forensic collection and analysis. Originally intended as a Windows debugging utility, ETW has evolved to support a myriad of diverse use cases. Modern Windows operating systems (8.1, 2012, Win10, and Server 2016) ship with hundreds of application and kernel layer ETW providers, any of which could capture and log critical information during an investigation. PSalandar enables users to easily start and capture events from one or many ETW providers. 

## Requirements
 - .NET 4.0 or greater
 - PowerShell 3.0 or greater

## External Dependencies
- PSWasp uses and ships a copy of the Microsoft's TraceEvent DLL [License](https://www.microsoft.com/net/dotnet_library_license.htm)

## Examples

### List all ETW providers on a System

```Get-ETWProvider```

### List all active ETW sessions 
 
```Get-ETWSessionNames```

### Enumerate details from active ETW sessions
Warning: Enumerating session details has been found to inadvertently stop ETW sessions in some cases.

```Get-ETWSessionDetails```

### Start Forensic Collection with PSWasp

#### Create provider object 
Defines the provider name or GUID, filtering keywords, or other filtering options
This example configures the `Micorsoft-Windows-Kernel-Process` provider and only enables the `Process`, `Image`, and `Thread` keywords
```
$ProviderConfig = New-ETWProviderConfig
$ProviderConfig.Name = 'Microsoft-Windows-Kernel-Process'
$ProcessRegex = '_PROCESS$|_IMAGE$|_THREAD$'
Get-ETWProviderKeywords -ProviderName $ProviderConfig.Name |
    Where-Object { $_.Name -match $ProcessRegex } |
    ForEach-Object { $ProviderConfig.Keywords += $_ } 
```

#### Start ETW Session

```Start-ETWSession -ProviderConfig $ProviderConfig -SessionName <unique session name> -OutputFile <path to etl file>```

### Stop ETW Session

```Stop-ETWSession -SessionName <previously provided unique session name>```

### Parse any .ETL Log

```Get-WinEvent -Path <path to ETL file> -Oldest```

### Start ETW forensic session with kernel session
Kernel session is an optional argument that starts a unique kernel session. Enabling this session allows for the capture of process command line arguments.

Note: Kernel session is enabled by default use `-DisableKernelProvider` to disable

```Start-ETWForensicCollection -SessionName <unique session name> -OutputFile <path to etl file>```

### Parse .ETL file generated from Start-ETWForensicCollection
Will automatically identify and parse any kernel session output files from the same session

```Get-ETWForensicEventLog -Path <path to ETL file>```  



## Useful links
https://github.com/Microsoft/dotnetsamples/blob/master/Microsoft.Diagnostics.Tracing/TraceEvent/docs/TraceEvent.md
https://blogs.msdn.microsoft.com/vancem/2012/12/20/using-tracesource-to-log-etw-data-to-a-file/
https://msdn.microsoft.com/en-us/library/windows/desktop/aa363668(v=vs.85).aspx
https://github.com/Microsoft/perfview/blob/master/src/TraceEvent/TraceEventSession.cs
https://blogs.technet.microsoft.com/office365security/hidden-treasure-intrusion-detection-with-etw-part-1/
https://blogs.technet.microsoft.com/office365security/hidden-treasure-intrusion-detection-with-etw-part-2/

## Referenced Work

- Module design for PSWasp was heavily influenced by [CimSweep](https://github.com/PowerShellMafia/CimSweep). It should be a model for all PS modules follow.
- Zak Brown and the Microsoft OS365 folks do great ETW work and have their own open source ETW library [krabsetw](https://github.com/microsoft/krabsetw)
