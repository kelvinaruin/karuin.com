# ProfWiz KB Article Package

Copy the included `knowledge-base` folder into the root of your local `karuin.com` repository.

This package contains:

- `knowledge-base/articles/intune-migration-with-profwiz.html`
- `knowledge-base/assets/images/profwiz/` with extracted DOCX images

The HTML already references images using paths such as:

```html
/knowledge-base/assets/images/profwiz/02-powershell-working-directory.png
```

After copying files into your repo, run:

```powershell
git add .
git commit -m "Convert ProfWiz DOCX to KB article with images"
git push
```
