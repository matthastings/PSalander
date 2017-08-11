# PSalander

PSalander is a PowerShell project that enables users to easily interact with Event Tracing for Windows (ETW); specifically designed for forensic collection and analysis. Originally intended as a Windows debugging utility and ETW has evolved to support a myriad of diverse use cases. Modern Windows operating systems (8.1, 2012, Win10, and Server 2016) ship with hundreds of application and kernel layer ETW providers, any of which could capture and log critical information during an investigation. PSalandar enables users to easily start and capture events from one or many ETW providers. One of the great features of ETW is that sessions can consist of multiple ETW providers which allow to link otherwise individual events together. Using this feature PSalandar contains default functionality to enable an "ETW forensic collection" which combines, what the authors found to be, forensically relevant ETW provides and removes the hurdles of enabling multiple providers with different filtering options. The result is a single PowerShell function to immediately start logging and forensically relevant information on a system. 

## Requirements
 - Uses the Microsoft TraceEvent Library from https://www.nuget.org/packages/Microsoft.Diagnostics.Tracing.TraceEvent/ for ETW functions
 - .NET 4.0 or greater
 - PowerShell 3.0 or greater

## Examples

### Starting Forensic Collection with PSalander
INSERT EXAMPLES of starting and parsing etw providers

### Parsing any .ETL Log

```Get-WinEvent -Path <path to ETL file> -Oldest```


## Useful links
https://github.com/Microsoft/dotnetsamples/blob/master/Microsoft.Diagnostics.Tracing/TraceEvent/docs/TraceEvent.md
https://blogs.msdn.microsoft.com/vancem/2012/12/20/using-tracesource-to-log-etw-data-to-a-file/
https://msdn.microsoft.com/en-us/library/windows/desktop/aa363668(v=vs.85).aspx
https://github.com/Microsoft/perfview/blob/master/src/TraceEvent/TraceEventSession.cs
https://blogs.technet.microsoft.com/office365security/hidden-treasure-intrusion-detection-with-etw-part-1/
https://blogs.technet.microsoft.com/office365security/hidden-treasure-intrusion-detection-with-etw-part-2/

## Requirements
 - Uses the Microsoft TraceEvent Library from https://www.nuget.org/packages/Microsoft.Diagnostics.Tracing.TraceEvent/ for ETW functions
 - .NET 4.0 or greater
 - PowerShell 3.0 or greater

## Referenced Work

- Module design for PSalander was heavily influenced by [CimSweep](https://github.com/PowerShellMafia/CimSweep). It should be a model for all PS modules follow.
- Zak Brown and the Microsoft OS365 folks have done great ETW work and have their own open source ETW library [krabsetw](https://github.com/microsoft/krabsetw)
