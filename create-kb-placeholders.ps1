$articles = @(
            background: linear-gradient(180deg,#06080c,#090d13);
            color: var(--text);
            font-family: Inter, Arial, sans-serif;
            line-height: 1.7;
        }

        .container {
            width: min(900px, calc(100% - 40px));
            margin: 0 auto;
            padding: 80px 0;
        }

        .back {
            display: inline-block;
            margin-bottom: 30px;
            color: var(--accent);
            text-decoration: none;
        }

        .card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 24px;
            padding: 40px;
        }

        h1 {
            margin-top: 0;
            font-size: 3rem;
            line-height: 1;
            letter-spacing: -0.05em;
        }

        .status {
            display: inline-block;
            padding: 8px 14px;
            border-radius: 999px;
            background: rgba(102,227,255,0.1);
            border: 1px solid rgba(102,227,255,0.2);
            color: #bff4ff;
            font-size: 0.85rem;
            margin-bottom: 24px;
        }

        p {
            color: var(--muted);
        }
    </style>
</head>
<body>
    <div class="container">
        <a class="back" href="/knowledge-base/">← Back to Knowledge Base</a>

        <div class="card">
            <div class="status">Article In Development</div>
            <h1>ARTICLE_TITLE</h1>

            <p>
                This article placeholder has been created as part of the Karuin knowledge base launch.
            </p>

            <p>
                Full technical documentation, deployment steps, validation procedures, rollback guidance, diagrams, scripts, and supporting media will be added in a future revision.
            </p>
        </div>
    </div>
</body>
</html>
"@

foreach ($article in $articles) {

    $title = ($article -replace '-', ' ' | ForEach-Object {
        (Get-Culture).TextInfo.ToTitleCase($_)
    })

    $content = $template.Replace("ARTICLE_TITLE", $title)

    $path = ".\knowledge-base\articles\$article.html"

    Set-Content -Path $path -Value $content -Encoding UTF8
}