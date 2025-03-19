####################################################################################
##  File:  Install-WindowsFeatures.ps1
##  Desc:  Install Windows Features
####################################################################################

$windowsFeatures = '
[
    { "name": "Containers" },
    { "name": "Microsoft-Windows-Subsystem-Linux", "optionalFeature": true },
    { "name": "VirtualMachinePlatform", "optionalFeature": true },
    { "name": "Client-ProjFS", "optionalFeature": true }
]
' | ConvertFrom-JSON

foreach ($feature in $windowsFeatures) {
    if ($feature.optionalFeature) {
        Write-Host "Activating Windows Optional Feature '$($feature.name)'..."
        Enable-WindowsOptionalFeature -Online -FeatureName $feature.name -NoRestart

        $resultSuccess = $?
    } else {
        Write-Host "Activating Windows Feature '$($feature.name)'..."
        $arguments = @{
            Name                   = $feature.name
            IncludeAllSubFeature   = [System.Convert]::ToBoolean($feature.includeAllSubFeatures)
            IncludeManagementTools = [System.Convert]::ToBoolean($feature.includeManagementTools)
        }
        $result = Install-WindowsFeature @arguments

        $resultSuccess = $result.Success
    }

    if ($resultSuccess) {
        Write-Host "Windows Feature '$($feature.name)' was activated successfully"
    } else {
        throw "Failed to activate Windows Feature '$($feature.name)'"
    }
}
