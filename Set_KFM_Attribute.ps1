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
    1.1.26   26/01/2020  Ben Whitmore

.DESCRIPTION
Script to set KnownFolder Pinned status

.PARAMETER KnownFolder
Specify which KnownFolders to process. Choice of "Desktop", "Documents", "Pictures".

.PARAMETER PinStatus
Specify the Pinned atribute to pass. Choice of "Pin", "Unpin".

.EXAMPLE
Set_KFM_Attribute.ps1 -KnownFolder "Desktop", "Documents" -PinStatus "Pin"

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateSet("Desktop", "Documents", "Pictures")]
    [String[]]$KnownFolder,
    [Parameter(Mandatory)]
    [ValidateSet("Pin","UnPin")]
    [String]$PinStatus
)

#Set attributes to pass to attrib.exe
If ($PinStatus -eq 'Pin') {$AttributeState1 = '+P'; $AttributeState2 = '-U'}
If ($PinStatus -eq 'UnPin') {$AttributeState1 = '-P'; $AttributeState2 = '+U'}  

#Set variable for OneDrive Commercial
$OneDriveLoc = $ENV:OneDriveCommercial

#Update attributes for all files and folders specified, including toplevel KnownFolder
Foreach ($Folder in $KnownFolder){

    #Set KnownFolder 
    $OneDriveKnownFolder = Join-Path $OneDriveLoc $Folder

    #Set the KnownFolder attribute so new items match the pinned status passed in the script
    attrib.exe $OneDriveKnownFolder $AttributeState1 $AttributeState2 /s /d

    #Process child items in the KnownFolder
    Get-ChildItem $OneDriveKnownFolder -Recurse | Select-Object Fullname | ForEach-Object {attrib.exe $_.FullName $AttributeState1 $AttributeState2}
}