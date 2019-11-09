#requires -version 5.0
function Get-LatestRunner {
    <#
    .SYNOPSIS
        Download latest GitLab Runner from Nexus URL
    .DESCRIPTION
        This script downloads latest available GL Runner from Nexus
        and moves it to folder which has event observer on it.
        If a veto file is found on Nexus, then it will be used instead
    #>
    [cmdletbinding()]
    Param (
        [parameter()]
        [string]$target_dir = "C:\ALM\runner\bin",

        [parameter()]
        [string]$RunnerUrl,

        [parameter()]
        [string]$runner_version_tag = "gitlab-runner-windows.recent",

        [parameter()]
        [string]$veto_file = "gitlab-runner-windows-veto.recent"
    )

    $check_dirs = @("$target_dir", "$target_dir\runners")

    # event log source is standard across all VMs
    If (-not ([System.Diagnostics.EventLog]::SourceExists("GitLab Runner Observer"))) {
        New-EventLog -LogName Application -Source "GitLab Runner Observer"
    }

    If (-not ([System.Diagnostics.EventLog]::SourceExists("GitLab Runner Folder Observer"))) {
        New-EventLog -LogName Application -Source "GitLab Runner Folder Observer"
        Write-Output "Folder Observer for Task Manager has been registered"
    }

    foreach ($el in $check_dirs) {
        If ( -not(Test-Path -Path $el)) {
            New-Item -Path $el -ItemType "directory"
        }
    }

    # If a veto file has been uploaded, then this has a precedence over all other files used for
    # updating runners. Can be used for downgrading the runner.
    # We dont need the body of the file - HEAD method
    try {
        $msg = "Checking for veto $veto_file....."
        # $status_code cannot be used here because it is only assigned if Request has been successful
        $status_code = $(Invoke-WebRequest -UseBasicParsing "$RunnerUrl/$veto_file" -Method HEAD).StatusCode
    } catch {
        $msg = "A Veto file has not been found, thus continue with .recent file"
        Write-Output $msg
        Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1
    }

    if ($status_code -eq 200) {
        Write-Output  "$msg seems to be success: $status_code"
        Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1
        # success, hence veto becomes target version
        $runner_version_tag = $veto_file
        $msg = "A veto file has been FOUND, thus use version from the veto file"
        Write-Output $msg
        Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1
    }

    try {
        If (Test-Path -Path "$target_dir\$runner_version_tag") {
            $msg = "Old $runner_version_tag already exists and will be overwritten."
            Write-Output $msg
            Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1
            Remove-Item -Path "$target_dir\$runner_version_tag"
        }

        Invoke-WebRequest -UseBasicParsing "$RunnerUrl/$runner_version_tag" -OutFile "$target_dir\$runner_version_tag"
        $last_gitlab_runner = Get-Content -Path "$target_dir\$runner_version_tag"
        $current_RunnerUrl = "$RunnerUrl/$last_gitlab_runner"
        Invoke-WebRequest -UseBasicParsing "$current_RunnerUrl" -OutFile "$target_dir\runners\$last_gitlab_runner"
    }
    catch [System.Net.WebException] {
        $msg = "Files could not be downloaded successfully: $($_.Exception.Message)"
        Write-Output $msg
        Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1
        Write-Debug $_.Exception.Response
    }
    finally {
        Copy-Item -Path "$env:CI_PROJECT_DIR\runner\windows\bin\*.ps1" -Destination "$target_dir" -Force

        $msg = "`r`nNew GitLab Runner Version has been downloaded to: $target_dir\runners `
                Now moving important files to ALM\runner\bin folder
                "
        Write-Output $msg
        # do not change here "folder observer" - it is used for runner update
        Write-EventLog -LogName Application -Source "GitLab Runner Folder Observer" -Message $msg -EventId 1
    }

    ### Now there are 2 possibilities
    ## Solution one is to use Windows Service aka "runner service" which is registered as service
    ## and this script just calls the service
    ## Restart-Service -Name "Replace old GitLab Runner from Nexus"
    ###

    ## Another approach is to:
    # move file to a folder and from there event is triggered -> the chosen approach
}
