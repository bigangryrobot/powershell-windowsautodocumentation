#*=============================================================================
#* Clark's Auto Doc Tool
#*=============================================================================

#*=============================================================================
#* Release Notes
#*=============================================================================
#*This will (should?) create a text file on the local desktop with the relevent information
#*desktop\localhostautodoc.txt
#*=============================================================================

function List-UserGroupMembers {
param([String] $computerName = ".",    [Array] $userGroups)
Clear-Variable group
Clear-Variable members
foreach($group in $userGroups){
    $group =[ADSI]"WinNT://$computerName/$group"
    $members = @($group.psbase.Invoke("Members"))
    $members | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) + " - " + $group.Name}
    }
}

$computers="Rat", `
"Goose", `
"Sabretooth", `
"Magneto", `
"Tiger", `
"Cheetah", `
"Cardinal", `
"Wolverine"

Foreach ($computer in $computers){
$date = (get-date).AddSeconds(-190)
Clear-Variable Finalreport
Clear-Variable profile
Clear-Variable authusers
$Target=$computer
$path=([Environment]::GetFolderPath("Desktop"))
$ComputerSystem = Get-WmiObject -computername $Target Win32_ComputerSystem
#$netinfos = GWMI -cl "Win32_NetworkAdapterConfiguration" -name "root\CimV2" -comp $target -filter "IpEnabled = TRUE"
$netinfos = Get-WmiObject -computername $Target Win32_networkadapter -Filter 'NetConnectionStatus=2'| ForEach-Object {$_.GetRelated('Win32_NetworkAdapterConfiguration')}
$colShares = Get-wmiobject -ComputerName $Target Win32_Share
$wmi = gwmi Win32_OperatingSystem -EA silentlycontinue -ComputerName $Target
$OperatingSystems = Get-WmiObject -computername $Target Win32_OperatingSystem
$colDisks = Get-WmiObject -ComputerName $Target Win32_LogicalDisk
$NICCount = 0
$colAdapters = Get-WmiObject -ComputerName $Target Win32_NetworkAdapterConfiguration
$memoryinmb = [math]::round(($ComputerSystem.TotalPhysicalMemory / 1048576))
$colItems = Get-WmiObject -computername $Target Win32_Product
$authusers = List-UserGroupMembers -computerName $env:COMPUTERNAME -userGroups "Administrators", "Power Users", "Remote Desktop Users", "Users", "Guests"
$profile = (new-object -com HNetCfg.FwMgr).LocalPolicy.CurrentProfile


$Finalreport += "
Server $Target
Major functions performed by the system
`t
System category (e.g. Major, Minor)
`t
User access mode (e.g. GUI,SSH,CMD/TERM)
`t
Operational status (e.g. Operational, Under development, Undergoing major modification)
`t
Special conditions
`t
Machine Type
`t$($ComputerSystem.Model)
Operating System
`t$($OperatingSystems.Caption)
Service Pack
`t$($OperatingSystems.CSDVersion)
Total Memory
`t$memoryinmb MB
Authorized Users
"
Foreach ($authuser in $authusers){
$Finalreport += "`t$authuser
"
}
$Finalreport += "Network Connection Information
"
Foreach ($netinfo in $netinfos){
if ($netinfo.MACAddress -ne $null) {
$Finalreport += "`t$($netinfo.IPAddress)`t$($netinfo.MACAddress)`t$($netinfo.Caption)
"
}
}
$Finalreport += "Firewall status
"
# Is firewall enabled?
if ($profile.FirewallEnabled) {
$Finalreport += "`tThe firewall is enabled on system
"
}
else {
$Finalreport += "`tThe firewall is NOT enabled on system
"
}

# Exceptions allowed?
if ($profile.ExceptionsNotAllowed) {$Finalreport += "`tExceptions NOT allowed
"}
else {$Finalreport += "`tExceptions are allowed
"}

# Notifications?
if ($profile.NotificationsDisabled) {$Finalreport += "`tNotifications are disabled
"}
else {$Finalreport += "`tNotifications are not disabled
"}

# Display determine global open ports
$ports = $profile.GloballyOpenPorts
if (!$ports -or $ports.count -eq 0) {
$Finalreport += "`tThere are no global open ports
"
}
else {
$Finalreport += "`tThere are $($ports.count) open port(s) as follows:
"
Foreach($port in $ports){
$Finalreport += "`t`t$($port.name) `t$($port.port)
"
}
}

# Display ICMP settings
$Finalreport += "`tICMP Settings:
"
$Finalreport += "`t`t $($profile.IcmpSettings)
"
# Display authorised applications
$apps = $profile.AuthorizedApplications
#
if (!$apps) {
$Finalreport += "`tThere are no authorised applications
"
}
else {
$Finalreport += "`t`There are $($apps.count) global applications as follows:
"
Foreach($app in $apps){
$Finalreport += "`t`t$($app.name) `t$($app.port)
"
}
}

# Display authorised services
$services = $profile.services
#
if (!$services) {
$Finalreport += "`t`tThere are no authorised services
"
}
else {
$Finalreport += "`tThere are $($services.count) authorised services as follows:
"
Foreach($service in $services){
$Finalreport += "`t`t$($service.name) `t$($service.port)
"
}
} 
$Finalreport += @"
Shares
"@
Foreach ($objShare in $colShares)
	{
$Finalreport += "
`tName:$($objShare.Name)`tPath:$($objShare.Path)`tCaption:$($objShare.Caption)
"
}
$Finalreport += "Pysical Drives"
Foreach ($objDisk in $colDisks)
{
    if ($objDisk.DriveType -eq 3)
		{
        $disksize = [math]::round(($objDisk.size / 1048576))
		$freespace = [math]::round(($objDisk.FreeSpace / 1048576))
		$percFreespace=[math]::round(((($objDisk.FreeSpace / 1048576)/($objDisk.Size / 1048676)) * 100),0)
$Finalreport += "
`tName: $($objDisk.DeviceID)`tFilesystem: $($objDisk.FileSystem)`tsize: $($disksize)MB
"
		}
}
$Finalreport += "Installed Software"
foreach ($objItem in $colItems) {
$Finalreport += "
`tName: $($objItem.Name)`tVersion: $($objItem.Version)
"
}
$Finalreport += "
Misc Config and Setup
`t
"
$Finalreport | out-file -encoding ASCII -filepath $path\$Target"autodoc".txt
}
