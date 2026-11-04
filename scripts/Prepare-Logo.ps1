param(
    [string]$Source,
    [ValidateSet(64, 128, 256)][int]$Size = 128
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
if (-not $Source) { $Source = Join-Path $root 'Media\logo-bear-mail-v1.png' }
$original = [Drawing.Bitmap]::new([IO.Path]::GetFullPath($Source))
$image = [Drawing.Bitmap]::new($Size, $Size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($image)
try {
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($original, [Drawing.Rectangle]::new(0, 0, $Size, $Size))
} finally { $graphics.Dispose(); $original.Dispose() }
try {
    $png = Join-Path $root 'Media\logo-bear-mail-v1.png'
    $image.Save($png, [Drawing.Imaging.ImageFormat]::Png)
    # 无压缩 32 位 BGRA TGA，8 位 Alpha，左上原点；尺寸为 2 的幂。
    $stream = [IO.File]::Open((Join-Path $root 'Media\Logo.tga'), [IO.FileMode]::Create)
    $writer = [IO.BinaryWriter]::new($stream)
    try {
        $header = [byte[]]::new(18)
        $header[2] = 2
        $header[12] = $Size -band 255; $header[13] = $Size -shr 8
        $header[14] = $Size -band 255; $header[15] = $Size -shr 8
        $header[16] = 32; $header[17] = 40
        $writer.Write($header)
        for ($y = 0; $y -lt $Size; $y++) {
            for ($x = 0; $x -lt $Size; $x++) {
                $pixel = $image.GetPixel($x, $y)
                $writer.Write([byte]$pixel.B); $writer.Write([byte]$pixel.G)
                $writer.Write([byte]$pixel.R); $writer.Write([byte]$pixel.A)
            }
        }
    } finally { $writer.Dispose() }
    Write-Output "已生成 $Size × $Size 透明 PNG 及游戏 TGA。"
} finally { $image.Dispose() }
