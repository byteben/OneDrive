$OneDriveVersion = Get-ItemProperty -path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive" | Select-Object -Expand Version
$OneDrivePath = Get-ItemProperty -path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive" | Select-Object -Expand CurrentVersionPath
$OneDriveUninstaller = $OneDrivePath + "\OneDriveSetup.exe"
$OneDriveSCCMDetection = $OneDrivePath + "\" + $OneDriveVersion + "_RemovedByScript.txt"

If ($OneDriveVersion -like "19.163.*") {
    Start-Process -FilePath $OneDriveUninstaller -ArgumentList "/uninstall /allusers" -WindowStyle Hidden
    New-Item -Path $OneDriveSCCMDetection -ItemType File -Force
}