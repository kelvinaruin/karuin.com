Add-Type -AssemblyName System.IO.Compression.FileSystem

$sourceDir = ".\source-docs"
$articlesDir = ".\knowledge-base\articles"
$assetsDir = ".\knowledge-base\assets\images"

New-Item -ItemType Directory -Force -Path $articlesDir | Out-Null
New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null

function Convert-ToSlug {
    param([string]$name)

    $name = $name -replace '^TPT\s*-\s*',''
    $name = $name -replace '^SOP\s*-\s*',''
    $name = $name -replace '^SOW\s*-\s*',''

    $slug = $name.ToLower()
    $slug = $slug -replace '[^a-z0-9]+','-'
    $slug = $slug.Trim('-')
    return $slug
}

function Encode-Html {
    param([string]$text)
    return [System.Net.WebUtility]::HtmlEncode($text)
}

function Get-NodeText {
    param($node, $ns)

    $texts = $node.SelectNodes(".//w:t", $ns)
    $value = ""

    foreach ($t in $texts) {
        $value += $t.InnerText
    }

    return $value.Trim()
}

function Get-ParagraphStyle {
    param($p, $ns)

    $styleNode = $p.SelectSingleNode("./w:pPr/w:pStyle", $ns)
    if ($null -ne $styleNode) {
        return $styleNode.GetAttribute("val", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
    }

    return ""
}

$docs = Get-ChildItem $sourceDir -Filter *.docx

foreach ($doc in $docs) {

    Write-Host "Processing $($doc.Name)"

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($doc.Name)
    $slug = Convert-ToSlug $baseName

    $articlePath = Join-Path $articlesDir "$slug.html"
    $imageOutputDir = Join-Path $assetsDir $slug

    New-Item -ItemType Directory -Force -Path $imageOutputDir | Out-Null

    $tempZip = Join-Path $env:TEMP "$slug.zip"
    $extractPath = Join-Path $env:TEMP $slug

    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item $doc.FullName $tempZip -Force

    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $extractPath)

    $documentXmlPath = Join-Path $extractPath "word\document.xml"
    $relsPath = Join-Path $extractPath "word\_rels\document.xml.rels"

    if (!(Test-Path $documentXmlPath)) {
        Write-Warning "Skipping $($doc.Name). document.xml not found."
        continue
    }

    [xml]$documentXml = Get-Content $documentXmlPath -Raw
    [xml]$relsXml = if (Test-Path $relsPath) { Get-Content $relsPath -Raw } else { "<Relationships />" }

    $ns = New-Object System.Xml.XmlNamespaceManager($documentXml.NameTable)
    $ns.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
    $ns.AddNamespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
    $ns.AddNamespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")

    $relMap = @{}

    foreach ($rel in $relsXml.Relationships.Relationship) {
        if ($rel.Type -like "*image*") {
            $relMap[$rel.Id] = $rel.Target
        }
    }

    $bodyHtml = ""
    $imageCounter = 1

    $paragraphs = $documentXml.SelectNodes("//w:body/w:p", $ns)

    foreach ($p in $paragraphs) {

        $text = Get-NodeText $p $ns
        $style = Get-ParagraphStyle $p $ns
        $encodedText = Encode-Html $text

        $imageNodes = $p.SelectNodes(".//a:blip", $ns)

        if (![string]::IsNullOrWhiteSpace($text)) {

            if ($style -match "Heading1|Title") {
                $bodyHtml += "<section><h2>$encodedText</h2>`n"
            }
            elseif ($style -match "Heading2") {
                $bodyHtml += "<h3>$encodedText</h3>`n"
            }
            elseif ($text -match '^\d+\.\s+') {
                $bodyHtml += "<p>$encodedText</p>`n"
            }
            elseif ($text -match '^[·•]\s*') {
                $cleanBullet = $encodedText -replace '^[·•]\s*',''
                $bodyHtml += "<ul><li>$cleanBullet</li></ul>`n"
            }
            else {
                $bodyHtml += "<p>$encodedText</p>`n"
            }
        }

        foreach ($img in $imageNodes) {

            $embedId = $img.GetAttribute("embed", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")

            if ($relMap.ContainsKey($embedId)) {

                $target = $relMap[$embedId]
                $sourceImage = Join-Path (Join-Path $extractPath "word") $target

                if (Test-Path $sourceImage) {

                    $extension = [System.IO.Path]::GetExtension($sourceImage)
                    $newImageName = ("image-{0:D2}{1}" -f $imageCounter, $extension)
                    $destImage = Join-Path $imageOutputDir $newImageName

                    Copy-Item $sourceImage $destImage -Force

                    $imageUrl = "/knowledge-base/assets/images/$slug/$newImageName"
                    $altText = "$baseName screenshot $imageCounter"

                    $bodyHtml += @"
<figure>
    <img class="article-image" src="$imageUrl" alt="$altText">
    <figcaption>$altText</figcaption>
</figure>

"@

                    $imageCounter++
                }
            }
        }
    }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$baseName | Karuin KB</title>
    <meta name="description" content="$baseName knowledge base article.">
    <link rel="stylesheet" href="/knowledge-base/css/article.css">
</head>
<body>
    <main class="wrapper">
        <a class="back" href="/knowledge-base/">← Back to Knowledge Base</a>

        <div class="article-layout">
            <aside class="sidebar">
                <h3>Article Sections</h3>
                <a href="#article">Article</a>
                <a href="/knowledge-base/">Knowledge Base</a>
            </aside>

            <article class="article" id="article">
                <span class="status">Imported KB Article</span>

                <h1>$baseName</h1>

                <div class="meta">
                    <span class="pill">Status: Imported</span>
                    <span class="pill">Source: DOCX</span>
                    <span class="pill">Images: $($imageCounter - 1)</span>
                    <span class="pill">Last Updated: 2026</span>
                </div>

                $bodyHtml

                <p class="footer-note">
                    Karuin.com Knowledge Base · Imported from source documentation.
                </p>
            </article>
        </div>
    </main>
</body>
</html>
"@

    Set-Content -Path $articlePath -Value $html -Encoding UTF8

    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "KB conversion complete."