$articlesDir = ".\knowledge-base\articles"
$indexPath = ".\knowledge-base\index.html"

function Get-ArticleTitle {
    param([string]$filePath)

    $content = Get-Content $filePath -Raw

    if ($content -match "<h1[^>]*>(.*?)</h1>") {
        return ($matches[1] -replace "<.*?>", "").Trim()
    }

    return [System.IO.Path]::GetFileNameWithoutExtension($filePath) -replace "-", " "
}

function Get-ArticleDescription {
    param([string]$filePath)

    $content = Get-Content $filePath -Raw

    if ($content -match '<meta name="description" content="([^"]+)"') {
        return $matches[1].Trim()
    }

    if ($content -match '<p class="summary"[^>]*>(.*?)</p>') {
        return (($matches[1] -replace "<.*?>", "") -replace "\s+", " ").Trim()
    }

    return "Knowledge base article."
}

function Get-Category {
    param([string]$title)

    switch -Regex ($title) {
        "Intune|Autopilot|Provisioning|Endpoint|Windows Device" { return "Intune & Endpoint" }
        "Exchange|O365|Office 365|Microsoft 365|Entra|Conditional Access|Mimecast" { return "Cloud & Identity" }
        "DNS|DHCP|Active Directory|Domain|OU|Certificate|ADCS" { return "Infrastructure" }
        "VMware|ESXi|Hyper-V|Nutanix|Datto|Virtual Machine" { return "Virtualization" }
        "Backup|Restore|Recovery|Replication|Shadow Copies" { return "Backup & Recovery" }
        "VPN|Umbrella|Firewall|Network" { return "Networking" }
        "PowerShell|Script|Automation" { return "Automation" }
        "iOS|Outlook|Email|User" { return "User Support" }
        default { return "General" }
    }
}

$files = Get-ChildItem $articlesDir -Filter *.html | Sort-Object Name

$articleCards = ""

