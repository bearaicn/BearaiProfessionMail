[CmdletBinding()]
param(
    [ValidateSet('Hardcore','Forever','Both')][string]$Client = 'Hardcore',
    [switch]$AllowDirty
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dirty = @(& git -C $root status --porcelain).Count -gt 0
if ($dirty -and -not $AllowDirty) { throw '发布打包需要干净工作区；本地检查可使用 -AllowDirty。' }
$commit = (& git -C $root rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw '无法获取 Git 提交。' }
$toc = Get-Content -LiteralPath (Join-Path $root 'BearaiProfessionMail.toc') -Raw
$version = [regex]::Match($toc, '(?m)^## Version:\s*([^\r\n]+)').Groups[1].Value.Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw '无效插件版本。' }
foreach ($doc in @('README.md','README.en.md','CHANGELOG.md',"docs/releases/v$version.md")) {
    $text = Get-Content -LiteralPath (Join-Path $root $doc) -Raw
    if ($text -notmatch [regex]::Escape($version)) { throw "发布前必须更新文档：$doc" }
}
if (-not $AllowDirty -and (& git -C $root tag --list "v$version")) {
    $tagCommit = (& git -C $root rev-list -n 1 "v$version").Trim()
    if ($tagCommit -ne $commit) { throw '当前提交与版本 Tag 不一致，请检出发布提交。' }
}
$clients = Get-Content -LiteralPath (Join-Path $root 'config/clients.json') -Raw | ConvertFrom-Json
$files = @($toc -split '\r?\n' | Where-Object { $_ -match '\.lua$' })
$files += @(Get-Content -LiteralPath (Join-Path $root 'config/assets.json') -Raw | ConvertFrom-Json)
$files += 'LICENSE'
foreach ($file in $files) {
    if ($file -match '\.\.|^[/\\]|:' -or -not (Test-Path -LiteralPath (Join-Path $root $file))) { throw "无效发布文件：$file" }
}
$output = Join-Path $root ".tmp/releases/v$version"
New-Item -ItemType Directory -Path $output -Force | Out-Null
$checksums = @()
$targets = if ($Client -eq 'Both') { @('Hardcore','Forever') } else { @($Client) }
foreach ($name in $targets) {
    $config = $clients.$name
    $stage = Join-Path $root ('.tmp/package-' + [guid]::NewGuid().ToString('N'))
    $addon = Join-Path $stage 'BearaiProfessionMail'
    New-Item -ItemType Directory -Path $addon -Force | Out-Null
    foreach ($file in $files) {
        $destination = Join-Path $addon $file
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $root $file) -Destination $destination
    }
    $targetToc = [regex]::Replace($toc, '(?m)^## Interface:[^\r\n]*', "## Interface: $($config.interface)")
    [IO.File]::WriteAllText((Join-Path $addon 'BearaiProfessionMail.toc'), $targetToc, [Text.UTF8Encoding]::new($false))
    [ordered]@{ version=$version; tag="v$version"; target=$config.flavor; interface=$config.interface;
        gitCommit=$commit; workingTreeDirty=$dirty; inGameValidation=$config.inGameValidation } |
        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $addon 'release.json') -Encoding utf8
    @"
BearAI Profession Mail / 熊智专业邮寄助手 $version
Compatibility / 兼容状态：$($config.inGameValidation)
Copy BearaiProfessionMail to this client's Interface/AddOns and restart WoW.
将 BearaiProfessionMail 放入对应客户端 Interface/AddOns 后重启游戏。
Target / 目标：$($config.flavor), Interface $($config.interface)
License: MIT. See LICENSE.
Documentation: https://github.com/bearaicn/BearaiProfessionMail
Mirror: https://gitee.com/bearaicn/BearaiProfessionMail
"@ | Set-Content -LiteralPath (Join-Path $addon 'INSTALL.txt') -Encoding utf8
    $zip = Join-Path $output "BearaiProfessionMail-$version-$($config.flavor).zip"
    Compress-Archive -LiteralPath $addon -DestinationPath $zip -Force
    $checksums += "$((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant())  $([IO.Path]::GetFileName($zip))"
    Write-Output $zip
}
$checksums | Set-Content -LiteralPath (Join-Path $output 'SHA256SUMS.txt') -Encoding ascii
