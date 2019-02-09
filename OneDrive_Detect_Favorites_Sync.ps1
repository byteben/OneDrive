$OneDrive = $Env:OneDrive
$OneDriveFavoritesPath = $OneDrive + "\Documents\Favorites_Synced.txt"
If (Test-Path $OneDriveFavoritesPath)
{
	write-host "Installed"
}