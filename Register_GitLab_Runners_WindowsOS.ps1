

Function Register-GitLabRunner {
<#
.SYNOPSIS
    This "advanced PowerShell function" registers and connects GitLab Runner, abbreviated here 
    as GR, on Windows Server OS with a targeted GitLab instance.

.DESCRIPTION
    This script is used for registering GR on Windows Server OS. 
    It MUST be executed with "Admin" permissions!
    It has been tested only on Windows Server >= 2016.

.PARAMETER UniqueId
    The parameter UniqueId is used to define a unique identifier for the GR.
    In GitLab UI, this is called runner's "description".
    The parameter cannot be empty string or be $null.
    Example: gitlab-runner-for-docker-container

.PARAMETER Site
    The parameter Site (complete URL) is used to define a targeted GitLab instance which GR will 
    want to associate with.
    Usually (at least in corporate environments) there are test/integration/production versions of 
    GitLab. 
    Thus, GR must be associated with only 1 GitLab instances. 
    If you need to have multiple runners connected with several GitLab instances, execute script 
    n times.
    Example 1: https://site.companyName.com/gitlab
    Example 2: https://gitlab-prod.companyName.com

.PARAMETER Token
    The parameter Token is used to authenticate with a targeted GitLab instance. 
    This can be found in your project's or group's settings.
    Example: https://gitlab.com/dmpe/YOUR_project_NAME/settings/ci_cd

.PARAMETER Domain
    The parameter Domain is used to define Active Directory of the Logon user. 
    Example: MSFT

.PARAMETER Logon
    The parameter Logon is a user account which is used for registering GR in the system. 

.PARAMETER Passwd
    The parameter Passwd is a user password (of the Logon user).

.PARAMETER Tags
    The parameter Tags is used to define a targeted GitLab Runner. It can be separated by 
    the commas, e.g. "matrix42" or "docker,pages".

.PARAMETER Executor
    The parameter Executor (i.e. GR) "implements a number of executors that can be used to run your 
    builds in different scenarios" [%RUNNER_EXECUTOR%]
    If shell (which is also default option here), then on Windows Batch (cmd) by default as well. 

    Example: shell, docker, ssh, kubernetes, etc. 
    https://docs.gitlab.com/runner/executors/

.PARAMETER Shell
    The parameter Shell "allows you to execute builds locally to the machine that the Runner 
    is installed". 

    Example: "cmd" (Batch/CMD by default for Windows OS)
             alternatively: "powershell"
    https://docs.gitlab.com/runner/shells/

.LINK
    https://docs.gitlab.com/runner/shells/
    https://docs.gitlab.com/runner/executors/
    https://docs.gitlab.com/runner/executors/README.html#compatibility-chart
    https://github.com/dmpe/ 

.EXAMPLE
    The example below registers 1 GitLab Runner on Windows Server. 
    This was executed with Admin rights.
    PS C:\WINDOWS\system32> Register-GitLabRunner 
    
.NOTES
    Author: https://github.com/dmpe/ 
    Last Edit/Version: See Git Repo
    Style Guide: https://poshcode.gitbooks.io/powershell-practice-and-style/
#>


    # Here we defined a block of parameters which also have 
    # their own attributes and parameter arguments.
    # String[] = multiple parameters, String = just 1

    # This adds cmdlet features to the function: common parameters (-verbose, -whatif, -confirm, etc.)
    [CmdletBinding()]
    Param (
        [Parameter(
            # arguments
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline=$true, #  Accept values via the pipeline.
            HelpMessage = "The unique_id, also named scope, is a unique identifier which " + 
            "describes GitLab Runner in the system.")]
            # attributes
            [alias("scope", "Scope")]
            [ValidateNotNullOrEmpty()]
            [String]$UniqueId,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline=$true,
            HelpMessage = "Enter 1 GitLab site URL")]
            [alias("url", "URL")]
            [ValidateNotNullOrEmpty()]
            [String$Site,

        [Parameter(
            Mandatory = $true,
            Position = 2,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a group/project Token")]
            [alias("token")]
            [ValidateNotNullOrEmpty()]
            [String]$Token,

        [Parameter(
            Mandatory = $false, 
            Position = 3,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a name of your Active Directory")]
            [String[]]$Domain,
        
        [Parameter(
            Mandatory = $true,
            Position = 4,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a user login (of Windows Server)")]
            [alias("login", "logon", "username")]
            [ValidateNotNullOrEmpty()]
            [String]$Logon,
        
        [Parameter(
            Mandatory = $true,
            Position = 5,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a user password (of Windows Server)")]
            [alias("password", "pswd")]
            [ValidateNotNullOrEmpty()]
            [String]$Passwd,

        [Parameter(
            Mandatory = $true,
            Position = 6,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter tag(s) which identify your GR")]
            [alias("tag", "tags")]
            [ValidateNotNullOrEmpty()]
            [String[]]$Tags,
        
        [Parameter(
            Mandatory = $true,
            Position = 5,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a executor - shell by default")]
            [alias("exec", "executor")]
            [ValidateNotNullOrEmpty()]
            [String]$Executor = shell,

        [Parameter(
            Mandatory = $true,
            Position = 7,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a shell: 'cmd' by default or 'powershell' ")]
            [alias("shell")]
            [ValidateNotNullOrEmpty()]
            [String]$Shell = cmd,


    )

    Begin {

    }

    Process {

    }

    End {

    }


}

