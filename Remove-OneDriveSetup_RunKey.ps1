#Create PSDrive for HKU
New-PSDrive -PSProvider Registry -Name HKUDefaultHive -Root HKEY_USERS

#Load Default User Hive
Reg Load "HKU\DefaultHive" "C:\Users\Default\NTUser.dat"

#Set OneDriveSetup Variable
$OneDriveSetup = Get-ItemProperty "HKUDefaultHive:\DefaultHive\Software\Microsoft\Windows\CurrentVersion\Run" | Select -ExpandProperty "OneDriveSetup"

#If Variable returns True, remove the OneDriveSetup Value
If ($OneDriveSetup) { Remove-ItemProperty -Path "HKUDefaultHive:\DefaultHive\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDriveSetup" }

#Unload Hive
Reg Unload "HKU\DefaultHive\"

#Remove PSDrive HKUDefaultHive
Remove-PSDrive "HKUDefaultHive"