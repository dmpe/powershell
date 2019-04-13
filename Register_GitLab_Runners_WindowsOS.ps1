#requires -version 5.0

Function Register-GitLabRunner {
<#
.SYNOPSIS
    This "advanced PowerShell function" registers GitLab Runner (GR) on Windows Server 
    and connects it with a targeted GitLab instance.

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
    The parameter Site (a complete URL) is used to define a targeted GitLab instance which GR will 
    want to associate with.
    Usually (at least in corporate environments) there are test/integration/production versions of 
    GitLab. Thus, GR must be associated with only 1 GitLab instances. 
    If you need to have multiple runners connected with several GitLab instances, execute script 
    n times.
    Example 1: https://site.companyName.com/gitlab
    Example 2: https://gitlab-prod.companyName.com

.PARAMETER Token
    The parameter Token is used to authenticate with a targeted GitLab instance. 
    This can be found in your project's or group's settings.
    Example: https://gitlab.com/dmpe/YOUR_project_NAME/settings/ci_cd

.PARAMETER Domain
    The parameter Domain is used to define the name of Active Directory of the Logon user. 
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


.PARAMETER Base
    The parameter Base equals to the location "c:/ALM/runner" 
    TODO: of this PS1 file in the file system (= $PSScriptRoot).

.PARAMETER RunnerName
    The parameter RunnerName is a name of the gitlab runner exe file
    Example: gitlab-runner-windows-amd64.exe (by default here)
    Example: gitlab-runner.exe
    

.LINK
    https://docs.gitlab.com/runner/shells/
    https://docs.gitlab.com/runner/executors/
    https://docs.gitlab.com/runner/executors/README.html#compatibility-chart
    https://github.com/dmpe/ 

.EXAMPLE
    # The example below registers 1 GitLab Runner on Windows Server. This was executed with Admin rights.
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
            ValueFromPipeline=$true, #  Accept values via the pipeline.
            HelpMessage = "The unique_id, also named scope, is a unique identifier which " + 
            "describes GitLab Runner in the system.")]
            # attributes
            [alias("scope")]
            [ValidateNotNullOrEmpty()]
            [String]$UniqueId,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline=$true,
            HelpMessage = "Enter 1 GitLab site URL")]
            [alias("url")]
            [ValidateNotNullOrEmpty()]
            [String]$Site,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a group/project Token")]
            [alias("RegToken")]
            [ValidateNotNullOrEmpty()]
            [String]$Token,

        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a name of your Active Directory")]
            [String]$Domain,
        
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a user login (of Windows Server)")]
            [alias("login", "username")]
            [ValidateNotNullOrEmpty()]
            [String]$Logon,
        
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a user password (of Windows Server)")]
            [alias("password", "pswd")]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Passwd = [System.Management.Automation.PSCredential]::Empty,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter tag(s) which identify your GR")]
            [alias("tag")]
            [ValidateNotNullOrEmpty()]
            [String[]]$Tags,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a type of an executor - shell by default")]
            [alias("exec")]
            [ValidateNotNullOrEmpty()]
            [String]$Executor = "shell",

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline=$true, 
            HelpMessage = "Enter a type of a shell: 'cmd' by default or 'powershell' ")]
            [ValidateNotNullOrEmpty()]
            [String]$Shell = "cmd", 

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline=$true, 
            HelpMessage = "Starting location of GitLab Runner")]
            [alias("location", "base_loc")]
            [ValidateNotNullOrEmpty()]
            [String]$Base = "c:\ALM\runner",
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline=$true, 
            HelpMessage = "Name of GitLab Runner .exe file")]
            [ValidateNotNullOrEmpty()]
            [String]$RunnerName = "gitlab-runner-windows-amd64.exe"
            
    )

    Begin {

        Write-Host ""
        Write-Host "Debug Information"  -ForegroundColor Yellow
        Write-Host ""
        Write-Host ""

        $FunctionName = $PSCmdlet.MyInvocation.InvocationName
        $ParameterList = (Get-Command -Name $FunctionName).Parameters
        foreach ($param in $ParameterList) {
            # print passed parameters
            Get-Variable -Name $param.Values.Name -ErrorAction SilentlyContinue
        }

        Write-Host ""
        Write-Host "1. Step: Set right location for GitLab Runner"  -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This PowerShell function is executed in $PSScriptRoot" -ForegroundColor DarkYellow

        $var = 'd:\ALM\var\runner'

        if ( -not (Test-Path $var)) {
           $var = "c:\ALM\var\runner"
        } 
        Write-Host "Following directory is used for GitLab Runner: $var" -ForegroundColor DarkYellow

    }

    Process {
        Write-Host ""
        Write-Host "2. Step: Try to unregister, shutdown and uninstall existing runner and service."  -ForegroundColor Yellow
        Write-Host ""

        $config_toml = "$Base\etc\$UniqueId.toml"
        Write-Host "Configuration TOML file is: " $config_toml -ForegroundColor DarkYellow

        $builds_location = $var + "$UniqueId\build"
        Write-Host "Location of build artefacts: " $builds_location -ForegroundColor DarkYellow

        $hostname = $env:computername
        $runner_name = $UniqueId + "@" + $hostname
        Write-Host "Name of runner to unregister: " $runner_name -ForegroundColor DarkYellow
        Write-Host ""
        Write-Host ""
        # For testing
        # & $Base\$RunnerName --help 

        # & $Base\$RunnerName stop --service $UniqueId
        # & $Base\$RunnerName unregister --config $config_toml --name $runner_name --url $Site
        # & $Base\$RunnerName uninstall --service $UniqueId

        Write-Host "" 
        Write-Host "3. Step: Setup Win32 service $UniqueId" -ForegroundColor Yellow
        Write-Host ""
        
        #& $Base\$RunnerName install --config $config_toml --service $UniqueId --working-directory "$var\$UniqueId" --user "$domain\\$logon" --password "$Passwd"
        Write-Host "GitLab Runner has been successfully installed!" -ForegroundColor DarkYellow

        Write-Host "" 
        Write-Host "4. Step: Register runner $runner_name at $Site .." -ForegroundColor Yellow
        Write-Host ""

        if ( -not (Test-Path $builds_location)) {
            # New-Item -Path $builds_location -ItemType Directory -ErrorAction SilentlyContinue
            Write-Host "$builds_location has been created!"
        }
        
        # use splatting here - instead of ` char
        # need for using GR short names (of parameters)
        $params = @{ 'c' = $config_toml
                     'u' = $Site
                     'r' = $Token
                   }
        
        # worst offense
        # https://poshcode.gitbooks.io/powershell-practice-and-style/Style-Guide/Readability.html
        Write-Host @params --non-interactive --name $runner_name --executor $executor --shell $shell --builds-dir $builds_location --tag-list $tags --locked $false
        #& $Base\$RunnerName register @params --non-interactive --name $runner_name --executor $executor --shell $shell --builds-dir $builds_location --tag-list $tags --locked $false
        #& $Base\$RunnerName register --non-interactive --name $runner_name --executor $executor --shell $shell --builds-dir $builds_location --tag-list $tags --locked $false -c $config_toml -u $Site -r $Token
        Write-Host "GitLab Runner has been successfully registered!" -ForegroundColor DarkYellow
    }

    End {
        Try {
            Write-Host $ErrorActionPreference -ForegroundColor Yellow
            $ErrorActionPreference = "Stop"; # Make all errors terminating
            #& $Base\$RunnerName start --config $config_toml --name $runner_name --url $Site
             Write-Host "GitLab Runner has been successfully started!" -ForegroundColor Red
        } Catch {
            Write-Host "Caught the exception" -ForegroundColor Red
            Write-Host $Error[0].Exception 
        }
        
    }


}



Register-GitLabRunner -UniqueId "UniqueIDofRunner" -Logon "username" -Site "https://alp.gitlab.com/gitlab"  -Token "asfasfasf" -Domain "MET" -tags "domain,pages"


