# cv-auto

Automated multilingual CV built from
[ORCID](https://orcid.org/0000-0003-3031-322X)
data. Renders to HTML, PDF (Typst), and DOCX
via Quarto, with weekly CI updates deployed
to GitHub Pages.

## Variants

| Variant | EN | ES |
|---------|----|----|
| Academic | `cv-academic` | `cv-academic-es` |
| Industry | `cv-industry` | `cv-industry-es` |

## Requirements

- R (>= 4.6)
- [Quarto](https://quarto.org/) (pre-release,
  for Typst support)
- [air](https://github.com/posit-dev/air)
  (formatter, optional for local dev)

## Setup

```sh
Rscript setup.R   # bootstrap renv
```

On subsequent clones:

```sh
Rscript -e "renv::restore()"
```

## Usage

```sh
make all      # render HTML + PDF + DOCX
make html     # HTML only
make pdf      # PDF (Typst) only
make docx     # DOCX only
make lint     # run lintr on R/
make format   # format R/ with air
make clean    # remove rendered outputs
```

## Project structure

```
R/
  data.R          # fetch CV data from ORCID
  render.R        # formatting/rendering helpers
_partials/        # shared CV sections (EN)
_partials/es/     # Spanish-language sections
templates/        # Typst + DOCX templates
assets/           # CSS for HTML output
cv-*.qmd          # top-level CV documents
index.qmd         # landing page linking all variants
_quarto.yml       # Quarto project config
Makefile          # build targets
setup.R           # one-time renv bootstrap
```

## CI/CD

GitHub Actions (`.github/workflows/render.yml`):

1. **Lint** — checks R formatting (air) and
   linting (lintr)
2. **Render** — builds all formats
3. **Deploy** — publishes HTML to GitHub Pages;
   archives PDF/DOCX as workflow artifacts

Runs on push to `main`, weekly (Monday 08:00
UTC), and manual dispatch.
