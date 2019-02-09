#Popup MsgBox to inform user the action will log off the current session
param ([string]$Message = 'Running this app will move your Favorites location to OneDrive and log you off. Please ensure you have copied your "Favorites" folder to the root of your OneDrive before you continue. Contact ICT if you need assistance. Click OK to continue or CANCEL to exit the program.',
	[string]$Title = 'Move Favorites Location to OneDrive')
Add-Type -AssemblyName 'System.Windows.Forms'
$MsgBox = [Windows.Forms.MessageBox]
$Decision = $MsgBox::Show($Message, $Title, 'OkCancel', 'Information')
#If user clicks cancel, exit script
If ($Decision -eq "Cancel")
{
	exit
}
else
{
	#Set user registry keys to move Favorites location to Onedrive\Favorites
	$OneDrive = $Env:OneDrive
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -Name Favorites -Value "$OneDrive\Favorites"
	Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' -Name Favorites -Value "$OneDrive\Favorites"
	#Logoff
	Shutdown /l
}