$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $PSScriptRoot
$sourceToc = Get-Content -LiteralPath (Join-Path $source 'BearaiProfessionMail.toc') -Raw
$expectedVersion = [regex]::Match($sourceToc, '(?m)^## Version:\s*([^\r\n]+)').Groups[1].Value.Trim()
$fixture = Join-Path $source ('.tmp\deploy-' + [guid]::NewGuid().ToString('N'))
foreach ($client in @('_classic_era_', '_forever_')) {
    New-Item -ItemType Directory -Path (Join-Path $fixture "$client\Interface\AddOns\OtherAddon") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $fixture "$client\Interface\AddOns\OtherAddon\sentinel.txt") -Value 'untouched'
}
& "$PSScriptRoot\Deploy.ps1" -Client Both -GameRoot $fixture
if (Test-Path -LiteralPath (Join-Path $fixture '_classic_era_\Interface\AddOns\BearaiProfessionMail')) {
    throw '预览模式发生了写入。'
}
& "$PSScriptRoot\Deploy.ps1" -Client Both -GameRoot $fixture -Apply
foreach ($client in @('_classic_era_', '_forever_')) {
    $target = Join-Path $fixture "$client\Interface\AddOns\BearaiProfessionMail"
    $files = @(Get-ChildItem -LiteralPath $target -Recurse -File)
    if ($files.Count -ne 15) { throw "部署文件数量异常：$($files.Count)" }
    $expectedInterface = if ($client -eq '_classic_era_') { 11509 } else { 16001 }
    $deployedToc = Get-Content -LiteralPath (Join-Path $target 'BearaiProfessionMail.toc') -Raw
    if ($deployedToc -notmatch "(?m)^## Interface: $expectedInterface\r?`$") { throw '目标 TOC Interface 错误。' }
    $manifest = Get-Content -LiteralPath (Join-Path $target 'deployment.json') -Raw | ConvertFrom-Json
    if ($manifest.interface -ne $expectedInterface -or $manifest.addonVersion -ne $expectedVersion) { throw '部署清单版本错误。' }
    if ($manifest.inGameValidation -ne 'pending') { throw '部署不应将游戏测试标记为通过。' }
    foreach ($entry in $manifest.files.PSObject.Properties) {
        if ((Get-FileHash -LiteralPath (Join-Path $target $entry.Name)).Hash -ne $entry.Value) { throw '部署清单哈希错误。' }
    }
    if ((Get-Content -LiteralPath (Join-Path $fixture "$client\Interface\AddOns\OtherAddon\sentinel.txt")) -ne 'untouched') {
        throw '其他插件文件被改变。'
    }
    if (Test-Path -LiteralPath (Join-Path $target 'tests')) { throw '部署夹带开发文件。' }
}
Write-Output "PASS：双客户端部署模拟、预览零写入、独立 Interface、部署清单与哈希校验、其他插件哨兵未改动。测试目录：$fixture"
