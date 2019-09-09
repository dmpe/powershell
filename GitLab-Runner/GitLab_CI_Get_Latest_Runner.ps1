#requires -version 5.0

#######
## This script downloads latest available GL Runner from Nexus
## moves it to folder which has event observer on it.
## If a veto file is found on Nexus, then it will be used instead
#######
function Get-LatestRunner {

    [cmdletbinding()]
    Param (
        [parameter()]
        [string]$target_dir = "C:\ALM\runner\bin",

        [parameter()]
        [string]$runner_url,

        [parameter()]
        [string]$runner_version_tag = "gitlab-runner-windows.recent",

        [parameter()]
        [string]$veto_file = "gitlab-runner-windows-veto.recent"
    )

    $check_dirs = @("$target_dir", "$target_dir\runners")

    # event log source is standart accross all VMs
    If (-not ([System.Diagnostics.EventLog]::SourceExists("GitLab Runner Observer"))) {
        New-EventLog -LogName Application -Source "GitLab Runner Observer"
    }

    foreach ($el in $check_dirs) {
        If ( -not(Test-Path -Path $el)) {
            New-Item -Path $el -ItemType "directory"
        }
    }

    # if a veto file has been uploaded, then this has a precedence over all other files used for
    # updating runners. Can be used for downgrading the runner.
    try {
        # we dont need the body of the file, hence just HEAD method
        $status_code = $(Invoke-WebRequest "$runner_url/$veto_file" -Method HEAD).StatusCode
    }
    catch {
        # $status_code cannot be used here because it is only assigned if Request has been successfull
        if ($_.Exception.Response.StatusCode.value__ -ne 200) {
            $msg = "A Veto file has not been found, thus contrinue with .recent file"
            Write-Host $msg
            Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1
        }
        else {
            # success, hence veto becomes target version
            $runner_version_tag = $veto_file
        }
    }

    try {
        If (Test-Path -Path "$target_dir\$runner_version_tag") {
            $msg = "Old $runner_version_tag already exists and thus will be overwritten."
            Write-Host $msg
            Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1
            Remove-Item -Path "$target_dir\$runner_version_tag"
        }

        Invoke-WebRequest "$runner_url/$runner_version_tag" -OutFile "$target_dir\$runner_version_tag"
        $last_gitlab_runner = Get-Content -Path "$target_dir\$runner_version_tag"
        $current_runner_url = "$runner_url/$last_gitlab_runner"
        Invoke-WebRequest "$current_runner_url" -OutFile "$target_dir\runners\$last_gitlab_runner"
    }
    catch [System.Net.WebException] {
        $msg = "Files could not be downloaded successfully: $($_.Exception.Message)"
        Write-Host $msg
        Write-EventLog -LogName Application -Source "GitLab Runner Observer" -Message $msg -EventId 1
        Write-Debug $_.Exception.Response
    }
    finally {
        $msg = "New GitLab Runner Version has been downloaded: $last_gitlab_runner"
        Write-Host $msg
        Write-EventLog -LogName "Application" -Source "GitLab Runner Observer" -Message $msg -EntryType "Information" -EventId 1
    }

    ### Now there are 2 possibilities
    ## Solution one is to use Windows Service akakrunner service which is registered as service
    ## and this script just calls the service
    ## Start-Service -Name "Replace old GitLab Runner from Nexus"
    ###

    ## Another approach is to:
    # move file to a folder and from there event is triggered -> the chosen approach
}
