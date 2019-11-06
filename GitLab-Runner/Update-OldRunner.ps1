#requires -version 5.0

function StopExistingRunnerService {
    Get-Service -name "runner*" | Stop-Service -Verbose
}

function StartExistingRunnerService {
    Get-Service -name "runner*" | Start-Service -Verbose
}

function RenameGLRunerFile {
    dir $alm_path
    Remove-Item -Path "$alm_path\$runner_name"
    # move and rename
    Move-Item -Path "$alm_path\runners\$last_gitlab_runner" -Destination "$alm_path\$runner_name" -Force
}

function Update-OldRunner {
    <#
    .SYNOPSIS
        Replace current GitLab Runner exe with the newest one. Triggered by a Windows Task.
    .DESCRIPTION
        When the newest exe file is moved to the target directory, such an event is being logged in the Windows Event Log.
        Up the log ("Information"), this script is started and updates GitLab runner for all runner services.
    .LINK
        https://mcpmag.com/articles/2015/09/24/changes-to-a-folder-using-powershell.aspx
    #>
    [cmdletbinding()]
    Param (
        [parameter()]
        [string]$alm_path = "C:\ALM\runner\bin",

        [parameter()]
        [string]$runner_name = "gitlab-runner.exe",

        [parameter()]
        [string]$runner_version_tag = "gitlab-runner-windows.recent",

        [parameter()]
        [string]$veto_file = "gitlab-runner-windows-veto.recent"
    )

    Begin {
        $msg = "Replace GitLab Runner with the latest version from Nexus."
        Write-Host $msg
        Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1

        if (Test-Path -Path $alm_path\$veto_file) {
            $runner_version_tag = $veto_file
        }

        $last_gitlab_runner = Get-Content -Path $alm_path\$runner_version_tag
        # try {

        # }
        # catch {
        #     exit
        # }
    }

    Process {
        $msg = "Stopping now and replacing the .exe file."
        Write-Host $msg
        Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1

        StopExistingRunnerService
        # save zone
        Start-Sleep -Seconds 10 -Verbose
        RenameGLRunerFile
    }

    End {
        Start-Sleep -Seconds 10 -Verbose
        StartExistingRunnerService
        # save zone
        $msg = "Finished updating the runner - now in version $last_gitlab_runner"
        Write-Host $msg
        Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1
    }
}

# this executes the above function
Update-OldRunner
