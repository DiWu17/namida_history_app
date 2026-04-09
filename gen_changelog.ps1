param(
    [string]$Since = ""  # tag or commit, e.g. "v1.0.0". Empty = all commits
)

if ($Since) {
    $range = "$Since..HEAD"
    Write-Host "Generating changelog since $Since ..." -ForegroundColor Cyan
} else {
    $range = "HEAD"
    Write-Host "Generating changelog for all commits ..." -ForegroundColor Cyan
}

$logs = git log $range --pretty=format:"%s||%h" --no-merges 2>&1

$feats = @()
$fixes = @()
$refactors = @()
$others = @()

foreach ($line in $logs) {
    $parts = $line -split '\|\|', 2
    $msg = $parts[0].Trim()
    $hash = $parts[1].Trim()

    if ($msg -match '^feat[:\(]') {
        $feats += "- $($msg -replace '^feat[^:]*:\s*', '') ($hash)"
    } elseif ($msg -match '^fix[:\(]') {
        $fixes += "- $($msg -replace '^fix[^:]*:\s*', '') ($hash)"
    } elseif ($msg -match '^refactor[:\(]') {
        $refactors += "- $($msg -replace '^refactor[^:]*:\s*', '') ($hash)"
    } else {
        $others += "- $msg ($hash)"
    }
}

$version = (Select-String -Path "pubspec.yaml" -Pattern "^version:\s*(.+)$").Matches.Groups[1].Value
$versionName = ($version -split '\+')[0]
$date = Get-Date -Format "yyyy-MM-dd"

$output = "## v$versionName ($date)`n"

if ($feats.Count -gt 0) {
    $output += "`n### Features`n$($feats -join "`n")`n"
}
if ($fixes.Count -gt 0) {
    $output += "`n### Bug Fixes`n$($fixes -join "`n")`n"
}
if ($refactors.Count -gt 0) {
    $output += "`n### Refactors`n$($refactors -join "`n")`n"
}
if ($others.Count -gt 0) {
    $output += "`n### Others`n$($others -join "`n")`n"
}

Write-Host "`n$output" -ForegroundColor Green

$output | Set-Content -Path "CHANGELOG.md" -Encoding UTF8
Write-Host "Saved to CHANGELOG.md" -ForegroundColor Cyan
