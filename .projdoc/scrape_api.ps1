$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

$BaseUrl = "https://developer.gp.qq.com/api"
$OutputDir = "D:\Games\WeGameApps\rail_apps\OasisEraEditor(2001776)\ShadowTrackerExtra\UGCProjects\UGC01_Zombie\.projdoc\api"
$TreeUrl = "$BaseUrl/class/list/list.json"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "=== Peace Elite Oasis API Scraper ===" -ForegroundColor Cyan

$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8

# 1. Download tree.json
Write-Host "[1/3] Downloading tree structure..." -ForegroundColor Yellow
try {
    $treeJson = $wc.DownloadString($TreeUrl)
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$OutputDir\_tree.json", $treeJson, $utf8NoBom)
$treeRaw = $treeJson | ConvertFrom-Json
Write-Host "  Tree downloaded. Top-level dirs: $($treeRaw.Count)" -ForegroundColor Green

# 2. Extract all class paths
Write-Host "[2/3] Extracting class list..." -ForegroundColor Yellow

$classList = New-Object System.Collections.ArrayList
function Get-Classes($nodes) {
    foreach ($n in $nodes) {
        if ($n.Type -eq "class") {
            [void]$classList.Add(@{ Name = $n.Name; Label = $n.Label; Path = $n.Path })
        }
        if ($n.Children) {
            Get-Classes $n.Children
        }
    }
}
Get-Classes $treeRaw
Write-Host "  Total classes found: $($classList.Count)" -ForegroundColor Green

# 3. Download each class detail
Write-Host "[3/3] Downloading class details..." -ForegroundColor Yellow
$detailDir = "$OutputDir\details"
if (-not (Test-Path $detailDir)) { New-Item -ItemType Directory -Path $detailDir -Force | Out-Null }

$total = $classList.Count
$success = 0
$failed = 0
$ts = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()

for ($i = 0; $i -lt $total; $i++) {
    $item = $classList[$i]
    $rawPath = $item.Path

    if ($rawPath -match '^detail/class/(.+)$') {
        $restPath = $Matches[1]
    } elseif ($rawPath -match '^class/detail/(.+)$') {
        $restPath = $Matches[1]
    } else {
        $restPath = $rawPath
    }

    $safeName = $item.Name -replace '[\\/:*?"<>|]', '_'
    $outFile = Join-Path $detailDir "$safeName.json"

    if (Test-Path $outFile) { $success++; continue }

    try {
        $detailUrl = "$BaseUrl/class/detail/$restPath" + "?ts=$ts"
        $detailJson = $wc.DownloadString($detailUrl)
        [System.IO.File]::WriteAllText($outFile, $detailJson, $utf8NoBom)
        $success++
    } catch {
        Write-Host ("  FAIL: " + $item.Name) -ForegroundColor DarkYellow
        $failed++
    }

    if (($i + 1) % 30 -eq 0) {
        Write-Host ("  Progress: " + ($i+1) + "/" + $total + " (OK:" + $success + " FAIL:" + $failed + ")") -ForegroundColor Gray
    }
}
Write-Host ("  Done: " + $success + " downloaded, " + $failed + " failed") -ForegroundColor Green

# 4. Generate Markdown
Write-Host ""
Write-Host "[4/3] Generating Markdown docs..." -ForegroundColor Yellow
$mdDir = "$OutputDir\markdown"
if (-not (Test-Path $mdDir)) { New-Item -ItemType Directory -Path $mdDir -Force | Out-Null }

function Convert-DetailToMarkdown($detail) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# " + $detail.Name)
    [void]$sb.AppendLine("")
    if ($detail.Description) {
        [void]$sb.AppendLine($detail.Description)
        [void]$sb.AppendLine("")
    }
    if ($detail.Functions -and $detail.Functions.Count -gt 0) {
        [void]$sb.AppendLine("## Functions")
        [void]$sb.AppendLine("")
        foreach ($func in $detail.Functions) {
            $paramStr = ""
            if ($func.Params) {
                $pl = @()
                foreach ($p in $func.Params) { $pl += ($p.Type + " " + $p.Name) }
                $paramStr = ($pl -join ", ")
            }
            $retStr = ""
            if ($func.Return -and $func.Return.Count -gt 0 -and $func.Return[0].Type) {
                $retStr = $func.Return[0].Type
            }
            $sigLine = $retStr + " " + $func.Name + "(" + $paramStr + ")"
            [void]$sb.AppendLine("### " + $func.Name)
            [void]$sb.AppendLine("")
            $bt = [char]96 + [char]96 + [char]96
            [void]$sb.AppendLine($bt)
            [void]$sb.AppendLine($sigLine)
            [void]$sb.AppendLine($bt)
            [void]$sb.AppendLine("")
            if ($func.Description) {
                [void]$sb.AppendLine($func.Description)
                [void]$sb.AppendLine("")
            }
            if ($func.Params) {
                foreach ($p in $func.Params) {
                    if ($p.Description) {
                        [void]$sb.AppendLine("- **" + $p.Name + "** (" + $p.Type + "): " + $p.Description)
                    }
                }
                [void]$sb.AppendLine("")
            }
            if ($func.Return -and $func.Return.Count -gt 0) {
                foreach ($r in $func.Return) {
                    if ($r.Description) {
                        [void]$sb.AppendLine("- **Returns** (" + $r.Type + "): " + $r.Description)
                        [void]$sb.AppendLine("")
                    }
                }
            }
        }
    }
    if ($detail.Event -and $detail.Event.Count -gt 0) {
        [void]$sb.AppendLine("## Events")
        [void]$sb.AppendLine("")
        foreach ($evt in $detail.Event) {
            [void]$sb.AppendLine("### " + $evt.Name)
            [void]$sb.AppendLine("")
            if ($evt.Description) {
                [void]$sb.AppendLine($evt.Description)
                [void]$sb.AppendLine("")
            }
            if ($evt.Params) {
                foreach ($p in $evt.Params) {
                    if ($p.Description) {
                        [void]$sb.AppendLine("- **" + $p.Name + "** (" + $p.Type + "): " + $p.Description)
                    }
                }
                [void]$sb.AppendLine("")
            }
        }
    }
    if ($detail.Variables -and $detail.Variables.Count -gt 0) {
        [void]$sb.AppendLine("## Properties")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Name | Type | Description |")
        [void]$sb.AppendLine("|------|------|-------------|")
        foreach ($v in $detail.Variables) {
            $desc = ($v.Description -replace '\|', '\\|')
            [void]$sb.AppendLine("| " + $v.Name + " | " + $v.Type + " | " + $desc + " |")
        }
        [void]$sb.AppendLine("")
    }
    if ($detail.Delegate -and $detail.Delegate.Count -gt 0) {
        [void]$sb.AppendLine("## Delegates")
        [void]$sb.AppendLine("")
        foreach ($del in $detail.Delegate) {
            [void]$sb.AppendLine("### " + $del.Name)
            [void]$sb.AppendLine("")
            if ($del.Description) {
                [void]$sb.AppendLine($del.Description)
                [void]$sb.AppendLine("")
            }
        }
    }
    return $sb.ToString()
}

