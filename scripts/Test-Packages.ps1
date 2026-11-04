param([ValidateSet('Hardcore','Forever','Titan','Both','All')][string]$Client = 'All', [switch]$AllowUntagged)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = Split-Path -Parent $PSScriptRoot
$toc = Get-Content -LiteralPath (Join-Path $root 'BearaiProfessionMail.toc') -Raw
$version = [regex]::Match($toc, '(?m)^## Version:\s*([^\r\n]+)').Groups[1].Value.Trim()
$output = Join-Path $root ".tmp/releases/v$version"
$expected = @('BearaiProfessionMail.toc','LICENSE','INSTALL.txt','release.json')
$expected += @($toc -split '\r?\n' | Where-Object { $_ -match '\.lua$' })
$expected += @(Get-Content -LiteralPath (Join-Path $root 'config/assets.json') -Raw | ConvertFrom-Json)
$flavors = if ($Client -eq 'Both') { @('era','forever') } elseif ($Client -eq 'Forever') { @('forever') } else { @('era') }
if ($Client -eq 'Titan') { $flavors = @('titan') }
if ($Client -eq 'All') { $flavors = @('era','forever','titan') }
foreach ($flavor in $flavors) {
    $suffix = if ($flavor -in @('forever','titan')) { "$flavor-experimental" } else { $flavor }
    $file = Join-Path $output "BearaiProfessionMail-$version-$suffix.zip"
    $zip = [IO.Compression.ZipFile]::OpenRead($file)
    try {
        $entries = @($zip.Entries | Where-Object { $_.Name })
        if ($entries.Count -ne $expected.Count) { throw '包内文件数量不符。' }
        foreach ($entry in $entries) {
            $relative = $entry.FullName.Replace('\','/') -replace '^BearaiProfessionMail/', ''
            if ($entry.FullName.Replace('\','/') -notmatch '^BearaiProfessionMail/' -or $relative -notin $expected) { throw "发布包含意外文件：$($entry.FullName)" }
        }
        $tocEntry = $entries | Where-Object { $_.Name -eq 'BearaiProfessionMail.toc' }
        $reader = [IO.StreamReader]::new($tocEntry.Open())
        try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
        $interface = @{era=11509;forever=16001;titan=38002}[$flavor]
        if ($content -notmatch "(?m)^## Interface: $interface\r?`$" -or $content -notmatch "## Version: $([regex]::Escape($version))") { throw '包内 TOC 错误。' }
        $metadataEntry = $entries | Where-Object { $_.Name -eq 'release.json' }
        $reader = [IO.StreamReader]::new($metadataEntry.Open())
        try { $metadata = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        $releaseCommit = if ($AllowUntagged) { (& git -C $root rev-parse HEAD).Trim() } else { (& git -C $root rev-list -n 1 "v$version").Trim() }
        if ($metadata.gitCommit -ne $releaseCommit -or (-not $AllowUntagged -and $metadata.workingTreeDirty) -or $metadata.interface -ne $interface) {
            throw '安装包来源不是干净的发布标签或目标不符。'
        }
        foreach ($relative in $expected | Where-Object { $_ -match '\.(lua|tga|md)$' -or $_ -eq 'LICENSE' }) {
            $entry = $entries | Where-Object { $_.FullName.Replace('\','/') -eq "BearaiProfessionMail/$relative" }
            $stream = $entry.Open(); $sha = [Security.Cryptography.SHA256]::Create()
            try { $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') } finally { $sha.Dispose(); $stream.Dispose() }
            if ($hash -ne (Get-FileHash -LiteralPath (Join-Path $root $relative)).Hash) { throw "包内文件哈希不一致：$relative" }
        }
    } finally { $zip.Dispose() }
    $sumFile = if (Test-Path -LiteralPath (Join-Path $output 'SHA256SUMS-ALL.txt')) { 'SHA256SUMS-ALL.txt' } else { 'SHA256SUMS.txt' }
    $line = Get-Content -LiteralPath (Join-Path $output $sumFile) | Where-Object { $_.EndsWith([IO.Path]::GetFileName($file)) }
    if (-not $line -or ($line -split ' ')[0] -ne (Get-FileHash -LiteralPath $file).Hash.ToLowerInvariant()) { throw '安装包 SHA256 不符。' }
    Write-Output "PASS: $flavor 安装包结构、版本、源文件与 ZIP 哈希、LICENSE"
}
