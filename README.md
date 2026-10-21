# amanjaiswal.co.uk

Aman Jaiswal's personal site: one page, `index.html`, served by GitHub Pages at
https://amanjaiswal.co.uk/.

## How it is published

`.github/workflows/pages.yml` builds and deploys the site on every push to `main`, including
edits made on github.com. The build (`.github/scripts/build-site.sh`) compiles Tailwind from
the classes the page uses and swaps the `cdn.tailwindcss.com` script for that stylesheet, so
visitors never download the Tailwind compiler.

- It deploys only when **Settings → Pages → Build and deployment → Source** is
  **GitHub Actions**. While the source is "Deploy from a branch", GitHub publishes the branch
  as it is (the page then loads Tailwind from the CDN), and the workflow only checks the build.
- Keep the `<script src="https://cdn.tailwindcss.com">` line in `index.html`: it is what the
  build replaces, and what makes the page still work if the source is ever set back to the
  branch.
- `tailwind.config.js` and `tailwind.input.css` are build inputs; they are not published.
  `_config.yml` is used only by branch publishing.
- Fonts are self-hosted in `assets/fonts/` (Inter and Fira Code, OFL licences beside them).

## Search and sharing

- `sitemap.xml` lists the home page and the dissertation PDF. The build sets each `lastmod`
  from git history. Add the CV to it once the CV PDF names Duefree and says it is coming soon
  to Google Play and the App Store, as the page does (regenerate it in FlowCV, then set the
  PDF's Title, Subject, Keywords and Author again).
- The structured data (JSON-LD in `<head>`) describes the person this page is about. Keep it
  in step with what the page says.
- `assets/og-image.png` is the image LinkedIn, Slack, WhatsApp and X show. If it changes,
  save it under a new file name and update `og:image`, then re-scrape the page in LinkedIn's
  Post Inspector (LinkedIn caches previews).
- Keep the favicon URLs (`/favicon.ico`, `/favicon.svg`, `/favicon-96.png`,
  `/apple-touch-icon.png`) unchanged: Google caches the favicon it shows in results.

### When the job title or employer changes

Update these together: the `<title>`, the meta description, `og:title`, `og:description`,
`og:image:alt` and `twitter:image:alt`, the JSON-LD (`jobTitle`, `worksFor`, `description`,
and the ProfilePage `name`, which repeats the `<title>`), the hero's `#typewriter` text, the
About text and the Experience section. The og image shows the job title ("Founding
Engineer") but not the employer, so a new title needs a new og image, saved under a new file
name as above. The CV PDF's Title, Subject and Keywords name both; they were set after the
FlowCV export, so a new export needs them set again.
