##################################
# Check whether scripts are exist
##################################
$scriptPath = $MyInvocation.MyCommand.Path
$path = Split-Path -Parent $scriptPath
# If even one file($data) does not exist, the script will stop executing.
$data = @('config.xlaunch', 'do_not_turn_off.pow')
$data | ForEach-Object {
    if (!(Test-Path -Path $_ -PathType Leaf)) {
        Write-Host "Error: $_ is not exist."
        Write-Host "Exit."
        exit
    }
}

######################################
# Power settings
######################################
New-Item -Path $Env:USERPROFILE\power_guid_default_setting -Force -ItemType Directory
Function getGUID($arg = "*") {
    $flag = 0 # If GUID: found, $flag = 1
    $guid = "" # When $flag is 1, get the value of $var divided at that time and set $flag to 0

    # Get powercfg settings text including $arg
    $text = powercfg -list | findstr $arg
    # Split $text
    $split = $text -split " "
    foreach ($var in $split) {
        # Set $guid to $var when $flag = 1
        if ($flag -eq 1) {
            $guid = $var
            $flag = 0
        }
        # If $var="GUID:", set $flag to 1
        if ($var -eq "GUID:") {
            $flag = 1
        }
    }
    if ( $guid -eq "") {
        # Error
        Write-Host "GUID is empty"
        return -1
    }
    else {
        Write-Host "Found GUID"
        return $guid
    }
}
Function cantgetGUIDerr() {
    # Quit powercfg setting
    Write-Host "!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!="
    Write-Host "<ERROR: powercfg settings GUID obtain error>"
    Write-Host "Powercfg setting was stopped because GUID could not be obtained."
    Write-Host "Make sure to manually configure or monitor Windows to prevent it from going to sleep"
    Write-Host "!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!="
}
powercfg -list
$defaultsetting = -1
$defaultsetting = getGUID("*")
if ($defaultsetting -ne -1) {
    Write-Host "GUID of Default power setting is $defaultsetting"
    Set-Content "$Env:USERPROFILE\power_guid_default_setting\default_power_setting_guid.txt" $defaultsetting
    Copy-Item ".\do_not_turn_off.pow" "$Env:USERPROFILE\power_guid_default_setting"
    powercfg -import "$Env:USERPROFILE\power_guid_default_setting\do_not_turn_off.pow"
    Remove-Item "$Env:USERPROFILE\power_guid_default_setting\do_not_turn_off.pow"
    powercfg -list
    $do_not_turn_off = -1
    $do_not_turn_off = getGUID("do_not_turn_off")
    if ($do_not_turn_off -ne -1) {
        Write-Host "GUID of do_not_turn_off power setting is $do_not_turn_off"
        powercfg -setactive $do_not_turn_off
        Write-Host "do_not_turn_off power setting is activated!"
        powercfg -list
    }
    else {
        cantgetGUIDerr
    }
}
else {
    cantgetGUIDerr
}

######################################
# Copy X-server settings
######################################

Copy-Item '.\config.xlaunch' "$Env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"


#####################################
# Install Openssh client
#####################################

# If you install Openssh client on Windows, You can use ssh, ssh-keygen, etc... commands!
# see also: https://docs.microsoft.com/ja-jp/windows-server/administration/openssh/openssh_install_firstuse
# Install the OpenSSH Client
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

##############################
# winget setup
##############################
# If you don't have winget, Manually install winget on $Env:USERPROFILE\Downloads Folder.
# See also : https://zenn.dev/nobokko/articles/idea_winget_wsb#windows%E3%82%B5%E3%83%B3%E3%83%89%E3%83%9C%E3%83%83%E3%82%AF%E3%82%B9%E3%81%ABwinget%E3%82%92%E5%B0%8E%E5%85%A5%E3%81%97%E3%82%88%E3%81%86%EF%BC%81%E3%81%A8%E3%81%84%E3%81%86%E8%A9%B1
$winget = "winget"
if ( -not ( Get-Command $winget -ErrorAction "silentlycontinue" ) ) {
    Write-Host "winget command does not exist.`n Try to install winget manually using invoke-webrequest and Add-AppxPackage!"
    invoke-webrequest -uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -outfile $Env:USERPROFILE\Downloads\Microsoft.VCLibs.x64.14.00.Desktop.appx -UseBasicParsing
    invoke-webrequest -uri https://github.com/microsoft/winget-cli/releases/download/v1.0.12576/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -outfile $Env:USERPROFILE\Downloads\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -UseBasicParsing
    Add-AppxPackage -Path $Env:USERPROFILE\Downloads\Microsoft.VCLibs.x64.14.00.Desktop.appx
    Add-AppxPackage -Path $Env:USERPROFILE\Downloads\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
}

##############################
# Install softwares (windows)
##############################

# WindowsTerminal (https://www.microsoft.com/ja-jp/p/windows-terminal/9n0dx20hk701)
# is a powerful terminal software. I recommend you to use this software when you use WSL2 ubuntu.
winget install --silent Microsoft.WindowsTerminal --accept-package-agreements --accept-source-agreements

# Vscode (https://code.visualstudio.com/)
# is a very powerful editor. I strongly suggest you to use this editor when you edit any text files.
# (Install option reference is here : https://proudust.github.io/20200726-winget-install-vscode/)
winget install --silent Microsoft.VisualStudioCode --override "/VERYSILENT /NORESTART /mergetasks=""!runcode,desktopicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"""

# You can extract tar.gz etc. files by using 7zip (https://sevenzip.osdn.jp/).
winget install --silent 7zip.7zip

# Winscp (https://winscp.net/eng/docs/lang:jp)
# provides you to download/upload files with calculation servers by using scp (or sftp) protocol.
winget install --silent --scope user WinSCP.WinSCP

# Git (https://gitforwindows.org/) supports git command on windows.
winget install --silent Git.Git

# Teraterm (https://ttssh2.osdn.jp/) is a terminal software.
# If you don't like other terminal softwares, you can use this software.
winget install --silent TeraTermProject.teraterm --override "/VERYSILENT"

# VcXsrv (https://sourceforge.net/projects/vcxsrv/) is a X-server software.
# If you want to use GUI software when you use CLI WSL linux, VcXsrv supports this(GUI) feature.
winget install --silent marha.VcXsrv

##############################
# Windows Terminal setting
##############################

$new_guid=[Guid]::NewGuid()
$git_bash_terminal_setting="{
    `"commandline`": `"%PROGRAMFILES%\\Git\\bin\\bash.exe`",
    `"guid`": `"{$new_guid}`",
    `"hidden`": false,
    `"icon`": `"%PROGRAMFILES%\\Git\\mingw64\\share\\git\\git-for-windows.ico`",
    `"name`": `"Git Bash`",
    `"startingDirectory`": `"%USERPROFILE%`"
}"
echo $git_bash_terminal_setting > ./git_settings.json

##############################
# Restore default power setting
##############################

$defaultsetting=-1
$defaultsetting= Get-Content "$Env:USERPROFILE\power_guid_default_setting\default_power_setting_guid.txt"
Write-Host "defaultsetting is "$defaultsetting
if ($defaultsetting -ne -1){
    powercfg -setactive $defaultsetting
    Write-Host "default power setting is  reactivated!"
    powercfg -list
}else{
cantgetGUIDerr
}
