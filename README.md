## Various PowerShell scripts

This repository contains various PowerShell scripts that have been developed over the time at my internships and jobs. 

#### Registering GitLab Runner on Windows Server OS



#### Removal of (remote) user profiles from Windows OS

Inspired & based on a variety of existing source code (see list below), I have developed GUI-based (`WinForms`) application that can simplify deleting user (remote) profiles on Windows OS. 

- [X] Capability of creating and reading `ini` file (to the folder where `ps1` is being executed)
- [X] Deleting only those profiles which have been selected by the user
- [X] Deleting all (remote) profiles
- [X] While internal `PowerShell` console-based logging as well as `WinForms` GUI is in English, a GUI-based logging in the textbox on the right is in German

![delete_user_profiles](images/delete_remote_user_profiles_gui.PNG)

##### Sources:

- https://community.spiceworks.com/how_to/124316-delete-user-profiles-with-powershell
- https://martin77s.wordpress.com/2018/02/14/remove-profiles-from-a-local-or-remote-computer/
- https://www.reddit.com/r/PowerShell/comments/9enay3/delete_user_profiles_remotely/
