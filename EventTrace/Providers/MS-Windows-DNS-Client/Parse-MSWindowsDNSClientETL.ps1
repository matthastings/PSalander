<#
.SYNOPSIS
Converts MS-Windows-DNS-Client events properties first-order object noteproperties.

.DESCRIPTION
Convert-DNSEventProperties takes an array of MS-Windows-DNS-Client events and converts the
event properties to first-order noteproperties on the objects it returns

.PARAMETER Events
An array of MS-Windows-DNS-Client events

.EXAMPLE
$Events | Convert-DNSEventProperties | Format-List * -Force

TimeCreated : 5/26/2017 10:56:53 AM
Id          : 3008
Message     : DNS query is completed for the name v10.vortex-win.data.microsoft.com, type 1, query options 1073766400 with status 87 Results
Name        : v10.vortex-win.data.microsoft.com
Type        : 1
Options     : 1073766400
Status      : 87
Result      :

TimeCreated        : 5/26/2017 10:56:53 AM
Id                 : 3009
Message            : Network query initiated for the name v10.vortex-win.data.microsoft.com (is parallel query 1) on network index 0 with
                     interface count 1 with first interface name Ethernet0, local addresses 192.168.123.53; and Dns Servers 192.168.123.10;
Name               : v10.vortex-win.data.microsoft.com
isParallelQry      : 1
NetworkIndex       : 0
InterfaceCount     : 1
FirstInterfaceName : Ethernet0
LocalAddresses     : 192.168.123.53;
DNSServers         : 192.168.123.10;

