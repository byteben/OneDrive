<#
===========================================================================
Created on:   	26/01/2020 10:45
Created by:   	Ben Whitmore
Organization: 	
Filename:     	Set_KFM_Attribute.ps1
-------------------------------------------------------------------------
Script Name: Set_KFM_Attribute
===========================================================================
    
Version:
1.1.26.2   26/01/2020  Ben Whitmore
Added logging to HKCU for MEMCM Detection Method
HKEY_CURRENT_USER\ScriptStatus\Set_KFM_Attributes
> Attribute_Set
> Folders_Specified
> LastRun

1.1.26.1   26/01/2020  Ben Whitmore
Added "Favorites" as Known Folder Location

1.1.26.0   26/01/2020  Ben Whitmore

.DESCRIPTION
Script to set KnownFolder Pinned status

.PARAMETER KnownFolder
Specify which KnownFolders to process. Choice of "Desktop", "Documents", "Pictures", "Favorites".

.PARAMETER PinStatus
Specify the Pinned atribute to pass. Choice of "Pin", "Unpin".

.EXAMPLE
Set_KFM_Attribute.ps1 -KnownFolder "Desktop", "Documents" -PinStatus "Pin"

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateSet("Desktop", "Documents", "Pictures", "Favorites")]
    [String[]]$KnownFolder,
    [Parameter(Mandatory)]
    [ValidateSet("Pin", "UnPin")]
    [String]$PinStatus
)

#Set attributes to pass to attrib.exe
If ($PinStatus -eq 'Pin') { $AttributeState1 = '+P'; $AttributeState2 = '-U' }
If ($PinStatus -eq 'UnPin') { $AttributeState1 = '-P'; $AttributeState2 = '+U' }  

#Set variable for OneDrive Commercial
$OneDriveLoc = $ENV:OneDriveCommercial

#Update attributes for all files and folders specified, including toplevel KnownFolder
Foreach ($Folder in $KnownFolder) {

    #Set KnownFolder 
    $OneDriveKnownFolder = Join-Path $OneDriveLoc $Folder

    #Set the KnownFolder attribute so new items match the pinned status passed in the script
    attrib.exe $OneDriveKnownFolder $AttributeState1 $AttributeState2 /s /d

    #Process child items in the KnownFolder
    Get-ChildItem $OneDriveKnownFolder -Recurse | Select-Object Fullname | ForEach-Object { attrib.exe $_.FullName $AttributeState1 $AttributeState2 }
}

#Prepare to write registry key for MEMCM Detection Method
$RegistryPath = "HKCU:\ScriptStatus\Set_KFM_Attributes"

#Check If Script Registry Key Exists 
If (!(Test-Path $RegistryPath)) {

    #If Registry Key doesn't exist, create it
    New-Item -Path $RegistryPath -Force | Out-Null

    #Dealing with "Value Exists" logic in MEMCM Detection Method so will force the value here to say script has run
    New-ItemProperty -Path $RegistryPath -Name "Last_Run" -Value (Get-Date) -PropertyType String -Force | Out-Null

    #Create Registry Item for Known Folder the script has run against
    New-ItemProperty -Path $RegistryPath -Name "Attribute_Set" -Value $PinStatus -PropertyType String -Force | Out-Null
}
else {
     
    #Dealing with "Value Exists" logic in MEMCM Detection Method so will force the value here to say script has run
    New-ItemProperty -Path $RegistryPath -Name "Last_Run" -Value (Get-Date) -PropertyType String -Force | Out-Null

    #Create Registry Item for Known Folder the script has run against
    New-ItemProperty -Path $RegistryPath -Name "Attribute_Set" -Value $PinStatus -PropertyType String -Force | Out-Null 
}

#Reset Variables
$KnownFoldersProcessed = $Null
$Count = 0

Foreach ($Folder in $KnownFolder) {

    #Build string for Registry
    If ($Count -gt 0) { $LineBreak = ' | ' } else { $LineBreak = $Null }
    $KnownFoldersProcessed = $KnownFoldersProcessed + $LineBreak + $Folder 
    $Count ++
}

#Create Registry Item for Known Folder the script has run against
New-ItemProperty -Path $RegistryPath -Name "Folders_Specified" -Value $KnownFoldersProcessed -PropertyType String -Force | Out-Null 