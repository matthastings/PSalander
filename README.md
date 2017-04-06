# PSEventDetect

## Useful links
https://github.com/Microsoft/dotnetsamples/blob/master/Microsoft.Diagnostics.Tracing/TraceEvent/docs/TraceEvent.md
https://blogs.msdn.microsoft.com/vancem/2012/12/20/using-tracesource-to-log-etw-data-to-a-file/
https://msdn.microsoft.com/en-us/library/windows/desktop/aa363668(v=vs.85).aspx
https://github.com/Microsoft/perfview/blob/master/src/TraceEvent/TraceEventSession.cs

## Requirements
Uses the Microsoft TraceEvent Library from https://www.nuget.org/packages/Microsoft.Diagnostics.Tracing.TraceEvent/ for ETW functions


## Notes / Todos

* Doesn’t look like you can call multiple providers in a single session $result = $session.EnableProvider(@("Microsoft-Windows-PowerShell”, “ANOTHER SESSION NAME” )) does not work
* Need to look at enable provider options for custom provider configuration
* if there is time explore on demand event consumer 