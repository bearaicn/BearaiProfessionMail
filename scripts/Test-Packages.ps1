param([ValidateSet('Hardcore','Forever','Both')][string]$Client = 'Hardcore')
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
foreach ($flavor in $flavors) {
    $file = Join-Path $output "BearaiProfessionMail-$version-$flavor.zip"
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
        $interface = if ($flavor -eq 'era') { 11509 } else { 16001 }
        if ($content -notmatch "(?m)^## Interface: $interface\r?`$" -or $content -notmatch "## Version: $([regex]::Escape($version))") { throw '包内 TOC 错误。' }
        foreach ($relative in $expected | Where-Object { $_ -match '\.(lua|tga)$' -or $_ -eq 'LICENSE' }) {
            $entry = $entries | Where-Object { $_.FullName.Replace('\','/') -eq "BearaiProfessionMail/$relative" }
            $stream = $entry.Open(); $sha = [Security.Cryptography.SHA256]::Create()
            try { $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') } finally { $sha.Dispose(); $stream.Dispose() }
            if ($hash -ne (Get-FileHash -LiteralPath (Join-Path $root $relative)).Hash) { throw "包内文件哈希不一致：$relative" }
        }
    } finally { $zip.Dispose() }
    $line = Get-Content -LiteralPath (Join-Path $output 'SHA256SUMS.txt') | Where-Object { $_.EndsWith([IO.Path]::GetFileName($file)) }
    if (-not $line -or ($line -split ' ')[0] -ne (Get-FileHash -LiteralPath $file).Hash.ToLowerInvariant()) { throw '安装包 SHA256 不符。' }
    Write-Output "PASS: $flavor 安装包结构、版本、源文件与 ZIP 哈希、LICENSE"
}