foreach ($file in $files) {
    $title = Get-ArticleTitle $file.FullName
    $description = Get-ArticleDescription $file.FullName
    $category = Get-Category $title
    $url = "/knowledge-base/articles/$($file.Name)"

    $articleCards += @"
<a class="article-card" href="$url" data-category="$category" data-search="$title $description $category">
    <div class="article-meta">
        <span class="pill accent">$category</span>
        <span class="pill">KB Article</span>
    </div>
    <h3>$title</h3>
    <p>$description</p>
    <div class="article-footer">
        <span>Status: Published</span>
        <span>Open →</span>
    </div>
</a>

"@
}

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Knowledge Base | Karuin</title>
    <meta name="description" content="Karuin Knowledge Base for infrastructure, cloud, identity, endpoint, virtualization, backup, and automation documentation.">

    <style>
        :root {
            --bg: #07090d;
            --card: rgba(255,255,255,0.055);
            --card-hover: rgba(255,255,255,0.082);
            --border: rgba(255,255,255,0.11);
            --text: #f5f7fb;
            --muted: #a5adba;
            --muted-2: #737d8c;
            --accent: #66e3ff;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            background:
                radial-gradient(circle at top left, rgba(102,227,255,0.12), transparent 34rem),
                linear-gradient(180deg,#06080c,#090d13);
            color: var(--text);
            font-family: Inter, Arial, sans-serif;
        }

        body::before {
            content: "";
            position: fixed;
            inset: 0;
            background-image:
                linear-gradient(rgba(255,255,255,0.032) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255,255,255,0.032) 1px, transparent 1px);
            background-size: 48px 48px;
            pointer-events: none;
            z-index: -1;
        }

        a { color: inherit; text-decoration: none; }

        .shell {
            width: min(1180px, calc(100% - 40px));
            margin: 0 auto;
        }

        .nav {
            position: sticky;
            top: 0;
            z-index: 20;
            backdrop-filter: blur(18px);
            background: rgba(7,9,13,0.72);
            border-bottom: 1px solid rgba(255,255,255,0.08);
        }

        .nav-inner {
            min-height: 72px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .brand {
            font-weight: 760;
            letter-spacing: -0.03em;
        }

        .nav-links {
            display: flex;
            gap: 22px;
            color: var(--muted);
            font-size: 0.94rem;
        }

        .hero {
            padding: 76px 0 36px;
        }

        h1 {
            margin: 0;
            font-size: clamp(3rem, 8vw, 5.9rem);
            line-height: 0.92;
            letter-spacing: -0.075em;
            max-width: 900px;
        }

        .gradient-text {
            background: linear-gradient(90deg,#f8fbff,#66e3ff 50%,#b69cff);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }

        .hero-copy {
            margin: 24px 0 0;
            color: var(--muted);
            font-size: 1.15rem;
            line-height: 1.65;
            max-width: 780px;
        }

        .toolbar {
            margin-top: 34px;
        }

        .search {
            width: 100%;
            min-height: 54px;
            padding: 0 20px;
            border: 1px solid rgba(255,255,255,0.13);
            border-radius: 999px;
            background: rgba(255,255,255,0.055);
            color: var(--text);
            outline: none;
            font-size: 1rem;
        }

        .section {
            padding: 42px 0 80px;
        }

        .article-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 16px;
        }

        .article-card {
            padding: 22px;
            border: 1px solid var(--border);
            background: var(--card);
            border-radius: 22px;
            min-height: 220px;
            transition: transform 180ms ease, border-color 180ms ease, background 180ms ease;
        }

        .article-card:hover {
            transform: translateY(-4px);
            border-color: rgba(102,227,255,0.32);
            background: var(--card-hover);
        }

        .article-meta {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 16px;
        }

        .pill {
            display: inline-flex;
            align-items: center;
            min-height: 26px;
            padding: 0 10px;
            border-radius: 999px;
            border: 1px solid rgba(255,255,255,0.11);
            background: rgba(255,255,255,0.045);
            color: var(--muted);
            font-size: 0.76rem;
        }

        .pill.accent {
            color: #bdf4ff;
            border-color: rgba(102,227,255,0.24);
            background: rgba(102,227,255,0.08);
        }

        .article-card h3 {
            margin: 0 0 10px;
            font-size: 1.3rem;
            line-height: 1.15;
            letter-spacing: -0.035em;
        }

        .article-card p {
            margin: 0 0 18px;
            color: var(--muted);
            line-height: 1.58;
        }

        .article-footer {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            color: var(--muted-2);
            font-size: 0.87rem;
        }

        .empty {
            display: none;
            padding: 28px;
            border: 1px solid var(--border);
            border-radius: 22px;
            background: rgba(255,255,255,0.046);
            color: var(--muted);
        }

        footer {
            border-top: 1px solid rgba(255,255,255,0.08);
            padding: 34px 0;
            color: var(--muted-2);
            font-size: 0.92rem;
        }

        @media (max-width: 800px) {
            .article-grid {
                grid-template-columns: 1fr;
            }

            .nav-links {
                display: none;
            }
        }
    </style>
</head>
<body>
    <header class="nav">
        <div class="shell nav-inner">
            <a class="brand" href="/">Karuin</a>
            <nav class="nav-links">
                <a href="/">Home</a>
                <a href="/knowledge-base/">Knowledge Base</a>
                <a href="/videos/">Videos</a>
                <a href="/labs/">Labs</a>
            </nav>
        </div>
    </header>

    <main>
        <section class="hero">
            <div class="shell">
                <h1>Knowledge Base for <span class="gradient-text">infrastructure operations.</span></h1>
                <p class="hero-copy">
                    Searchable deployment guides, lab notes, automation references, troubleshooting articles, and repeatable implementation procedures.
                </p>

                <div class="toolbar">
                    <input id="searchInput" class="search" type="search" placeholder="Search articles, platforms, tools, tags..." autocomplete="off">
                </div>
            </div>
        </section>

        <section class="section">
            <div class="shell">
                <div class="article-grid" id="articleGrid">
$articleCards
                </div>

                <div class="empty" id="emptyState">
                    No matching articles found.
                </div>
            </div>
        </section>
    </main>

    <footer>
        <div class="shell">
            © 2026 Karuin Knowledge Base · Infrastructure · Automation · Labs · Documentation
        </div>
    </footer>

    <script>
        const searchInput = document.getElementById('searchInput');
        const cards = Array.from(document.querySelectorAll('.article-card'));
        const emptyState = document.getElementById('emptyState');

        function applySearch() {
            const query = (searchInput.value || '').toLowerCase().trim();
            let visible = 0;

            cards.forEach(card => {
                const searchable = (card.innerText + ' ' + (card.dataset.search || '')).toLowerCase();
                const match = !query || searchable.includes(query);
                card.style.display = match ? '' : 'none';
                if (match) visible++;
            });

            emptyState.style.display = visible ? 'none' : 'block';
        }

        searchInput.addEventListener('input', applySearch);
    </script>
</body>
</html>
"@

Set-Content -Path $indexPath -Value $html -Encoding UTF8

Write-Host "KB index generated: $indexPath"
Write-Host "Articles indexed: $($files.Count)"