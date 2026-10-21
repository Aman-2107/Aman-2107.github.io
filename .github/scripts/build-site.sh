#!/usr/bin/env bash
# Builds the site that GitHub Pages serves, into the directory given (default: _site).
#
#  1. Copies the files tracked in git (nothing else from the checkout).
#  2. Compiles Tailwind v3 from the classes the pages actually use.
#  3. In every page that loads the Tailwind Play CDN, swaps that script for the compiled
#     stylesheet, placed at the end of <head>: where the Play CDN puts its own <style>, so the
#     cascade stays as it was whatever <style> blocks the page has.
#  4. Stamps each sitemap <lastmod> with the date of the last commit to that file.
#
# Run by .github/workflows/pages.yml. Locally: bash .github/scripts/build-site.sh /tmp/site
set -euo pipefail

OUT=${1:-_site}
cd "$(git rev-parse --show-toplevel)"

rm -rf "$OUT"
mkdir -p "$OUT"
git ls-files -z | tar --null -T - -cf - | tar -xf - -C "$OUT"
rm -rf "$OUT/.github" "$OUT/tailwind.config.js" "$OUT/tailwind.input.css" "$OUT/_config.yml" "$OUT/README.md"

# CI sets TAILWIND to Tailwind's standalone CLI, pinned by checksum (pages.yml); local runs use npx.
if [ -n "${TAILWIND:-}" ]; then tw=("$TAILWIND"); else tw=(npx --yes tailwindcss@3.4.19); fi
"${tw[@]}" \
  --config tailwind.config.js \
  --input tailwind.input.css \
  --output "$OUT/assets/css/tailwind.css" \
  --minify
test -s "$OUT/assets/css/tailwind.css"

# GitHub Pages caches every file for 10 minutes and that cannot be changed, so the stylesheet's
# URL carries a hash of its contents: a page and its CSS always change together.
VERSION=$(sha256sum "$OUT/assets/css/tailwind.css" | cut -c1-10)

python3 - "$OUT" "$VERSION" <<'PY'
import pathlib, re, subprocess, sys

out, version = pathlib.Path(sys.argv[1]), sys.argv[2]
cdn = re.compile(r'[ \t]*<script src="https://cdn\.tailwindcss\.com[^"]*"></script>\r?\n?')
link = f'<link rel="stylesheet" href="/assets/css/tailwind.css?v={version}" />'

replaced = []
for page in sorted(out.glob('*.html')):
    html = page.read_text(encoding='utf-8')
    if not cdn.search(html):
        continue
    nl = '\r\n' if '\r\n' in html else '\n'
    html = cdn.sub('', html, count=1)
    head_end = re.search(r'</head\s*>', html, re.I)
    if not head_end:
        sys.exit(f'{page.name}: no </head>')
    html = html[:head_end.start()] + f'  {link}{nl}' + html[head_end.start():]
    page.write_text(html, encoding='utf-8')
    replaced.append(page.name)
    print(f'{page.name}: Tailwind Play CDN replaced by the compiled stylesheet')

if 'index.html' not in replaced:
    sys.exit('index.html has no line <script src="https://cdn.tailwindcss.com"></script> written exactly '
             'like that, so the compiled stylesheet has nowhere to go. Put that line back in its <head>.')
leftover = [p.name for p in out.glob('*.html') if 'cdn.tailwindcss.com' in p.read_text(encoding='utf-8')]
if leftover:
    sys.exit(f'Still loading the Play CDN: {leftover}')

# Sitemap: each URL's lastmod is the last commit that changed the file it points at.
sitemap = out / 'sitemap.xml'
if sitemap.exists():
    xml = sitemap.read_text(encoding='utf-8')
    def stamp(m):
        loc = m.group(1)
        path = re.sub(r'^https://amanjaiswal\.co\.uk/', '', loc) or 'index.html'
        if path.endswith('/'):
            path += 'index.html'
        date = subprocess.run(['git', 'log', '-1', '--format=%cs', '--', path],
                              capture_output=True, text=True).stdout.strip()
        return m.group(0) if not date else re.sub(r'<lastmod>[^<]*</lastmod>', f'<lastmod>{date}</lastmod>', m.group(0))
    xml = re.sub(r'<url>\s*<loc>([^<]+)</loc>\s*<lastmod>[^<]*</lastmod>\s*</url>', stamp, xml)
    sitemap.write_text(xml, encoding='utf-8')
PY

echo "Built $OUT (tailwind.css v=$VERSION, $(wc -c < "$OUT/assets/css/tailwind.css") bytes)"
