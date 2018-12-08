###################
###################
######### Copied from https://www.powershellgallery.com/packages/PsIni/2.0.5/Content/Functions%5COut-IniFile.ps1
#########
###################
###################

#Set-StrictMode -Version Latest
Function Out-IniFile {
    <# 
    .Synopsis 
        Write hash content to INI file 
 
    .Description 
        Write hash content to INI file 
 
    .Notes 
        Author : Oliver Lipkau <oliver@lipkau.net> 
        Blog : http://oliver.lipkau.net/blog/ 
        Source : https://github.com/lipkau/PsIni 
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
 
        #Requires -Version 2.0 
 
    .Inputs 
        System.String 
        System.Collections.IDictionary 
 
    .Outputs 
        System.IO.FileSystemInfo 
 
    .Example 
        Out-IniFile $IniVar "C:\myinifile.ini" 
        ----------- 
        Description 
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini 
 
    .Example 
        $IniVar | Out-IniFile "C:\myinifile.ini" -Force 
        ----------- 
        Description 
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present 
 
    .Example 
        $file = Out-IniFile $IniVar "C:\myinifile.ini" -PassThru 
        ----------- 
        Description 
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file 
 
    .Example 
        $Category1 = @{“Key1”=”Value1”;”Key2”=”Value2”} 
        $Category2 = @{“Key1”=”Value1”;”Key2”=”Value2”} 
        $NewINIContent = @{“Category1”=$Category1;”Category2”=$Category2} 
        Out-IniFile -InputObject $NewINIContent -FilePath "C:\MyNewFile.ini" 
        ----------- 
        Description 
        Creating a custom Hashtable and saving it to C:\MyNewFile.ini 
    .Link 
        Get-IniContent 
    #>

    [CmdletBinding()]
    [OutputType(
        [System.IO.FileSystemInfo]
    )]
    Param(
        # Adds the output to the end of an existing file, instead of replacing the file contents.
        [switch]
        $Append,

        # Specifies the file encoding. The default is UTF8.
        #
        # Valid values are:
        # -- ASCII: Uses the encoding for the ASCII (7-bit) character set.
        # -- BigEndianUnicode: Encodes in UTF-16 format using the big-endian byte order.
        # -- Byte: Encodes a set of characters into a sequence of bytes.
        # -- String: Uses the encoding type for a string.
        # -- Unicode: Encodes in UTF-16 format using the little-endian byte order.
        # -- UTF7: Encodes in UTF-7 format.
        # -- UTF8: Encodes in UTF-8 format.
        [ValidateSet("Unicode", "UTF7", "UTF8", "ASCII", "BigEndianUnicode", "Byte", "String")]
        [Parameter()]
        [String]
        $Encoding = "UTF8",

        # Specifies the path to the output file.
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {Test-Path $_ -IsValid} )]
        [Parameter( Position = 0, Mandatory = $true )]
        [String]
        $FilePath,

        # Allows the cmdlet to overwrite an existing read-only file. Even using the Force parameter, the cmdlet cannot override security restrictions.
        [Switch]
        $Force,

        # Specifies the Hashtable to be written to the file. Enter a variable that contains the objects or type a command or expression that gets the objects.
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        [System.Collections.IDictionary]
        $InputObject,

        # Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.
        [Switch]
        $Passthru,

        # Adds spaces around the equal sign when writing the key = value
        [Switch]
        $Loose,

        # Writes the file as "pretty" as possible
        #
        # Adds an extra linebreak between Sections
        [Switch]
        $Pretty
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        function Out-Keys {
            param(
                [ValidateNotNullOrEmpty()]
                [Parameter( Mandatory, ValueFromPipeline )]
                [System.Collections.IDictionary]
                $InputObject,

                [ValidateSet("Unicode", "UTF7", "UTF8", "ASCII", "BigEndianUnicode", "Byte", "String")]
                [Parameter( Mandatory )]
                [string]
                $Encoding = "UTF8",

                [ValidateNotNullOrEmpty()]
                [ValidateScript( {Test-Path $_ -IsValid})]
                [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
                [string]
                $Path,

                [Parameter( Mandatory )]
                $Delimiter,

                [Parameter( Mandatory )]
                $MyInvocation
            )

            Process {
                if (!($InputObject.get_keys())) {
                    Write-Warning ("No data found in '{0}'." -f $FilePath)
                }
                Foreach ($key in $InputObject.get_keys()) {
                    if ($key -match "^Comment\d+") {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $key"
                        Add-Content -Value "$($InputObject[$key])" -Encoding $Encoding -Path $Path
                    }
                    else {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $key"
                        Add-Content -Value "$key$delimiter$($InputObject[$key])" -Encoding $Encoding -Path $Path
                    }
                }
            }
        }

        $delimiter = '='
        if ($Loose) {
            $delimiter = ' = '
        }

        # Splatting Parameters
        $parameters = @{
            Encoding = $Encoding;
            Path     = $FilePath
        }

    }

    Process {
        $extraLF = ""

        if ($Append) {
            Write-Debug ("Appending to '{0}'." -f $FilePath)
            $outfile = Get-Item $FilePath
        }
        else {
            Write-Debug ("Creating new file '{0}'." -f $FilePath)
            $outFile = New-Item -ItemType file -Path $Filepath -Force:$Force
        }

        if (!(Test-Path $outFile.FullName)) {Throw "Could not create File"}

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"
        foreach ($i in $InputObject.get_keys()) {
            if (!($InputObject[$i].GetType().GetInterface('IDictionary'))) {
                #Key value pair
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"
                Add-Content -Value "$i$delimiter$($InputObject[$i])" @parameters

            }
            elseif ($i -eq $script:NoSection) {
                #Key value pair of NoSection
                Out-Keys $InputObject[$i] `
                    @parameters `
                    -Delimiter $delimiter `
                    -MyInvocation $MyInvocation
            }
            else {
                #Sections
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"

                # Only write section, if it is not a dummy ($script:NoSection)
                if ($i -ne $script:NoSection) { Add-Content -Value "$extraLF[$i]" @parameters }
                if ($Pretty) {
                    $extraLF = "`r`n"
                }

                if ( $InputObject[$i].Count) {
                    Out-Keys $InputObject[$i] `
                        @parameters `
                        -Delimiter $delimiter `
                        -MyInvocation $MyInvocation
                }

            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $FilePath"
    }

    End {
        if ($PassThru) {
            Write-Debug ("Returning file due to PassThru argument.")
            Write-Output (Get-Item $outFile)
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias oif Out-IniFile

#####################################
#####################################
#############
############# 
############# This code is copied from
############# https://www.powershellgallery.com/packages/PsIni/1.2.0/Content/Functions%5CGet-IniContent.ps1
#############
#############
#####################################
#Set-StrictMode -Version Latest
Function Get-IniContent {
    <#
    .Synopsis
        Gets the content of an INI file

    .Description
        Gets the content of an INI file and returns it as a hashtable

    .Notes
        Author        : Oliver Lipkau <oliver@lipkau.net>
  Source        : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version        : 1.0.0 - 2010/03/12 - OL - Initial release
                      1.0.1 - 2014/12/11 - OL - Typo (Thx SLDR)
                                              Typo (Thx Dave Stiff)
                      1.0.2 - 2015/06/06 - OL - Improvment to switch (Thx Tallandtree)
                      1.0.3 - 2015/06/18 - OL - Migrate to semantic versioning (GitHub issue#4)
                      1.0.4 - 2015/06/18 - OL - Remove check for .ini extension (GitHub Issue#6)
                      1.1.0 - 2015/07/14 - CB - Improve round-tripping and be a bit more liberal (GitHub Pull #7)
                                           OL - Small Improvments and cleanup
                      1.1.1 - 2015/07/14 - CB - changed .outputs section to be OrderedDictionary
                      1.1.2 - 2016/08/18 - SS - Add some more verbose outputs as the ini is parsed,
                                      allow non-existent paths for new ini handling,
                                      test for variable existence using local scope,
                                      added additional debug output.

        #Requires -Version 2.0

    .Inputs
        System.String

    .Outputs
        System.Collections.Specialized.OrderedDictionary

    .Parameter FilePath
        Specifies the path to the input file.

    .Parameter CommentChar
        Specify what characters should be describe a comment.
        Lines starting with the characters provided will be rendered as comments.
        Default: ";"

    .Parameter IgnoreComments
        Remove lines determined to be comments from the resulting dictionary.

    .Example
        $FileContent = Get-IniContent "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent

    .Example
        $inifilepath | $FileContent = Get-IniContent
        -----------
        Description
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent

    .Example
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"
        C:\PS>$FileContent["Section"]["Key"]
        -----------
        Description
        Returns the key "Key" of the section "Section" from the C:\settings.ini file

    .Link
        Out-IniFile
    #>

    [CmdletBinding()]
    [OutputType(
        [System.Collections.Specialized.OrderedDictionary]
    )]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$FilePath,
        [char[]]$CommentChar = @(";"),
        [switch]$IgnoreComments
    )

    Begin
    {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) { $DebugPreference = 'Continue' }
        Write-Debug "DebugPreference: $DebugPreference"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $commentRegex = "^([$($CommentChar -join '')].*)$"
        Write-Debug ("commentRegex is {0}." -f $commentRegex)
    }

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"

        $ini = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)

        if (!(Test-Path $Filepath))
        {
            Write-Verbose ("Warning: `"{0}`" was not found." -f $Filepath)
            return $ini
        }

        $commentCount = 0
        switch -regex -file $FilePath
        {
            "^\s*\[(.+)\]\s*$" # Section
            {
                $section = $matches[1]
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding section : $section"
                $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                $CommentCount = 0
                continue
            }
            $commentRegex # Comment
            {
                if (!$IgnoreComments)
                {
                    if (!(test-path "variable:local:section"))
                    {
                        $section = $script:NoSection
                        $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    }
                    $value = $matches[1]
                    $CommentCount++
                    Write-Debug ("Incremented CommentCount is now {0}." -f $CommentCount)
                    $name = "Comment" + $CommentCount
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding $name with value: $value"
                    $ini[$section][$name] = $value
                }
                else { Write-Debug ("Ignoring comment {0}." -f $matches[1]) }

                continue
            }
            "(.+?)\s*=\s*(.*)" # Key
            {
                if (!(test-path "variable:local:section"))
                {
                    $section = $script:NoSection
                    $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                }
                $name,$value = $matches[1..2]
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding key $name with value: $value"
                $ini[$section][$name] = $value
                continue
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
        Return $ini
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Set-Alias gic Get-IniContent

###############################################
#########################
#########################
######################### 
######################### Here begins the main program
#########################
#########################
#########################
###############################################


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

##################
# Documentation and other URL links
# https://learn-powershell.net/2012/12/08/powershell-and-wpf-listbox-part-2datatriggers-and-observablecollection/
# https://stackoverflow.com/a/13353589
# https://blogs.technet.microsoft.com/stephap/2012/04/23/building-forms-with-powershell-part-1-the-form/
# https://blogs.technet.microsoft.com/heyscriptingguy/2012/01/15/use-powershell-to-choose-unique-objects-from-a-sorted-list/
##################

$Icon                            = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$ini_configuration_file          = "user_config.ini"

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '720,500' # w -> h
$Form.text                       = "Removal of remote user profiles (UP)"
$Form.TopMost                    = $false
$Form.AutoSize                   = $True
$Form.Icon                       = $Icon
$Form.startposition              = "centerscreen"


# Define Colors
# Hex F1CA95, F1CAAC <> Adobe Color CC
$color1 = [System.Drawing.Color]::FromArgb(241,202,172)
$color2 = [System.Drawing.Color]::FromArgb(210,191,172)
#############################################################################

# Define Tooltips
$Tooltip = New-Object System.Windows.Forms.ToolTip 
$ShowHelp = { 
    Switch ($this.name) { 
        'TextBox1'  {$Tip = "Remote PC/Server name/IP"; Break} 
        'TextBox2'  {$Tip = 'Remove UPs that were not used for more than XXX days (Optional)'; Break} 
        'UserToSid' {$Tip = 'Type valid user SID'; Break} 
    } 
    $Tooltip.SetToolTip($this,$Tip) 
} 
################################################################################

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.Name                   = 'TextBox1'
$TextBox1.width                  = 230
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point (7, 10)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'
$TextBox1.Text                   = "Remote PC/Server name/IP"
# $TextBox1.ForeColor            = 'Darkgray'
$TextBox1.add_MouseHover($ShowHelp) 

######################################################################################
############## 
############## older then x days components
##############

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline              = $false
$TextBox2.width                  = 230
$TextBox2.Name                   = 'TextBox2'
$TextBox2.height                 = 20
$TextBox2.location               = New-Object System.Drawing.Point(7,170)
$TextBox2.Font                   = 'Microsoft Sans Serif,10'
$TextBox2.Text                   = "Older than >= XXX days"
$TextBox2.ForeColor              = 'Darkgray'
$TextBox2.add_MouseHover($ShowHelp) 

############## 
############## Outcome Box used for logging
##############

$TextBox3                        = New-Object system.Windows.Forms.TextBox
$TextBox3.multiline              = $true
$TextBox3.AcceptsReturn          = $true;
$TextBox3.width                  = 300
$TextBox3.height                 = 200
$TextBox3.location               = New-Object System.Drawing.Point(380,10)
$TextBox3.Font                   = 'Microsoft Sans Serif,10'
$TextBox3.ReadOnly               = $true
# $TextBox3.Text                 = "`r`n" 

##########################################################################################
#################          ADD + DELETE + DELETE ALL Button
###################################
$ReadINI                    = New-Object System.Windows.Forms.Button 
$ReadINI.Location           = New-Object System.Drawing.Point(245,10) 
$ReadINI.width              = 100
$ReadINI.height             = 25
$ReadINI.Text               = ".ini read" 
$ReadINI.Font               = 'Microsoft Sans Serif,10'

$WriteINI                    = New-Object System.Windows.Forms.Button 
$WriteINI.Location           = New-Object System.Drawing.Point(245,40) 
$WriteINI.width              = 100
$WriteINI.height             = 25
$WriteINI.Text               = ".ini write" 
$WriteINI.Font               = 'Microsoft Sans Serif,10'

$ButtonAdd                         = New-Object system.Windows.Forms.Button
$ButtonAdd.text                    = "Add"
$ButtonAdd.width                   = 100
$ButtonAdd.height                  = 35
$ButtonAdd.location                = New-Object System.Drawing.Point(245,80)
$ButtonAdd.Font                    = 'Microsoft Sans Serif,10'

$ButtonRemove                    = New-Object System.Windows.Forms.Button 
$ButtonRemove.Location           = New-Object System.Drawing.Point(245,120) 
$ButtonRemove.width              = 100
$ButtonRemove.height             = 35
$ButtonRemove.Text               = "Delete" 
$ButtonRemove.Font               = 'Microsoft Sans Serif,10'

$ButtonDeleteAll                    = New-Object System.Windows.Forms.Button 
$ButtonDeleteAll.Location           = New-Object System.Drawing.Point(245,160) 
$ButtonDeleteAll.width              = 100
$ButtonDeleteAll.height             = 35
$ButtonDeleteAll.Text               = "Delete all" 
$ButtonDeleteAll.Font               = 'Microsoft Sans Serif,10'

$ListBoxComputerNames                       = New-Object system.Windows.Forms.ListBox
$ListBoxComputerNames.name                  = "ListBoxComputerNames"
$ListBoxComputerNames.width                 = 230
$ListBoxComputerNames.height                = 100
$ListBoxComputerNames.location              = New-Object System.Drawing.Point(7,40)
$ListBoxComputerNames.SelectionMode         = "MultiExtended" 

$Panel1                          = New-Object system.Windows.Forms.Panel
$Panel1.height                   = 220
$Panel1.width                    = 690
$Panel1.location                 = New-Object System.Drawing.Point(15,15)
$Panel1.BackColor                = "White"
$Panel1.BorderStyle              = "FixedSingle"


$Form.controls.Add($Panel1)
$Panel1.Controls.AddRange(@($TextBox1, $TextBox2, $TextBox3, $ReadINI, $WriteINI, $ButtonAdd, $ButtonRemove, $ButtonDeleteAll, $ListBoxComputerNames));
###########################################################################################
#----------------PANEL 1 CLOSE HERE -----------------
#-----------------------------------------
















#----------------PANEL 2 BEGINS HERE -----------------
#-----------------------------------------
###########################################################################################
$ListView1                       = New-Object system.Windows.Forms.ListBox
$ListView1.width                 = 400
$ListView1.height                = 190
$ListView1.location              = New-Object System.Drawing.Point(300,260)
$ListView1.SelectionMode         = "MultiExtended" 

$ButtonGET                         = New-Object system.Windows.Forms.Button
$ButtonGET.text                    = "Get user profiles"
$ButtonGET.width                   = 180
$ButtonGET.height                  = 35
$ButtonGET.location                = New-Object System.Drawing.Point(20,300)
$ButtonGET.Font                    = 'Microsoft Sans Serif,10'

$ButtonDeleteProfiles                         = New-Object system.Windows.Forms.Button
$ButtonDeleteProfiles.text                    = "Delete selected UPs"
$ButtonDeleteProfiles.width                   = 180
$ButtonDeleteProfiles.height                  = 35
$ButtonDeleteProfiles.location                = New-Object System.Drawing.Point(20,350)
$ButtonDeleteProfiles.Font                    = 'Microsoft Sans Serif,10'
$ButtonDeleteProfiles.ForeColor               = "Black"
$ButtonDeleteProfiles.Enabled                 = $false

$ButtonDeleteALLProfiles                         = New-Object system.Windows.Forms.Button
$ButtonDeleteALLProfiles.text                    = "Delete all UPs"
$ButtonDeleteALLProfiles.width                   = 180
$ButtonDeleteALLProfiles.height                  = 35
$ButtonDeleteALLProfiles.location                = New-Object System.Drawing.Point(20,390)
$ButtonDeleteALLProfiles.Font                    = 'Microsoft Sans Serif,10'
$ButtonDeleteALLProfiles.ForeColor               = "Black"
$ButtonDeleteALLProfiles.Enabled                 = $false

$ButtonExitProgramm                    = New-Object System.Windows.Forms.Button 
$ButtonExitProgramm.Location           = New-Object System.Drawing.Point(20,430) 
$ButtonExitProgramm.width              = 180
$ButtonExitProgramm.height             = 35
$ButtonExitProgramm.Text               = "Exit"
$ButtonExitProgramm.Font               = 'Microsoft Sans Serif,10'


$Panel2                          = New-Object system.Windows.Forms.Panel
$Panel2.height                   = 220
$Panel2.width                    = 690
$Panel2.location                 = New-Object System.Drawing.Point(15,250)
$Panel2.BackColor                = "White"
$Panel2.BorderStyle              = "FixedSingle"

$Form.controls.AddRange(@($ListView1, $ButtonGET, $ButtonDeleteProfiles, $ButtonDeleteALLProfiles, $ButtonExitProgramm, $LinkLabel, $Panel2, $Panel1));

$IPTable = @{}
$key_server_name = "ip"
$global:Comp = @()

function add_to_list_from_ini_file {
    $FileExists = Test-Path $PSScriptRoot\$ini_configuration_file
    # check if ini file does exist, 
    # if it does exist, then read from ini and add to the global variable
    if($FileExists -eq $true) {
        # Write-host "it exists"
        $FileContent = Get-IniContent $PSScriptRoot\$ini_configuration_file
        $FileContent_KeyValues = $FileContent["computer_names"]

        foreach ($item in $FileContent_KeyValues.keys) {  
            if ($global:Comp -contains $item) {
                Write-Host "`r`nDuplicate values cannot be inserted - function add_to_list_from_ini_file"
            } else {        
                if ($global:Comp -contains $FileContent_KeyValues[$item]) {
                    Write-Host "`r`nDuplicate values cannot be inserted into global variable - function add_to_list_from_ini_file"
                } else {
                    $global:Comp += $FileContent_KeyValues[$item]
                }
            }
        }

        foreach ($itm in $global:Comp) {
            if ($ListBoxComputerNames.Items -contains $itm) {
                Write-Host "`r`nDuplicate values are not allowed - function add_to_list_from_ini_file #2"
            } else {
                $ListBoxComputerNames.Items.Add($itm)
            }
        }

    } else {
        Write-Host "`r`nINI config file does NOT exist. Hence we cannot read from it"
        $TextBox3.AppendText("ini Datei existiert nicht `r`n")
    }
    
}

function read_from_list_to_write_ini_file {
    ##################
    # this creates table with ip0 (key) -> IP (value) pairs
    # used for storing the table in the ini file
    if ((-NOT [string]::IsNullOrEmpty($ListBoxComputerNames.Items))) {

        for ($i = 0; $i -lt $ListBoxComputerNames.Items.Count; $i++) {
            if($IPTable.ContainsValue($ListBoxComputerNames.Items[$i])) {
            
            } else {
                $IPTable["$key_server_name$i"] += $ListBoxComputerNames.Items[$i]
            }
        }

        Write-Host "`r`nOutput table used for creating INI config file...."
        $IPTable | Format-Table | Out-String | Write-Host
        Write-Host "`r`nEnd of the INI-based output table..."
        
        # for writing the ini file
        # here to create an ini file which stores all computer names that I have inputted. 
        $NewINIContent = @{"computer_names" = $IPTable}
        Out-IniFile -InputObject $NewINIContent -FilePath $PSScriptRoot\$ini_configuration_file -Force 
    } else {
        Write-Host "`r`nWe cannot write to ini file because nothing has been added to the listbox"
        $TextBox3.AppendText("Es gib nichts zum schreiben in die ini Datei `r`n")
    }  
}

function StartMainFunction {

    $Table = @()

    [ValidateRange(0,1000)][int]$DeleteOlderThan = 0
    $WouldHaveBeenRemoved = $false

    foreach ($item in $ListBoxComputerNames.Items) {
        
        $item = $item.Trim()

        if($global:Comp -contains $item) {
            Write-Host "`r`nDuplicate values are not allowed - function StartMainFunction #3"
        } else {
            $global:Comp += $item
        }
    }
    
    if ($TextBox2.Text -eq 'Older than >= XXX days') {
        $DeleteOlderThan = 0
    } else {
        $DeleteOlderThan = $TextBox2.Text
    }
    
    $today = Get-Date
    $targetted_date_above = $today.AddDays(-1 * $DeleteOlderThan) 

    Write-Host "`r`nCurrent date and time:   --->  $($targetted_date_above)"
    Write-Host "User's input is:         ---> " $Comp
    Write-Host "Number of days you want: ---> " $DeleteOlderThan

    $TextBox3.AppendText("Anfrage an: $($Comp) `r`n")
    
    ##################            
    foreach ($remote_pc in $Comp) {
        $remote_pc = $remote_pc.Trim()

        if($remote_pc -notin ('', 0, "null")) {

            write-host "`r`nChecking UPs on this server: -> $($remote_pc)" -ForegroundColor Green

            if(Test-Connection -ComputerName $remote_pc -BufferSize 16 -Count 2 -Quiet) { 
                # use WMI to find all users with a profile on the servers 
                # important to make sure that only those from the last table are in
                $ListView1.Items.Clear()

                Try { 
                    $params = @{
                        ComputerName = $remote_pc
                        Namespace    = 'root\cimv2' # Root\Cimv2 namespace by default
                        Class        = 'Win32_UserProfile'
                    }
                    
                    Get-WmiObject @params | ForEach-Object {
                        Write-Host "Printing User Profile location -> " $_.LocalPath
        
                        $WouldHaveBeenRemoved = $false
                        # horrible if statement which is True (i.e. these user profiles could be deleted)
                        # only if users are not having a well known SID (local account & NT authority), 
                        # not being used by PC (i.e. must be logged off) and 
                        # not whose last time used is greater than number of provided days 
                        # -and (($_.LastUseTime -and (([WMI]'').ConvertToDateTime($_.LastUseTime))) -le $targetted_date
                        # ($IgnoreLastUseTime -or (($_.LastUseTime) -and (([WMI]'').ConvertToDateTime($_.LastUseTime)) -lt $targetted_date_below)) -or
                        if(($_.SID -notin @('S-1-5-18', 'S-1-5-19', 'S-1-5-20')) -and 
                            (-not $_.Loaded) -and 
                            (($_.LastUseTime) -and (([WMI]'').ConvertToDateTime($_.LastUseTime)) -lt $targetted_date_above))
                            {
                                $WouldHaveBeenRemoved = $true
                            }
        
                        # create structured data object - hashtable account
                        # tries to translate SID to Domain User
                        try {
                            $ac_value = (New-Object System.Security.Principal.SecurityIdentifier($_.Sid)).Translate([System.Security.Principal.NTAccount]).Value 
                        } catch {
                            Write-Warning "`r`nCould not find SID/translate to its value "
                        }
        
                        $prf = [PSCustomObject]@{
                            PSComputerName = $_.PSComputerName
                            Account = $ac_value
                            #Path = $_.Path 
                            LocalPath = $_.LocalPath 
                            LastUseTime = if($_.LastUseTime) { ([WMI]'').ConvertToDateTime($_.LastUseTime) } else { $null }
                            Loaded = $_.Loaded
                            WouldHaveBeenRemoved = $WouldHaveBeenRemoved
                        } 
                        
                        $Table += $prf                                                   
                    }

                    # or differently - if account contains metzde then
                    # sidestep - a filter - to get rid of windows users/user profiles
                    # $cleaned_Table = $Table | Where-Object {$_.LocalPath -notlike 'C:\Windows*' -and $_.LocalPath -notlike "C:\Users\Classic .NET AppPool" }
                    $cleaned_Table = $Table | Where-Object {$_.Account -like 'METZDE\*' } | Sort-Object -Property LastUseTime -Descending
                    
                    $copyOfCleanedTable = $cleaned_Table
                    $copyOfCleanedTable = $copyOfCleanedTable | Where-Object {$_.WouldHaveBeenRemoved -eq $true}

                    # compile the profile list and remove the path prefix, leaving just usernames 
                    $profilelist = $profilelist + $copyOfCleanedTable.localpath -replace "C:\\users\\" 
                    # filter usernames to show only unique values which are left - that in order to prevent displaying duplicates that come from profiles that exist on multiple computers 
                    $uniqueusers = $profilelist | Sort-Object -Unique 

                    # add unique users to the combo box 
                    ForEach($identified_profiles in $uniqueusers) { 
                       [void] $ListView1.Items.Add($identified_profiles) 
                    }

                    Write-Host "`r`n -----------------------------                 -------------------"
                    Write-Host "`r`n -----------------------------                 -------------------"
                    Write-Host "`r`n All UPs that could have been deleted          -------------------"
                    $cleaned_Table | Format-Table | Out-String | Write-Host

                    Write-Host "Unique UPs -------------------"
                    $uniqueusers | Format-Table | Out-String | Write-Host
                } Catch { 
                    $TextBox3.AppendText("Computer $($remote_pc) ist nicht erreichbar. `r`n")  
                    Write-Warning "$($error[0]) "   
                    continue   
                }  
                $ButtonDeleteProfiles.Enabled  = $true  
                $ButtonDeleteALLProfiles.Enabled  = $true  
            } else {
                $TextBox3.AppendText("Computer $($remote_pc) ist nicht erreichbar. `r`n")
                Write-Warning -Message "Computer $($remote_pc) is unavailable"
                $ButtonDeleteProfiles.Enabled  = $false
                $ButtonDeleteALLProfiles.Enabled  = $false  

            }
        }
    }
}

function DeleteSelectedUserProfiles {
    ForEach ($usr in $ListView1.SelectedItems) { 
        #Add the path prefix back to the selected user 
        $selecteduser = $usr 
        $selecteduser = "C:\Users\$selecteduser" 
        Write-host $selecteduser
        Write-host $comp 
        
        ForEach ($computer in $Comp) { 
            if($computer -notin ('', 0, "null")) {
                Try { 
                    Get-WmiObject -ComputerName $computer -Class Win32_UserProfile | Where-Object {$_.LocalPath -eq $selecteduser} | ForEach-Object {$_.Delete()} 
                    Write-Host -ForegroundColor Red "$($selecteduser) has been deleted from $($computer)" 
                    $TextBox3.AppendText("`r`n $($selecteduser) wurde vom $($computer) geloscht. `r`n")
                } Catch [System.Management.Automation.MethodInvocationException]{ 
                    Write-Host -ForegroundColor Red "ERROR: Profile is currently locked on $($computer) - please log off that user"
                    $TextBox3.AppendText("Profil ist von $($computer) benutzt. `r`n") 
                } Catch [System.Management.Automation.RuntimeException] { 
                    Write-Host -ForegroundColor Yellow -BackgroundColor Blue "INFO: $($selecteduser) Profile does not exist on $($computer)" 
                    $TextBox3.AppendText("Profil existiert am $($computer) nicht. `r`n") 
                } Catch { 
                    Write-Host -ForegroundColor Red "ERROR: an unknown error occoured. The error response was $error[0]" 
                    $TextBox3.AppendText("Anderen ERROR: $error[0] `r`n") 
                }
            }
        }  
    }
}


function DeleteAllUserProfiles {
    ForEach ($usr in $ListView1.SelectedItems) { 
        #Add the path prefix back to the selected user 
        $selecteduser = $usr 
        $selecteduser = "C:\Users\$selecteduser" 
        Write-host $selecteduser
        Write-host $comp 
        
        ForEach ($computer in $Comp) { 
            if($computer -notin ('', 0, "null")) {
                Try { 
                    Get-WmiObject -ComputerName $computer -Class Win32_UserProfile | ForEach-Object {$_.Delete()} 
                    Write-Host -ForegroundColor Red "All users has been deleted from $($computer)" 
                    $TextBox3.AppendText("`r`n Alle User Profile wurden vom $($computer) geloscht. `r`n")
                } Catch [System.Management.Automation.MethodInvocationException]{ 
                    Write-Host -ForegroundColor Red "ERROR: Profile is currently locked on $($computer) - please log off that user"
                    $TextBox3.AppendText("Profil ist von $($computer) benutzt. `r`n") 
                } Catch [System.Management.Automation.RuntimeException] { 
                    Write-Host -ForegroundColor Yellow -BackgroundColor Blue "INFO: $($selecteduser) Profile does not exist on $($computer)" 
                    $TextBox3.AppendText("Profil existiert am $($computer) nicht. `r`n") 
                } Catch { 
                    Write-Host -ForegroundColor Red "ERROR: an unknown error occoured. The error response was $error[0]" 
                    $TextBox3.AppendText("Anderen ERROR: $error[0] `r`n") 
                }
            }
        }  
    }
}


If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    [System.Windows.Forms.MessageBox]::Show("It doesn't appear you have run this PowerShell session with administrative rights, the script may not function correctly. If no users are displayed please ensure you run the script again using administrive rights.")  
} 


##############################################################################
##############################################################################
# Add the Panel controls to the form.

################################################################################

$ButtonGET.Add_Click({ StartMainFunction })
$ButtonDeleteProfiles.Add_Click({ DeleteSelectedUserProfiles })
$ButtonDeleteALLProfiles.Add_Click({ DeleteAllUserProfiles })
$ButtonExitProgramm.Add_Click({ $Form.Close() }) 

$ButtonAdd.Add_Click({
    If ((-NOT [string]::IsNullOrEmpty($TextBox1.text))) {
        if($ListBoxComputerNames.Items -contains $TextBox1.text) {
            Write-Warning -Message "Duplicate IPs are not allowed"
            $TextBox3.AppendText("Duplikate sind nicht erlaubt `r`n")
        } else {
            $ListBoxComputerNames.Items.Add($TextBox1.text.Trim())
        }

        $TextBox1.Clear()
    }
})

$ButtonRemove.Add_Click({
    While ($ListBoxComputerNames.SelectedItems.count -gt 0) {
        $ListBoxComputerNames.Items.RemoveAt($ListBoxComputerNames.SelectedIndex)
    }
}) 

# delete with one click all items
$ButtonDeleteAll.Add_Click({
    $ListBoxComputerNames.Items.Clear()
    Remove-Item $PSScriptRoot\$ini_configuration_file
    # clear textbox (becomes empty)
    $TextBox3.Text = ""
}) 


$ReadINI.add_Click({
    $ListBoxComputerNames.Items.Clear()
    add_to_list_from_ini_file
})

$WriteINI.add_Click({
    read_from_list_to_write_ini_file
})


########################################################################################
$TextBox1.Add_GotFocus({
    if ($TextBox1.Text -eq 'Remote PC/Server name/IP') {
        $TextBox1.ForeColor = 'Black'
        $TextBox1.Text = ''
    }
})

#Textbox placeholder grayed out text when textbox clicked
$TextBox1.Add_LostFocus({
    if ($TextBox1.Text -eq '') {
        $TextBox1.Text = 'Remote PC/Server name/IP'
        $TextBox1.ForeColor = 'Darkgray'
    }
})

$TextBox2.Add_GotFocus({
    if ($TextBox2.Text -eq 'Older than >= XXX days') {
        $TextBox2.ForeColor = 'Black'
        $TextBox2.Text = ''
    }
})

#Textbox placeholder grayed out text when textbox clicked
$TextBox2.Add_LostFocus({
    if ($TextBox2.Text -eq '') {
        $TextBox2.Text = 'Older than >= XXX days'
        $TextBox2.ForeColor = 'Darkgray'
    } 
})

################################################################################

$Form.Add_Shown({$Form.Activate(), $ListView1.focus()})
[void]$Form.ShowDialog() 





