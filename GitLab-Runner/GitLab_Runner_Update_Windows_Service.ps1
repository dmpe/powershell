#requires -version 5.0

### This runner is triggered by logging in the Windows Event Log and it updates GitLab runner.

function StopExistingRunnerService {
    Get-Service -name "runner*" | Stop-Service -Verbose
}

function StartExistingRunnerService {
    Get-Service -name "runner*" | Start-Service -Verbose
}

function RenameGLRunerFile{
    dir $alm_path
    Remove-Item -Path "$alm_path\$runner_name"
    # move and rename
    Move-Item -Path "$alm_path\runners\$last_gitlab_runner" -Destination "$alm_path\$runner_name" -Force
}

function ReplaceOldRunner {
    [cmdletbinding()]
    Param (
        [parameter()]
        [string]$alm_path = "C:\ALM\runner\bin",

        [parameter()]
        [string]$runner_name = "gitlab-runner.exe",

        [parameter()]
        [string]$runner_version_tag = "gitlab-runner-windows.recent"
    )

    Begin {
        $msg = "Replace GitLab Runner with the latest version from Nexus."
        Write-Host $msg
        Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1

        try {
            $last_gitlab_runner = Get-Content -Path $alm_path\$runner_version_tag
        } catch {
            exit
        }
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

ReplaceOldRunner
