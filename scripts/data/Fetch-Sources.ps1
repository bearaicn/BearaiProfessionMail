[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$clients = Get-Content (Join-Path $root 'config/clients.json') -Raw | ConvertFrom-Json
$stage = Join-Path $root ('.tmp/material-source-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $stage | Out-Null
$entries = @()
foreach ($name in @('Hardcore', 'Titan', 'Forever')) {
    $client = $clients.$name
    $files = @()
    foreach ($table in @('SkillLineAbility', 'SpellReagents')) {
        $url = "https://wago.tools/db2/$table/csv?build=$($client.observedVersion)"
        $relative = "wago/$($client.flavor)/$table.csv"
        $path = Join-Path $stage $relative
        New-Item -ItemType Directory -Force (Split-Path -Parent $path) | Out-Null
        Invoke-WebRequest $url -TimeoutSec 60 -OutFile $path
        $header = Get-Content $path -TotalCount 1
        if (($header -split ',') -notcontains 'ID' -or (Get-Item $path).Length -lt 500) { throw "无效 CSV：$url" }
        $files += [ordered]@{ table=$table; path=$relative; url=$url; sha256=(Get-FileHash $path).Hash.ToLowerInvariant() }
    }
    $entries += [ordered]@{
        flavor=$client.flavor; build=$client.observedVersion; interface=$client.interface
        retrievedAt=[DateTimeOffset]::Now.ToString('o'); files=$files
    }
}
# 所有下载成功后才更新工作区；随后生成器会检查哈希和字段。
$destination = Join-Path $root 'data-sources'
New-Item -ItemType Directory -Force $destination | Out-Null
foreach ($entry in $entries) {
    foreach ($file in $entry.files) {
        $target = Join-Path $destination $file.path
        New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath (Join-Path $stage $file.path) -Destination $target -Force
    }
}
[ordered]@{ schema=1; provider='wago.tools'; sourceKind='Blizzard client DB2 facts'; clients=$entries } |
    ConvertTo-Json -Depth 8 | Set-Content (Join-Path $destination 'manifest.json') -Encoding utf8
Write-Output '已更新三客户端源快照；运行 npm run data:build 生成材料索引。'
