If (!(Test-Path HKCU:\ScriptStatus\Set_KFM_Attributes)) {
}
Else {
    Write-Output "Installed"
}