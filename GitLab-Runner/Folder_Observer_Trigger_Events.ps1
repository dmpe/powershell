#requires -version 5.0
Function Set-FolderSystemWatcher {
    <#
    .SYNOPSIS
        Set folder watcher for changes
    .DESCRIPTION
        Stolen and edited for our needs
    .LINK
        https://mcpmag.com/articles/2015/09/24/changes-to-a-folder-using-powershell.aspx
    #>
    [cmdletbinding()]
    Param (
        [parameter()]
        [string]$Path="C:\ALM\runner\bin\runners",

        [parameter()]
        [ValidateSet('Changed', 'Created', 'Deleted', 'Renamed')]
        [string[]]$EventName,

        [parameter()]
        [string]$Filter,
        [parameter()]

        [System.IO.NotifyFilters]$NotifyFilter,
        [parameter()]
        [switch]$Recurse,

        [parameter()]
        [scriptblock]$Action
    )

    $FileSystemWatcher = New-Object System.IO.FileSystemWatcher

    If (-NOT $PSBoundParameters.ContainsKey('Path')) {
        $Path = $PWD
    }

    $FileSystemWatcher.Path = $Path

    If ($PSBoundParameters.ContainsKey('Filter')) {
        $FileSystemWatcher.Filter = $Filter
    }

    If ($PSBoundParameters.ContainsKey('NotifyFilter')) {
        $FileSystemWatcher.NotifyFilter = $NotifyFilter
    }

    If ($PSBoundParameters.ContainsKey('Recurse')) {
        $FileSystemWatcher.IncludeSubdirectories = $True
    }

    If (-NOT $PSBoundParameters.ContainsKey('EventName')) {
        $EventName = 'Changed', 'Created', 'Deleted', 'Renamed'
    }

    If (-NOT $PSBoundParameters.ContainsKey('Action')) {
        $Action = {
            Switch ($Event.SourceEventArgs.ChangeType) {
                Default {
                    $Object = "{0} was {1} to {2} at {3}" -f $Event.SourceArgs[-1].OldFullPath,
                    $Event.SourceEventArgs.ChangeType,
                    $Event.SourceArgs[-1].FullPath,
                    $Event.TimeGenerated
                }
            }

            # $WriteHostParams = @{
            #     ForegroundColor = 'Green'
            #     BackgroundColor = 'Black'
            #     Object          = $Object
            # }
            # # On each event change, write to Windows Event Log
            # Write-Host  @WriteHostParams
            Write-Host  "Starting folder watcher"
            Write-EventLog -LogName Application -Source "GitLab Runner Folder Observer" `
                -Message $Object `
                -EventId 1
        }
    }

    $ObjectEventParams = @{
        InputObject = $FileSystemWatcher
        Action      = $Action
    }

    ForEach ($Item in  $EventName) {
        $ObjectEventParams.EventName = $Item
        $ObjectEventParams.SourceIdentifier = "File.$($Item)"
        Write-Host  "Starting watcher for Event: $($Item)"
        $Null = Register-ObjectEvent  @ObjectEventParams
    }
}
