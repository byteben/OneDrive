$OneDrive = $Env:OneDrive
$OneDrive + "\Favorites" | Get-ChildItem -Filter *.url | ForEach {attrib.exe ""$OneDrive"\Favorites\"$_"" +p -u /d /s}
New-Item -force $OneDrive"\Documents\Favorites_Synced.txt"