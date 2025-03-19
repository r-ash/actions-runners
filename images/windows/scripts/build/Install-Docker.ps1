################################################################################
##  File:  Install-Docker.ps1
##  Desc:  Install Docker.
##         Must be an independent step because it requires a restart before we
##         can continue.
################################################################################

Write-Host "Get latest Moby release"
$toolsetVersion = "$env:DOCKER_VERSION"
$mobyVersion = (Get-GithubReleasesByVersion -Repo "moby/moby" -Version "${toolsetVersion}").version
$dockerceUrl = "https://download.docker.com/win/static/stable/x86_64/"
$dockerceBinaries = Invoke-WebRequest -Uri $dockerceUrl -UseBasicParsing

Write-Host "Check Moby version $mobyVersion"
$mobyRelease = $dockerceBinaries.Links.href -match "${mobyVersion}\.zip" | Select-Object -Last 1
if (-not $mobyRelease) {
    Write-Host "Release not found for $mobyLatestRelease version"
    $versions = [regex]::Matches($dockerceBinaries.Links.href, "docker-(\d+\.\d+\.\d+)\.zip") | Sort-Object { [version] $_.Groups[1].Value }
    $mobyRelease = $versions | Select-Object -ExpandProperty Value -Last 1
    Write-Host "Found $mobyRelease"
}
$mobyReleaseUrl = $dockerceUrl + $mobyRelease

Write-Host "Install Moby $mobyRelease..."
$mobyArchivePath = Invoke-DownloadWithRetry $mobyReleaseUrl
Expand-Archive -Path $mobyArchivePath -DestinationPath $env:TEMP_DIR
