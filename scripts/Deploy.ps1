[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Hardcore', 'Forever', 'Both')][string]$Client = 'Hardcore',
    [string]$GameRoot = 'D:\Games\World of Warcraft',
    [switch]$Apply
)
$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $PSScriptRoot
$toc = Join-Path $source 'BearaiProfessionMail.toc'
if (-not (Test-Path -LiteralPath $toc)) { throw '插件 TOC 不存在。' }
$clients = Get-Content -LiteralPath (Join-Path $source 'config\clients.json') -Raw | ConvertFrom-Json
$targets = if ($Client -eq 'Both') { @('Hardcore', 'Forever') } else { @($Client) }
$tocContent = Get-Content -LiteralPath $toc -Raw
$version = [regex]::Match($tocContent, '(?m)^## Version:\s*([^\r\n]+)').Groups[1].Value.Trim()
if (-not $version) { throw 'TOC 缺少插件版本。' }
$files = @('BearaiProfessionMail.toc') + @(Get-Content -LiteralPath $toc | Where-Object { $_ -match '\.lua$' })
# 严格白名单，只复制 TOC 和其显式声明的 Lua；不删除目标目录中的任何文件。
foreach ($file in $files) {
    if ($file -match '\.\.|^[/\\]|:') { throw "TOC 中存在非法路径：$file" }
    if (-not (Test-Path -LiteralPath (Join-Path $source $file))) { throw "缺少文件：$file" }
}
foreach ($targetName in $targets) {
    $config = $clients.$targetName
    if (-not $config -or $config.folder -notmatch '^_[a-z_]+_$' -or $config.interface -lt 10000) {
        throw "客户端配置无效：$targetName"
    }
    $clientRoot = Join-Path $GameRoot $config.folder
    if (-not (Test-Path -LiteralPath $clientRoot -PathType Container)) { throw "客户端不存在：$clientRoot" }
    $destination = [IO.Path]::GetFullPath((Join-Path $clientRoot 'Interface\AddOns\BearaiProfessionMail'))
    $generatedToc = [regex]::Replace($tocContent, '(?m)^## Interface:[^\r\n]*', "## Interface: $($config.interface)")
    Write-Output "目标：$destination；插件 $version；Interface $($config.interface)；$($files.Count) 个插件文件；执行：$Apply"
    if (-not $Apply) { continue }
    foreach ($file in $files) {
        $target = Join-Path $destination $file
        if ($PSCmdlet.ShouldProcess($target, '同步本插件文件')) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
            if ($file -eq 'BearaiProfessionMail.toc') {
                [IO.File]::WriteAllText($target, $generatedToc, [Text.UTF8Encoding]::new($false))
                if ([IO.File]::ReadAllText($target) -cne $generatedToc) { throw '生成 TOC 校验失败。' }
            } else {
                Copy-Item -LiteralPath (Join-Path $source $file) -Destination $target -Force
                if ((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath (Join-Path $source $file)).Hash) {
                    throw "同步后哈希不一致：$file"
                }
            }
        }
    }
    $manifestPath = Join-Path $destination 'deployment.json'
    if ($PSCmdlet.ShouldProcess($manifestPath, '记录部署版本及源码来源')) {
        $commit = & git -C $source rev-parse --verify HEAD 2>$null
        $dirty = @(& git -C $source status --porcelain).Count -gt 0
        $hashes = [ordered]@{}
        foreach ($file in $files) { $hashes[$file] = (Get-FileHash -LiteralPath (Join-Path $destination $file)).Hash }
        $manifest = [ordered]@{
            addonVersion = $version; target = $targetName; interface = $config.interface
            observedClientVersion = $config.observedVersion; observedAt = $config.observedAt
            deployedAt = [DateTimeOffset]::Now.ToString('o'); gitCommit = $commit
            workingTreeDirty = $dirty; inGameValidation = 'pending'; files = $hashes
        }
        $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
    }
}
