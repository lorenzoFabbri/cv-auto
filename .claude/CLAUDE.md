# cv-auto — working rules

`README.md` covers structure, setup, the content model and CI; read it before changing anything. The rules below are the ones that matter when editing the CV.

- ORCID is the source of truth for records. When a record is wrong or missing, the fix belongs on ORCID, not in code; say so instead of hard-coding it. Hand-written partials hold only what ORCID cannot (README, "Updating content").
- An edit to `_partials/X.qmd` needs the matching edit to `_partials/es/X.qmd`, in Spain Spanish.
- Detail lists are keyed by ORCID put-code. Look codes up with `curl -s -H "Accept: application/json" https://pub.orcid.org/v3.0/0000-0003-3031-322X/record`; never guess one.
- When ORCID gains or renames a role, degree or award title, update `ROLE_LABELS` in `R/render.R`: its keys are the exact ORCID strings, so a renamed title silently falls back to untranslated. Filters select records by put-code, never by title.
- Detail lines and the profile state only what ORCID, the existing CV or Lorenzo already says. Do not add claims about tools, data or results.
- `bios.md` is the one home for descriptions of Lorenzo: the website's About, Research and Now pages, the GitHub profile README (`lorenzoFabbri/lorenzoFabbri`), the ORCID biography and LinkedIn About (from its plain-text long bio) and the CVN summaries copy from it. Change it first, then the copies. Public texts name the research line and its methods but no drug classes or databases.
- The website (`~/Documents/personal/epilorenzo`) follows the CV; after a fact changes here, bring the site in line under its own `.claude/CLAUDE.md`.
- `/cv-sync` runs the full check against ORCID, the vault, the CVN export and the website, and ends with what Lorenzo must change by hand.
- Verify with `make lint`, `air format --check R/` and `make all`, then check the rendered text for the specific change in both languages: strip tags from `docs/<variant>.html`, and run `pdftotext -layout docs/<variant>.pdf -` for the PDF.
- A push to `main` redeploys the public CV at https://lorenzofabbri.github.io/cv-auto/, so confirm before pushing. Scheduled runs render only on the first Monday of the month.
- air is pinned in the workflow (`posit-dev/setup-air`, `version:`); bump it together with the local install in `~/.local/bin`.
