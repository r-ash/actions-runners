################################################################################
##  File:  Install-Docker-ce.ps1
##  Desc:  Install Docker ce.
##         Must be an independent step because it requires a restart before we
##         can continue.
################################################################################

Write-Host "Install Docker CE"
$dockerPath = "$env:TEMP_DIR\docker\docker.exe"
$dockerdPath = "$env:TEMP_DIR\docker\dockerd.exe"
$instScriptUrl = "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1"
$instScriptPath = Invoke-DownloadWithRetry $instScriptUrl
& $instScriptPath -DockerPath $dockerPath -DockerDPath $dockerdPath
if ($LastExitCode -ne 0) {
    Write-Host "Docker installation failed with exit code $LastExitCode"
    exit $exitCode
}
