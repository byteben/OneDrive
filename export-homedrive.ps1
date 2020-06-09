<#
===========================================================================
Created on:   	26/01/2020 10:45
Created by:   	Ben Whitmore
Organization: 	
Filename:     	export-homedrive.ps1
-------------------------------------------------------------------------
Script Name: export-homedrive
===========================================================================
#>

#Set OneDrive Variable
$OneDriveDir = $Env:OneDriveCommercial

#Get username and remove the Domain Netbios portion
$Username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$username = $Username.Replace("MY-DOMAIN\","")

#Set variable for exisitng homedrive
$HomeDriveRoot = "\\fileserver\usershare$"
$HomeDrive = Join-Path $HomeDriveRoot $Username

#Define file types we do not want to copy to OneDrive
$Exclude = @('*.lock', '*.tmp', 'CON', 'PRN', 'AUX', 'NUL', 'COM0', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT0', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9', '_vti_', 'desktop.ini')

#Create array of destinations. We utilise OneDrive know Folder Move and redirect the users folders to the OneDrive Root using the hieracrchy below
$Destinations = @('Documents', 'Pictures', 'Favorites', 'Desktop', 'Documents\Templates')

#Create log file
$Log = Join-Path $OneDriveDir 'Documents\HomeDrive_Sync_log.txt'

If (Test-Path $Log) {
    Remove-Item $Log -Force | Out-Null
}

#Iterate through each root folder
Foreach ($Destination in $Destinations) {
    
    #Set variable for fileserver source and OneDrive folder destination
    $HomeSource = Join-Path $HomeDrive $Destination
    $OneDriveDestination = Join-Path $OneDriveDir $Destination

    #Create the destination root folder in OneDrive
    If (Test-Path $OneDriveDir) {

        If (!(Test-Path $OneDriveDestination)) {
            New-Item -Path $OneDriveDestination -ItemType Directory -Force -ErrorAction Continue 
        }
        
        #Copy items from old redirected Desktop to OneDrive\Desktop, excluding the Recycle Bin. Move any .lnk or .url files to a new folder on the desktop called Old_Shortcuts. This avoids duplicate because MEMCM/GPO creates the correct application shortcuts in Windows 10
        If ($Destination -eq 'Desktop') {
            New-Item -Path (Join-Path $OneDriveDestination 'Old_Shortcuts') -ItemType Directory -Force -ErrorAction Continue 
            Robocopy.exe $HomeSource (Join-Path $OneDriveDestination 'Old_Shortcuts') *.lnk *.url /z /sec /r:5 /w:1 /reg /v /eta /xd (Join-Path $HomeSource '$Recycle.Bin') /UNILOG+:$Log
            Robocopy.exe $HomeSource $OneDriveDestination /e /z /sec /r:5 /w:1 /reg /v /eta /xf *.lnk *.url $Exclude /xd (Join-Path $HomeSource '$Recycle.Bin') /UNILOG+:$Log
        }
        
        #Copy items from old redirected Documents to OneDrive\Documents, excluding the Recycle Bin and the Templates directory. We create new Office templates for the user
        If ($Destination -eq 'Documents') {
            Robocopy.exe $HomeSource $OneDriveDestination /e /z /sec /r:5 /w:1 /reg /v /eta /xd (Join-Path $HomeSource 'Templates') (Join-Path $HomeSource '$Recycle.Bin') /xf $Exclude /UNILOG+:$Log
        }

        #Copy items from old redirected Templates to OneDrive\Documents\Templates_Old, excluding the Recycle Bin. We create new Office templates for the user so the old templates are moved to Templates_Old
        If ($Destination -eq 'Documents\Templates') {
            $OneDriveDestination = Join-Path $OneDriveDir 'Documents\Templates_Old'
            New-Item -Path $OneDriveDestination -ItemType Directory -Force -ErrorAction Continue
            Robocopy.exe $HomeSource $OneDriveDestination /e /z /sec /r:5 /w:1 /reg /v /eta /xf $Exclude /xd (Join-Path $HomeSource '$Recycle.Bin') /UNILOG+:$Log
        }

        #No special consideration required for Pictures or IE Favorites. We copy these into the relevant root folder in OneDrive
        If (!($Destination -eq 'Desktop') -and !($Destination -eq 'Documents') -and !($Destination -eq 'Documents\Templates')) {
            Robocopy.exe $HomeSource $OneDriveDestination /e /z /sec /r:5 /w:1 /reg /v /eta /xf $Exclude /xd (Join-Path $HomeSource '$Recycle.Bin') /UNILOG+:$Log
        }


    }
}

#We create a file to indicate the script has run for MEMCM detection.
New-Item -Path (Join-Path $OneDriveDir 'Documents\HomeDrive_Synced.txt') -ItemType File -Force -ErrorAction Continue