# cv-auto

Automated bilingual CV built from [ORCID](https://orcid.org/0000-0003-3031-322X) data. Quarto renders it to HTML, PDF (Typst) and DOCX, and GitHub Actions redeploys it monthly to [GitHub Pages](https://lorenzofabbri.github.io/cv-auto/).

## Variants

| Variant | EN | ES |
|---------|----|----|
| Academic | `cv-academic` | `cv-academic-es` |
| Industry | `cv-industry` | `cv-industry-es` |

## Requirements

- R (>= 4.6)
- [Quarto](https://quarto.org/), stable release (CI installs the latest)
- [air](https://github.com/posit-dev/air) 0.12.0, the formatter; CI pins this version, so keep the local install in step
- lintr, for `make lint`; it is not in `renv.lock` because no project code depends on it

## Setup

After cloning:

```sh
Rscript -e 'install.packages("renv"); renv::activate(); renv::restore()'
Rscript -e 'renv::install("lintr")'   # only needed for make lint
```

`.Rprofile` and `renv/activate.R` are not tracked, so `renv::activate()` writes them; CI does the same through `r-lib/actions/setup-renv`.

## Usage

```sh
make all      # render HTML + PDF + DOCX
make html     # HTML only
make pdf      # PDF (Typst) only
make docx     # DOCX only
make lint     # run lintr on R/; fails on any lint
make format   # format R/ with air
make clean    # remove rendered outputs
```

## Updating content

Records come from ORCID at render time, so they are edited on ORCID rather than here: employments, education, research visits (ORCID invited positions), grants, distinctions, working groups (services), memberships, continuing education (qualifications) and works (journal articles, posters, contributed talks, software). Journal articles are enriched with authors and journal details from CrossRef, and posters with author lists from their DOI metadata. Where that metadata is wrong, `AUTHOR_NAME_FIXES` and `AUTHOR_LISTS` in `R/render.R` correct it per DOI. A failed ORCID, CrossRef or DOI request stops the render, so CI fails and Pages keeps the last good version.

Everything else is hand-written in `_partials/`: research interests, the industry profile, skills, the etverse entry, invited talks, peer review, working papers, and the detail lines under appointments and education. Detail lines are keyed by ORCID put-code, which the public API returns, e.g. `curl -H "Accept: application/json" https://pub.orcid.org/v3.0/0000-0003-3031-322X/employments`. Every partial has a Spanish twin in `_partials/es/`, and the two change together.

ORCID holds one language, so `ROLE_LABELS` in `R/render.R` translates role, degree and award titles into the CV language. A title without an entry appears as ORCID has it, so add one whenever ORCID gains a role.

## Project structure

```
R/
  data.R          # fetch CV data from ORCID
  render.R        # formatting, localisation and rendering helpers
_partials/        # shared CV sections (EN)
_partials/es/     # Spanish-language sections
templates/        # Typst + DOCX templates
assets/           # CSS for HTML output
fonts/            # vendored fonts for the Typst PDF
cv-*.qmd          # top-level CV documents
index.qmd         # landing page linking all variants
bios.md           # ready-to-paste bios (not rendered)
_quarto.yml       # Quarto project config
Makefile          # build targets
```

## CI/CD

GitHub Actions (`.github/workflows/render.yml`) runs on every push to `main`, on the first Monday of each month at 08:00 UTC, and on manual dispatch. Cron cannot express "first Monday", so the schedule fires every Monday and a gate job skips all but the first.

1. Lint: `air format --check` with the pinned air version, then lintr; any lint fails the job.
2. Render: restores the renv lockfile and builds every format with the latest stable Quarto.
3. Deploy: publishes `docs/` (HTML, PDF and DOCX) to GitHub Pages; the PDFs and DOCX files are also kept as a workflow artifact.
