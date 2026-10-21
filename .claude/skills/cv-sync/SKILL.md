---
name: cv-sync
description: Check Lorenzo's CV against ORCID, the Obsidian vault, the latest CVN export and the epilorenzo website; fix what belongs in cv-auto and the site; end with the list of changes he must make by hand on ORCID, the CVN and his profiles. Use when Lorenzo asks to sync, audit or update the CV, the bios or the website, or to find entries missing from them.
---

# CV sync

A sync reads every source before it edits anything, because most findings are disagreements between two sources and the fix depends on which one is right. ORCID wins for records, the vault wins for plans and dates Lorenzo has noted, and Lorenzo settles any conflict the two leave open; ask him with `AskUserQuestion` rather than picking. The PhD ended in September 2025 and was defended on 19 December 2025, so an ORCID end date of 2025-09 beside a CVN degree date of 19/12/2025 is consistent and is never reported.

## Sources, in this order

1. The ORCID record, saved to the session scratchpad and summarised by section and put-code:

   ```sh
   curl -s -H "Accept: application/json" https://pub.orcid.org/v3.0/0000-0003-3031-322X/record -o "$S/orcid.json"
   jq -r '
   def d: if . == null then "" else [.year.value, (.month.value // ""), (.day.value // "")] | map(select(. != null and . != "")) | join("-") end;
   def aff(sec; key): .["activities-summary"][sec]["affiliation-group"][]?.summaries[]?[key] | "\(.["put-code"]) | \(.["role-title"] // "") | \(.["department-name"] // "") | \(.organization.name) | \(.["start-date"] | d) → \(.["end-date"] | d)";
   "## person", (.person.biography.content // "no bio"), (.person.keywords.keyword[]?.content),
   "## employments", aff("employments"; "employment-summary"),
   "## educations", aff("educations"; "education-summary"),
   "## qualifications", aff("qualifications"; "qualification-summary"),
   "## distinctions", aff("distinctions"; "distinction-summary"),
   "## invited", aff("invited-positions"; "invited-position-summary"),
   "## memberships", aff("memberships"; "membership-summary"),
   "## services", aff("services"; "service-summary"),
   "## fundings", (.["activities-summary"].fundings.group[]?["funding-summary"][0] | "\(.["put-code"]) | \(.type) | \(.title.title.value) | \(.organization.name) | \(.["start-date"] | d) → \(.["end-date"] | d)"),
   "## works", (.["activities-summary"].works.group[]?["work-summary"][0] | "\(.["put-code"]) | \(.type) | \(.["publication-date"] | d) | \(.title.title.value) | \(.["journal-title"].value // "")")
   ' "$S/orcid.json"
   ```

2. The vault notes named in the memory note `obsidian-vault-cv-sources`: the degree notes' frontmatter and their "What to do and when" tables, `diary.md`, `work/postdoc-cnio/direction.md#Identity` for how the research line is described, and `reference/personal/cv.md` for the profiles to keep in step and its open tasks. Planning notes and research logs are plans, not records. Only `education/`, `work/postdoc-cnio/` and `projects/` are granted in `.claude/settings.local.json`, so reading `diary.md` and `cv.md` asks first; nothing else in the vault is read, because `diary.md` aside it holds private notes the CV does not need.
3. The newest `~/Downloads/cvn_*.pdf`, converted with `pdftotext -layout` into the scratchpad and read in full. If none is newer than the last sync, ask Lorenzo to export one from cvn.fecyt.es.
4. In this repo: `bios.md`, every partial in `_partials/` and `_partials/es/`, and `ROLE_LABELS` in `R/render.R`.
5. In `~/Documents/personal/epilorenzo`: `index.qmd`, `research/index.qmd`, `now.qmd`, `talks/talks_2025.yml` and `publications.yml`.

## Checks

Run these against the saved record, with `$S` the scratchpad:

```sh
awk '/^ROLE_LABELS/,/^\)/' R/render.R | grep -oE '^ +"[^"]+" =' | sed -E 's/^ +"(.*)" =$/\1/' | sort -u > "$S/keys.txt"
jq -r '.["activities-summary"] as $a | ([$a.employments, $a.educations, $a.qualifications, $a.distinctions, $a["invited-positions"], $a.memberships, $a.services][]["affiliation-group"][]?.summaries[]? | to_entries[0].value["role-title"] // empty), ($a.fundings.group[]?["funding-summary"][0].title.title.value) | sub(" \\[declined\\]$"; "")' "$S/orcid.json" | sed 's/^Postdoctoral Researcher$/Postdoctoral Fellow/' | sort -u > "$S/titles.txt"
comm -23 "$S/titles.txt" "$S/keys.txt"   # titles with no label
comm -13 "$S/titles.txt" "$S/keys.txt"   # labels for titles ORCID no longer has
jq -r '[.. | objects | .["put-code"]? // empty] | .[] | tostring' "$S/orcid.json" | sort -u > "$S/codes.txt"
grep -rhoE '"[0-9]{6,9}"' _partials | tr -d '"' | sort -u | comm -23 - "$S/codes.txt"   # detail keys with no record
```

A title with no label matters when it is a role, degree, award or working-group name that the Spanish CV should translate; English course titles and the proper names of awards, networks and membership categories stay as ORCID has them, while a course titled in Spanish gets an English label. Beyond the scripted checks, compare by reading:

- dates that disagree between ORCID, the vault, the CVN and the website;
- programmes whose start date in the vault has passed but which are not on ORCID;
- entries on ORCID that the CVN lacks, and CVN fields left empty (authors, signature position, URLs, directors);
- any text in `bios.md`, the partials, the website or the CVN summaries that contradicts `direction.md#Identity`;
- English left in the rendered Spanish CV: strip the tags from `docs/cv-academic-es.html` and read it.

## What the sync may change

Partials, in English and Spain Spanish together; `ROLE_LABELS` keys, which are the exact ORCID strings; `bios.md` first and then its copies on the website, under the website's own `.claude/CLAUDE.md`; and the memory notes when a fact about Lorenzo changes. A wrong or missing record is fixed on ORCID by Lorenzo and is never hard-coded here. Public texts name the research line and its methods but no drug classes or databases. Nothing is pushed until Lorenzo confirms, since a push to `main` redeploys the public CV and site.

Verify as `.claude/CLAUDE.md` says, and render the website with `make render` when its pages changed.

## Ending

Report the edits made, then the manual list grouped by where each fix goes: ORCID, the CVN (with the field and the `bios.md` block to paste), the vault, and each other profile in `reference/personal/cv.md` (Google Scholar, LinkedIn, Bluesky, the GitHub profile README). Say which items were checked and found consistent, and name anything that could not be checked.
