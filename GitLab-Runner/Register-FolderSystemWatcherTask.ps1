#requires -version 5.0

Function Register-FolderSystemWatcherTask {
    <#
    .SYNOPSIS
        Register Windows task for folder watcher, e.g. upon system boot
    .DESCRIPTION
        Register Windows task which watches for folder changes, e.g. delete/adding exe files.
    #>
    [cmdletbinding()]
    Param (
        [parameter()]
        [string]$Path,

        [parameter()]
        [string]$Name,

        [parameter()]
        [string]$Command,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline=$true,
            HelpMessage = "Enter a user login (of Windows Server)")]
            [alias("login", "username")]
            [String]$Logon="NT AUTHORITY\SYSTEM",

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline=$true,
            HelpMessage = "Enter a user password (of Windows Server)")]
            [alias("password", "pswd")]
            [String]$Passwd
    )

    $Trigger= New-ScheduledTaskTrigger -AtStartup
    $User= "$login"
    $Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File $Path"
    Register-ScheduledTask -Description "Used for checking exe file and updating GL Runner" `
        -TaskName "$Name" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
}
