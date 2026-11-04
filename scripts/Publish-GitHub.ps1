[CmdletBinding()]
param([ValidateSet('Hardcore','Forever','Titan','Both','All')][string]$Client = 'All')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$toc = Get-Content -LiteralPath (Join-Path $root 'BearaiProfessionMail.toc') -Raw
$version = [regex]::Match($toc, '(?m)^## Version:\s*([^\r\n]+)').Groups[1].Value.Trim()
$tag = "v$version"
$output = Join-Path $root ".tmp/releases/$tag"
& "$PSScriptRoot/Test-Packages.ps1" -Client $Client
if (-not $?) { throw '发布包校验失败。' }
$hadToken = -not [string]::IsNullOrEmpty($env:GH_TOKEN)
try {
    if (-not $hadToken) {
        $credential = "protocol=https`nhost=github.com`n`n" | git -c credential.interactive=false credential fill 2>$null
        if ($LASTEXITCODE -ne 0) { throw '没有可用的 GitHub 凭据，请先登录 GitHub CLI。' }
        foreach ($line in $credential) {
            if ($line.StartsWith('password=')) { $env:GH_TOKEN = $line.Substring(9) }
        }
        $credential = $null
    }
    $targets = switch ($Client) {
        'Hardcore' { @('era') }
        'Forever' { @('forever') }
        'Titan' { @('titan') }
        'Both' { @('era','forever') }
        'All' { @('era','forever','titan') }
    }
    $assets = @()
    foreach ($target in $targets) {
        $suffix = if ($target -eq 'era') { 'era' } else { "$target-experimental" }
        $assets += Join-Path $output "BearaiProfessionMail-$version-$suffix.zip"
    }
    $assets += Join-Path $output 'SHA256SUMS-ALL.txt'
    & gh release create $tag @assets --repo bearaicn/BearaiProfessionMail --verify-tag `
        --title "$tag - era / forever / titan 测试版" --prerelease `
        --notes-file (Join-Path $root "docs/releases/$tag.md")
    if ($LASTEXITCODE -ne 0) { throw 'GitHub Release 未创建，请检查权限或已有发行版；不自动覆盖。' }
    & gh release view $tag --repo bearaicn/BearaiProfessionMail --json url,tagName,isDraft,isPrerelease,assets
    if ($LASTEXITCODE -ne 0) { throw '发布后查询失败。' }
} finally {
    if (-not $hadToken -and (Test-Path Env:GH_TOKEN)) { Remove-Item Env:GH_TOKEN }
}
