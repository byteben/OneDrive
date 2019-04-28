<#
.Disclaimer
	This scripts is provided AS IS without warranty of any kind.
	In no event shall the author be liable for any damages whatsoever 
	(including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss)
	arising out of the use of or inability to use script,
	even if the Author has been advised of the possibility of such damages

.Author
	Ben Whitmore

.Created
	28/04/2019

.DESCRIPTION
 	Script to monitor and remove duplicate desktop shortcuts created when OneDrive Known FOlder Move initialises
 
.EXAMPLE
	OneDriveKFM_Prevent_Duplicate_Shortcuts.ps1

#>

#Unregister-Event -SourceIdentifier FileCreated if still regsitered
$EventWatcher = Get-EventSubscriber
ForEach ($Event in $EventWatcher)
{
	If ($Event.SourceIdentifier -eq 'FileCreated')
	{
		Unregister-Event -SubscriptionId $Event.SubscriptionId
	}
}

#Get user shell folder path for the desktop folder
$UserShellFolderKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
$UserShellFolderDir = (Get-ItemProperty -Path $UserShellFolderKey -Name Desktop).Desktop

#Get folder path for OneDrive for Business
If ($UserShellFolderDir -like "*OneDrive - *")
{
	$OneDriveCommercialPath = $UserShellFolderDir
}
else
{
	$OneDriveCommercialPath = $env:OneDriveCommercial + "\Desktop"
}

$ProgressBar = 'True'

#Specify the time in seconds the script will wait for KFM policies to redirect the desktop
$TimeToWait = 900

#Initialise wait timer
$WaitTime = 0

Do
{
	$ProgressCount = ($WaitTime/$TimeToWait) * 100
	
	If ($UserShellFolderDir -ne $OneDriveCommercialPath)
	{
		#Sleep 10 Seconds before checking if OneDrive KFM policies have redirected the desktop
		Start-Sleep -s 1
		
		#Set time remaining counter
		$CountDown = ($TimeToWait - $WaitTime)
		
		#If set to 'True', display the progress bar. Use for testing only.
		If ($ProgressBar -eq 'True')
		{
			Write-Progress -Activity "Waiting for KFM Redirection" -Status $CountDown" Seconds" -PercentComplete $ProgressCount
		}
		
		#Reset desktop variable
		$UserShellFolderDir = (Get-ItemProperty -Path $UserShellFolderKey -Name Desktop).Desktop
	}
}

#Continue checking for folder redirection until KFM initialises or the timer runs out
While (++$WaitTime -le $TimeToWait -and $UserShellFolderDir -ne $OneDriveCommercialPath)

#If KFM timeout interval is reached, suggest increasing the timeout
If ($WaitTime -ge $TimeToWait)
{
	Write-Host "Script timed out waiting for OneDrive KFM to redirect the desktop folder. Try increasing the 'TimeToWait' variable" -ForegroundColor Yellow
}
else
{
	Write-Host "User shell folder desktop is redirected to OneDrive" -ForegroundColor Green
	
	#Specify the time in seconds the script will wait for KFM Desktop to be created
	$TimeToWait2 = 1800
	
	#Initialise wait timer2
	$WaitTime2 = 0
	Do
	{
		$ProgressCount2 = ($WaitTime2/$TimeToWait2) * 100
		
		If (!(Test-Path -Path $UserShellFolderDir))
		{
			#Sleep 1 Second before checking if OneDrive KFM desktop exists
			Start-Sleep -s 1
			
			#Set time remaining counter
			$CountDown2 = ($TimeToWait2 - $WaitTime2)
			
			#If set to 'True', display the progress bar. Use for testing only.
			If ($ProgressBar -eq 'True')
			{
				Write-Progress -Activity "Waiting OneDrive Desktop Creation" -Status $CountDown2" Seconds" -PercentComplete $ProgressCount2
			}
		}
	}
	
	#Continue checking for folder creation or until the timer runs out
	While (++$WaitTime2 -le $TimeToWait2 -and (!(Test-Path -Path $UserShellFolderDir)))
	
	#If KFM creates the OneDrive desktop folder before the timeout value is reached, carry on with the script
	if (Test-Path -Path $UserShellFolderDir)
	{
		#User shell folder desktop is created on Onedrive
		Write-Host "User shell folder desktop exists in OneDrive" -ForegroundColor Green
		
		#Define a new File System Watcher
		$ShortcutRadar = New-Object System.IO.FileSystemWatcher
		$ShortcutRadar.Path = $UserShellFolderDir
		$ShortcutRadar.Filter = '*.lnk'
		$ShortcutRadar.IncludeSubdirectories = $False
		$ShortcutRadar.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'
		
		#Create a new File System Watcher to check when .lnk files are created in OneDrive\Desktop
		Register-ObjectEvent $ShortcutRadar Created -SourceIdentifier FileCreated -Action {
			$FileName = $Event.SourceEventArgs.Name
			$FileOperation = $Event.SourceEventArgs.ChangeType
			$FileOperationTimeStamp = $Event.TimeGenerated
			
			Write-Host "The file '$FileName' was $FileOperation at $FileOperationTimeStamp" -ForegroundColor Green
			
			#For each new shortcut created on the desktop, get the target
			$ShortcutObject = New-Object -ComObject WScript.Shell
			
			#Get all versions of the newly created shortcut
			$StringSeparator = " - Copy"
			$NewShortcut = $FileName -Split $StringSeparator
			$NewShortcutOriginalName = $NewShortcut[0]
			
			$OriginalOneDriveDesktopShortcut = Get-ChildItem -Path "$($UserShellFolderDir)" -Filter '*.lnk' | Where { $_.Name.StartsWith($NewShortcutOriginalName) } | Sort-Object CreationTime -Descending | Select -Last 1
			
			$OneDriveDesktopShortcuts = Get-ChildItem -Path "$($UserShellFolderDir)" -Filter '*.lnk' | Where { $_.Name.StartsWith($NewShortcutOriginalName) -and $_.Name -ne $OriginalOneDriveDesktopShortcut.Name } | Sort-Object CreationTime -Descending
			
			#Get target for original desktop icon
			$OriginalShortcutDestination = $ShortcutObject.CreateShortcut($OriginalOneDriveDesktopShortcut.FullName)
			$OriginalShortcutDestination.TargetPath
			
			#Show original desktop shortcut (earliest creation time and doesnt contain the word "copy"
			Write-Host "Original Shorcut: " $OriginalOneDriveDesktopShortcut.Name " | " $OriginalShortcutDestination.TargetPath -ForegroundColor Magenta
			
			ForEach ($Target in $OneDriveDesktopShortcuts)
			{
				
				$ShortcutDestination = $ShortcutObject.CreateShortcut($Target.Fullname)
				$ShortcutDestination.TargetPath
				
				#Show all shortcuts that match partial name and exact target of newly created shortcut                
				If ($ShortcutDestination.TargetPath -eq $OriginalShortcutDestination.TargetPath)
				{
					Write-Host $Target.Name " | " $ShortcutDestination.TargetPath -ForegroundColor Yellow
					
					#Delete duplicate shortcuts
					Remove-Item -Path $UserShellFolderDir"\"$Target -Force
				}
			}
		}
	}
	
	
	
}
#To End File Watcher Run:-
#Unregister-Event -SourceIdentifier FileCreated
