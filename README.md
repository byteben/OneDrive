# OneDrive
PowerShell Scripts for OneDrive Discovery and remediation in Windows 10 using ConfigMgr / MEMCM

OneDrive_Detect_Favorites_Sync.ps1 - Used for the SCCM App Detection Method. Will return a value of True if file "Favorites_Synced.txt" exists in the Users OneDrive\Documents folder

OneDrive_Move_Favorites_Location.ps1 - Scripts that can be published in the Software Centre to allow the user to easily point their Favorites folder to OneDrive\Favorites

OneDrive_Sync_Favorites.ps1 - Can be used in conjunction with OneDrive_Detect_Favorites_Sync.ps1 to Sync the OneDrive\Favorites folder to available Offline (Requires Windows 10 Creators and above)

OneDriveKFM_Prevent_Duplicate_Shortcuts.ps1 - Script to monitor OneDrive KFM initialisation for new profilesand then remove duplicate .lnk files created on the desktop. Prevents multiple shortcuts to the same target being created with a " - Copy" appended to shortcut name

Set_KFM_Attribute.ps1 - Script to set the OneDrive KnownFolder attributes