# Generate index.md
function Write-TreeToMarkdown($tree, $indent) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($node in $tree) {
        if ($node.Type -eq "directory") {
            [void]$sb.AppendLine($indent + "- **" + $node.Label + "**")
            if ($node.Children) {
                $childContent = Write-TreeToMarkdown $node.Children ($indent + "  ")
                [void]$sb.Append($childContent)
            }
        } elseif ($node.Type -eq "class") {
            $safeName = $node.Name -replace '[\\/:*?"<>|]', '_'
            [void]$sb.AppendLine($indent + "- [" + $node.Label + "](markdown/" + $safeName + ".md)")
        }
    }
    return $sb.ToString()
}

$indexSb = New-Object System.Text.StringBuilder
[void]$indexSb.AppendLine("# Oasis API Reference")
[void]$indexSb.AppendLine("")
[void]$indexSb.AppendLine("> Offline copy scraped from developer.gp.qq.com")
[void]$indexSb.AppendLine("")
[void]$indexSb.Append((Write-TreeToMarkdown $treeRaw ""))
[System.IO.File]::WriteAllText("$OutputDir\index.md", $indexSb.ToString(), $utf8NoBom)

# Generate per-class .md
$mdCount = 0
for ($i = 0; $i -lt $total; $i++) {
    $item = $classList[$i]
    $safeName = $item.Name -replace '[\\/:*?"<>|]', '_'
    $jsonFile = Join-Path $detailDir "$safeName.json"
    if (Test-Path $jsonFile) {
        try {
            $rawJson = [System.IO.File]::ReadAllText($jsonFile, [System.Text.Encoding]::UTF8)
            $detail = $rawJson | ConvertFrom-Json
            $md = Convert-DetailToMarkdown $detail
            $mdPath = Join-Path $mdDir "$safeName.md"
            [System.IO.File]::WriteAllText($mdPath, $md, $utf8NoBom)
            $mdCount++
        } catch {
            Write-Host ("  MD FAIL: " + $item.Name) -ForegroundColor DarkRed
        }
    }
}
Write-Host ("  Generated " + $mdCount + " markdown files") -ForegroundColor Green

Write-Host ""
Write-Host "=== ALL DONE ===" -ForegroundColor Cyan
Write-Host "Output: $OutputDir" -ForegroundColor Green
