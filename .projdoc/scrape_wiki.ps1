$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

$BaseUrl = "https://developer.gp.qq.com/wikieditor"
$OutputDir = "D:\Games\WeGameApps\rail_apps\OasisEraEditor(2001776)\ShadowTrackerExtra\UGCProjects\UGC01_Zombie\.projdoc\wiki"
$CatUrl = "$BaseUrl/_api/look-Category"
$ArticleUrl = "$BaseUrl/_api/query-articles"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "=== Peace Elite Wiki Scraper ===" -ForegroundColor Cyan

$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# 1. Download category tree
Write-Host "[1/4] Downloading category tree..." -ForegroundColor Yellow
try {
    $catRaw = $wc.DownloadData($CatUrl)
    $catText = [System.Text.Encoding]::UTF8.GetString($catRaw)
    [System.IO.File]::WriteAllText("$OutputDir\_category.json", $catText, $utf8NoBom)
    $catData = $catText | ConvertFrom-Json
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host "  Done." -ForegroundColor Green

# 2. Parse category tree and extract all article IDs
Write-Host "[2/4] Parsing category tree..." -ForegroundColor Yellow

$articles = New-Object System.Collections.ArrayList
$treeNodes = @()

foreach ($cat in $catData.data) {
    $catTitle = $cat.Title
    try {
        $bodyObj = $cat.Body | ConvertFrom-Json
    } catch {
        Write-Host "  WARN: Cannot parse Body for $catTitle" -ForegroundColor DarkYellow
        continue
    }
    $treeNodes += $bodyObj
}

function Extract-Articles($nodes, $parentPath) {
    foreach ($node in $nodes) {
        $label = $node.label
        $id = $node.id
        $type = $node.type
        $currentPath = if ($parentPath) { "$parentPath > $label" } else { $label }

        if ($type -eq 1) {
            [void]$articles.Add(@{
                Id = $id
                Label = $label
                Path = $currentPath
            })
        }
        if ($node.children -and $node.children.Count -gt 0) {
            Extract-Articles $node.children $currentPath
        }
    }
}

Extract-Articles $treeNodes ""
Write-Host "  Total articles: $($articles.Count)" -ForegroundColor Green

# 3. Download each article
Write-Host "[3/4] Downloading articles..." -ForegroundColor Yellow
$articleDir = "$OutputDir\articles"
if (-not (Test-Path $articleDir)) { New-Item -ItemType Directory -Path $articleDir -Force | Out-Null }

$total = $articles.Count
$success = 0
$failed = 0

for ($i = 0; $i -lt $total; $i++) {
    $item = $articles[$i]
    $id = $item.Id
    $safeName = "$id" + "_" + ($item.Label -replace '[\\/:*?"<>|]', '_')
    $outFile = Join-Path $articleDir "$safeName.json"

    if (Test-Path $outFile) { $success++; continue }

    try {
        $artRaw = $wc.DownloadData("$ArticleUrl" + "?Id=$id")
        $artText = [System.Text.Encoding]::UTF8.GetString($artRaw)
        [System.IO.File]::WriteAllText($outFile, $artText, $utf8NoBom)
        $success++
    } catch {
        Write-Host ("  FAIL: id=" + $id + " " + $item.Label) -ForegroundColor DarkYellow
        $failed++
    }

    if (($i + 1) % 20 -eq 0) {
        Write-Host ("  Progress: " + ($i+1) + "/" + $total + " (OK:" + $success + " FAIL:" + $failed + ")") -ForegroundColor Gray
    }
}
Write-Host ("  Done: " + $success + " downloaded, " + $failed + " failed") -ForegroundColor Green

# 4. Generate Markdown
Write-Host "[4/4] Generating Markdown..." -ForegroundColor Yellow
$mdDir = "$OutputDir\articles_md"
if (-not (Test-Path $mdDir)) { New-Item -ItemType Directory -Path $mdDir -Force | Out-Null }

# Generate index
function Write-TreeToMarkdown($nodes, $indent) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($node in $nodes) {
        $label = $node.label
        $id = $node.id
        $type = $node.type

        if ($type -eq 0) {
            [void]$sb.AppendLine($indent + "- **" + $label + "**")
            if ($node.children -and $node.children.Count -gt 0) {
                $childContent = Write-TreeToMarkdown $node.children ($indent + "  ")
                [void]$sb.Append($childContent)
            }
        } elseif ($type -eq 1) {
            $safeName = "$id" + "_" + ($label -replace '[\\/:*?"<>|]', '_')
            [void]$sb.AppendLine($indent + "- [" + $label + "](articles_md/" + $safeName + ".md)")
        }
    }
    return $sb.ToString()
}

$indexSb = New-Object System.Text.StringBuilder
[void]$indexSb.AppendLine("# Peace Elite Wiki (Offline)")
[void]$indexSb.AppendLine("")
[void]$indexSb.AppendLine("> Scraped from developer.gp.qq.com/wikieditor")
[void]$indexSb.AppendLine("")
$treeStr = Write-TreeToMarkdown $treeNodes ""
[void]$indexSb.Append($treeStr)
[System.IO.File]::WriteAllText("$OutputDir\index.md", $indexSb.ToString(), $utf8NoBom)

# Generate per-article .md files
$mdCount = 0
for ($i = 0; $i -lt $total; $i++) {
    $item = $articles[$i]
    $id = $item.Id
    $label = $item.Label
    $safeName = "$id" + "_" + ($label -replace '[\\/:*?"<>|]', '_')
    $jsonFile = Join-Path $articleDir "$safeName.json"

    if (Test-Path $jsonFile) {
        try {
            $rawJson = [System.IO.File]::ReadAllText($jsonFile, [System.Text.Encoding]::UTF8)
            $data = $rawJson | ConvertFrom-Json
            if ($data.data -and $data.data.Count -gt 0) {
                $article = $data.data[0]
                $title = $article.Title
                $body = $article.Body

                $mdContent = "# " + $title
                $mdContent += "`r`n`r`n> Wiki ID: $id | Path: " + $item.Path
                $mdContent += "`r`n`r`n" + $body

                $mdPath = Join-Path $mdDir "$safeName.md"
                [System.IO.File]::WriteAllText($mdPath, $mdContent, $utf8NoBom)
                $mdCount++
            }
        } catch {
            Write-Host ("  MD FAIL: id=" + $id + " " + $label) -ForegroundColor DarkRed
        }
    }
}
Write-Host ("  Generated " + $mdCount + " markdown files") -ForegroundColor Green

Write-Host ""
Write-Host "=== ALL DONE ===" -ForegroundColor Cyan
Write-Host "Output: $OutputDir" -ForegroundColor Green
Write-Host "  index.md         - Directory index" -ForegroundColor White
Write-Host "  articles_md/*.md - Wiki articles" -ForegroundColor White
