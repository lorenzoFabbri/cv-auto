// CV template for Quarto + Typst (all variants)

#let accent  = rgb("#1a3a5c")
#let muted   = rgb("#6b7280")

// Section header: uppercase label on a ruled line, kept with what follows
#let cv-section(title) = block(
  width: 100%, above: 1.3em, below: 0.6em, sticky: true,
  stroke: (bottom: 0.5pt + accent), inset: (bottom: 3pt),
  text(size: 9.5pt, weight: "bold", fill: accent, tracking: 0.04em)[#upper(title)],
)

#let cv-template(
  lang:     "en",
  name:     "",
  tagline:  "",
  email:    "",
  location: "",
  website:  "",
  orcid:    "",
  scholar:  "",
  github:   "",
  linkedin: "",
  bluesky:  "",
  doc,
) = {
  let updated-label = if lang == "es" { "Última actualización" } else { "Last updated" }
  // Page numbering pattern; "of" / "de" contain no Typst counting symbols.
  let page-pattern = if lang == "es" { "1 de 1" } else { "1 of 1" }

  let es-months = ("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
  let today = datetime.today()
  let formatted-date = if lang == "es" {
    es-months.at(today.month() - 1) + " de " + str(today.year())
  } else {
    today.display("[month repr:long] [year]")
  }

  set page(
    paper:  "a4",
    margin: (x: 1.8cm, top: 1.5cm, bottom: 1.5cm),
    footer: context [
      #set text(size: 7.5pt, fill: muted)
      #align(center)[
        #name --- CV --- #counter(page).display(page-pattern, both: true)
        #h(1em) | #h(1em)
        #updated-label: #formatted-date
      ]
    ]
  )

  // Liberation Sans is vendored in fonts/ (see _quarto.yml font-paths) so the CV
  // renders identically on every platform with no missing-font warnings.
  set text(font: "Liberation Sans", size: 9.5pt)
  set par(justify: false, leading: 0.55em, spacing: 0.9em)

  // Quarto shifts Typst headings up one level (the document title takes level
  // 0), so `##` sections arrive as level 1 and `###` subsections as level 2.
  show heading.where(level: 1): it => cv-section(it.body)
  show heading.where(level: 2): it => block(above: 0.9em, below: 0.5em, sticky: true,
    text(size: 9pt, weight: "bold", fill: muted)[#it.body])

  show strong: it => text(weight: "semibold")[#it.body]

  // Each CV entry is one paragraph with hard line breaks; keep it on one page.
  show par: it => block(breakable: false, it)

  // Clean table styling — no borders, compact, flush with the margin. Pandoc's
  // column widths already sum to 100%, so the gap is padding on the first
  // column rather than a column-gutter, which would overshoot the margin.
  set table(
    stroke: none,
    inset: (x, y) => (left: 0pt, right: if x == 0 { 1.2em } else { 0pt }, y: 3pt),
  )
  show table.cell.where(y: 0): set text(weight: "semibold", fill: accent)
  set table.hline(stroke: 0.5pt + accent)

  // ---- Header ----
  let clean-email = email.replace("\\@", "@")

  // Font Awesome icons (vendored in fonts/) — professional contact icons that
  // render identically on every platform. Solid = generic icons, Brands = logos.
  // The solid face registers as its own family; "Font Awesome 6 Free" at weight
  // black would resolve to Quarto's bundled Regular (outline) face instead.
  let fa-solid(code) = text(font: "Font Awesome 6 Free Solid", fill: accent)[#str.from-unicode(code)]
  let fa-brand(code) = text(font: "Font Awesome 6 Brands", fill: accent)[#str.from-unicode(code)]

  let items = ()
  if clean-email != "" { items.push((fa-solid(0xf0e0), link("mailto:" + clean-email)[#clean-email])) }
  if location != "" { items.push((fa-solid(0xf3c5), [#location])) }
  if website != "" { items.push((fa-solid(0xf0ac), link("https://" + website)[#website])) }
  if orcid != "" { items.push((fa-brand(0xf8d2), link("https://orcid.org/" + orcid)[orcid.org/#orcid])) }
  if github != "" { items.push((fa-brand(0xf09b), link("https://github.com/" + github)[github.com/#github])) }
  if scholar != "" { items.push((fa-brand(0xe63b), link("https://scholar.google.com/citations?user=" + scholar)[Google Scholar])) }
  if linkedin != "" { items.push((fa-brand(0xf08c), link("https://linkedin.com/in/" + linkedin)[LinkedIn])) }
  if bluesky != "" { items.push((fa-brand(0xe671), link("https://bsky.app/profile/" + bluesky)[Bluesky])) }

  // Two contact columns, filled top to bottom
  let rows = calc.ceil(items.len() / 2)
  let cells = ()
  for r in range(rows) {
    for c in (0, 1) {
      let i = c * rows + r
      if i < items.len() { cells += items.at(i) } else { cells += ([], []) }
    }
  }

  grid(
    columns: (1fr, auto),
    gutter: 12pt,
    align(left + horizon)[
      #text(size: 22pt, weight: "bold", fill: accent)[#name]
      #if tagline != "" {
        linebreak()
        // Break multi-part taglines at the "·" instead of leaving one word alone
        text(size: 9.5pt, fill: muted, tagline.split(" · ").join(linebreak()))
      }
    ],
    align(right + horizon, {
      set text(size: 8pt, fill: muted)
      grid(columns: (1em, auto, 1em, auto), column-gutter: (3pt, 12pt, 3pt), row-gutter: 5pt,
        align: (center + horizon, left + horizon, center + horizon, left + horizon), ..cells)
    })
  )
  v(4pt)
  line(length: 100%, stroke: 0.8pt + accent)
  v(4pt)

  // Underline links in the body only; the header icons already mark them.
  show link: it => underline(offset: 2pt, stroke: 0.5pt + muted, it)
  doc
}
