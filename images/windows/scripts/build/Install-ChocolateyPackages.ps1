################################################################################
##  File:  Install-ChocolateyPackages.ps1
##  Desc:  Install common Chocolatey packages
################################################################################

$commonPackages = '
[
    { "name": "7zip.install" },
    { "name": "visualstudio2022buildtools", "args": [ "--ignore-checksums" ] },
    { "name": "visualstudio2022-workload-python" }
]
' | ConvertFrom-JSON

foreach ($package in $commonPackages) {
    Install-ChocoPackage $package.name -ArgumentList $package.args
}