.NOTES
General notes
#>
function Convert-DNSEventProperties {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]]
        $Events
    )

    Process {
        # Create Object with common properties
        $Events | Foreach-Object {
            $_Event = $_
            $Obj = New-Object psobject 
            $Obj | Add-Member -NotePropertyName 'TimeCreated' -NotePropertyValue $_Event.TimeCreated
            $Obj | Add-Member -NotePropertyName 'Id' -NotePropertyValue $_Event.Id
            $Obj | Add-Member -NotePropertyName 'Message' -NotePropertyValue $_Event.Message

            # Add properties based on Event Id
            switch ( $_Event.Id ) {
                1002 { 
                    # DNS server for interface
                    $Obj | Add-Member -NotePropertyName 'Interface' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'DNSServer' -NotePropertyValue $_Event.Properties[2].value
                    break
                } # DNS server for interface

                1026 {
                    # Response question doesn't match request question
                    $Obj | Add-Member -NotePropertyName 'ResponseQuestion' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'DNSServer' -NotePropertyValue $_Event.Properties[3].value
                    $Obj | Add-Member -NotePropertyName 'RequestQuestion' -NotePropertyValue $_Event.Properties[0].value                
                    break
                } # Response question doesn't match request question

                3001 {
                    # Query result
                    $Obj | Add-Member -NotePropertyName 'Result' -NotePropertyValue $_Event.Properties[0].value
                    break
                } # Query result

                3002 {
                    # Cache lookup for name, type, query options
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Options' -NotePropertyValue $_Event.Properties[2].value
                    break
                } # Cache lookup for name, type, query options

                3003 {
                    # Cache lookup for name, type completed with result
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Result' -NotePropertyValue $_Event.Properties[2].value
                    break
                } # Cache lookup for name, type completed with result

                3004 {
                    # FQDN query initiated for name, type, with options
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Options' -NotePropertyValue $_Event.Properties[2].value
                    break
                } # FQDN query initiated for name, type, with options

                3005 {
                    # FQDN query for name, type completed with result
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Result' -NotePropertyValue $_Event.Properties[2].value
                    break
                } # FQDN query for name, type completed with result

                3006 { 
                    # Query for name, type, options, server list, isNetwork, network index, interface index, asynchronous
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Options' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'ServerList' -NotePropertyValue $_Event.Properties[3].value
                    $Obj | Add-Member -NotePropertyName 'isNetworkQuery' -NotePropertyValue $_Event.Properties[4].value
                    $Obj | Add-Member -NotePropertyName 'NetworkIndex' -NotePropertyValue $_Event.Properties[5].value
                    $Obj | Add-Member -NotePropertyName 'InterfaceIndex' -NotePropertyValue $_Event.Properties[6].value
                    $Obj | Add-Member -NotePropertyName 'Asynchronous' -NotePropertyValue $_Event.Properties[7].value
                    break
                } # Query for name, type, options, server list, isNetwork, network index, interface index, asynchronous

                3007 {
                    # DNSQueryEx for name is pending
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    break
                } # DNSQueryEx for name is pending

                3008 {
                    # DNS query completed for name, type, options with status, and results
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Options' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'Status' -NotePropertyValue $_Event.Properties[3].value
                    $Obj | Add-Member -NotePropertyName 'Result' -NotePropertyValue $_Event.Properties[4].value
                    break
                } # DNS query completed for name, type, options with status, and results

                3009 {
                    # Network query initiated for name, is parallel query, on network index with iface count
                    # with first iface name, local addresses and DNS servers
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'isParallelQry' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'NetworkIndex' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'InterfaceCount' -NotePropertyValue $_Event.Properties[3].value
                    $Obj | Add-Member -NotePropertyName 'FirstInterfaceName' -NotePropertyValue $_Event.Properties[4].value
                    $Obj | Add-Member -NotePropertyName 'LocalAddresses' -NotePropertyValue $_Event.Properties[5].value
                    $Obj | Add-Member -NotePropertyName 'DNSServers' -NotePropertyValue $_Event.Properties[6].value
                    break
                } # Network query initiated for name, is parallel query, on network index with iface count
                # with first iface name, local addresses and DNS servers

                3010 {
                    # Query sent to server for name and type
                    $Obj | Add-Member -NotePropertyName 'Server' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    break
                } # Query sent to server for name and type

                3011 {
                    # Received response from server for name and type with response status
                    $Obj | Add-Member -NotePropertyName 'Server' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Status' -NotePropertyValue $_Event.Properties[3].value
                    break
                } # Received response from server for name and type with response status

                3012 {
                    # NETBIOS query initiated for name, network index, interface count, first interface name and
                    # local addresses
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'NetworkIndex' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'InterfaceCount' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'FirstInterfaceName' -NotePropertyValue $_Event.Properties[3].value
                    $Obj | Add-Member -NotePropertyName 'LocalAddresses' -NotePropertyValue $_Event.Properties[4].value
                    break
                } # NETBIOS query initiated for name, network index, interface count, first interface name and
                # local addresses

                3013 {
                    # NETBIOS query completed for name with status and result
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Status' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Results' -NotePropertyValue $_Event.Properties[2].value
                    break
                } # NETBIOS query completed for name with status and result

                3014 {
                    # NETBIOS query for name is pending
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    break
                } # NETBIOS query for name is pending

                3015 {
                    # DNSQueryEx canceled for name
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    break
                } # DNSQueryEx canceled for name

                3016 {
                    # Cache lookup called for name, type, options and interface index
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Options' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'InterfaceIndex' -NotePropertyValue $_Event.Properties[3].value
                    break
                } # Cache lookup called for name, type, options and interface index

                3018 {
                    # Cache lookup for name, type and option returned value with results
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'Option' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'Value' -NotePropertyValue $_Event.Properties[3].value
                    $Obj | Add-Member -NotePropertyName 'Results' -NotePropertyValue $_Event.Properties[4].value
                    break
                } # Cache lookup for name, type and option returned value with results

                3019 {
                    # Query wire called for name, type, interface index and network index
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'InterfaceIndex' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'NetworkIndex' -NotePropertyValue $_Event.Properties[3].value
                    break
                } # Query wire called for name, type, interface index and network index

                3020 {
                    # Response for name, type, interface index and network index returned value with results
                    $Obj | Add-Member -NotePropertyName 'Name' -NotePropertyValue $_Event.Properties[0].value
                    $Obj | Add-Member -NotePropertyName 'Type' -NotePropertyValue $_Event.Properties[1].value
                    $Obj | Add-Member -NotePropertyName 'InterfaceIndex' -NotePropertyValue $_Event.Properties[2].value
                    $Obj | Add-Member -NotePropertyName 'NetworkIndex' -NotePropertyValue $_Event.Properties[3].value
                    $Obj | Add-Member -NotePropertyName 'Value' -NotePropertyValue $_Event.Properties[4].value
                    $Obj | Add-Member -NotePropertyName 'Results' -NotePropertyValue $_Event.Properties[5].value
                    break
                } # Response for name, type, interface index and network index returned value with results
            } # End switch

            $Obj
        }
    } # End Convert-DNSEventProperties
}