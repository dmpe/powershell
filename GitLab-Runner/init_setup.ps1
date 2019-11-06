#requires -version 5.0

# This file prepares windows machine to run & update gitlab runners.
# It also setups the VM so that gitlab runners are updated from GitLab UI (e.g. through Scheduled Pipeline)
# This script requires that all other scripts are in the same folder, and run as ADMIN.
# The File should be run 1 time, manually, and be adjusted each for each command due to names.

Import-Module .\Register-GitLabRunner.ps1
Import-Module .\Register-FolderSystemWatcherTask.ps1
Import-Module .\Register-GitLabRunnerUpdateTask.ps1

# for testing
# Import-Module .\Set-FolderSystemWatcher.ps1
# Import-Module .\Update-OldRunner.ps1

# 1. Windows Service, for actual CI/CD, ALP GROUP INVITE
Register-GitLabRunner -UniqueId "runner-xxx-prototype" -RunnerName "gitlab-runner.exe" `
          -Site "https://gitlab/" -Shell "powershell" -Token " " `
          -tags "xxx-test" -logon "gitlab" -pswd " "

# This service is used for updating gitlab runner using a scheduled pipeline
# e.g. gitlab/project/pipeline_schedules
# 2. Windows Service for runner updating
Register-GitLabRunner -UniqueId "runner-xxx-update" -RunnerName "gitlab-runner.exe" `
          -Site "https://gitlab/" -Shell "powershell" -Token " " `
          -tags "xxx-update" -logon "gitlab" -pswd " "

# 3. Windows Tasks for folder watcher, and runner update.
Register-FolderSystemWatcherTask -Path "C:\ALM\runner\bin\Set-FolderSystemWatcher.ps1" `
          -Name "runner-xxx-folder-watcher-task"

Register-GitLabRunnerUpdateTask -Path "C:\ALM\runner\bin\Update-OldRunner.ps1" `
          -Name "runner-xxx-runner-update-task"

# for testing purposes
#Set-FolderSystemWatcher -Path "C:\ALM\runner\bin\runners"
#Update-OldRunner
