param([string]$GameRoot = 'D:\Games\World of Warcraft')
$ErrorActionPreference = 'Stop'
foreach ($folder in @('_classic_era_', '_forever_', '_classic_titan_')) {
    $path = Join-Path $GameRoot $folder
    $exe = Get-ChildItem -LiteralPath $path -Filter 'Wow*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    [PSCustomObject]@{ Client = $folder; Exists = (Test-Path -LiteralPath $path); Version = $exe.VersionInfo.FileVersion;
        AddOns = (Join-Path $path 'Interface\AddOns') }
}
