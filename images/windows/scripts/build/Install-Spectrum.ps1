################################################################################
##  File:  Install-Spectrum.ps1
##  Desc:  Install Spectrum beta
################################################################################

# Install spectrum desktop from beta site
$downloadUrl = "https://spectrumbeta.avenirhealth.org/SpecInstall.EXE"
$destinationPath = "${env:TEMP_DIR}\SpecInstall.exe"
Invoke-DownloadWithRetry -Url $downloadUrl -Path $desintationPath
Start-Process -FilePath $destinationPath /S -Wait

# Create an env var pointing to the executable
$envName = "SPECTRUM_EXE_PATH"
$envValue = "C:\Program Files (x86)\Spectrum6\SPECTRUM.EXE"
[System.Environment]::SetEnvironmentVariable($envName, $envValue, [System.EnvironmentVariableTarget]::Machine)

# Add to PATH
Add-MachinePathItem "C:\Program Files (x86)\Spectrum6"
