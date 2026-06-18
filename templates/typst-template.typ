// Academic CV template for Quarto + Typst

#let accent  = rgb("#1a3a5c")
#let muted   = rgb("#6b7280")

// Section header with ruled line
#let cv-section(title) = {
  v(1.2em)
  text(size: 9pt, weight: "bold", fill: accent)[#upper(title)]
  v(3pt)
  line(length: 100%, stroke: 0.5pt + accent)
  v(0.4em)
}

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

  let es-months = ("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
  let today = datetime.today()
  let formatted-date = if lang == "es" {
    es-months.at(today.month() - 1) + " " + str(today.year())
  } else {
    today.display("[month repr:long] [year]")
  }

  set page(
    paper:  "a4",
    margin: (x: 1.8cm, top: 1.5cm, bottom: 1.5cm),
    footer: context [
      #set text(size: 7.5pt, fill: muted)
      #align(center)[
        #name --- CV --- #counter(page).display("1 of 1", both: true)
        #h(1em) | #h(1em)
        #updated-label: #formatted-date
      ]
    ]
  )

  // Liberation Sans is vendored in fonts/ (see _quarto.yml font-paths) so the CV
  // renders identically on every platform with no missing-font warnings.
  set text(font: "Liberation Sans", size: 9.5pt)
  set par(justify: false, leading: 0.55em, spacing: 0.9em)

  // Section headers (level 2)
  show heading.where(level: 2): it => cv-section(it.body)

  // Subsection headers (level 3) — compact
  show heading.where(level: 3): it => {
    v(0.3em)
    text(size: 8.5pt, weight: "bold", fill: accent)[#upper(it.body)]
    v(1pt)
    line(length: 100%, stroke: 0.3pt + muted)
    v(0.2em)
  }

  show strong: it => text(weight: "semibold")[#it.body]

  // Underline links
  show link: it => underline(offset: 2pt, stroke: 0.5pt + muted, it)

  // Clean table styling — no borders, compact
  set table(
    stroke: none,
    inset: (x: 6pt, y: 4pt),
  )
  show table.cell.where(y: 0): set text(weight: "semibold", fill: accent)

  // ---- Header ----
  let clean-email = email.replace("\\@", "@")

  // Font Awesome icons (vendored in fonts/) — professional contact icons that
  // render identically on every platform. Solid = generic icons, Brands = logos.
  let fa-solid(code) = text(font: "Font Awesome 6 Free", weight: "black", fill: accent)[#str.from-unicode(code)]
  let fa-brand(code) = text(font: "Font Awesome 6 Brands", fill: accent)[#str.from-unicode(code)]

  grid(
    columns: (1fr, auto),
    gutter: 12pt,
    [
      #text(size: 22pt, weight: "bold", fill: accent)[#name]
      #if tagline != "" {
        linebreak()
        text(size: 10pt, fill: muted)[#tagline]
      }
    ],
    align(right + horizon)[
      #set text(size: 8pt, fill: muted)
      #if clean-email != "" [#fa-solid(0xf0e0)#h(4pt)#link("mailto:" + clean-email)[#clean-email] \ ]
      #if location != "" [#fa-solid(0xf3c5)#h(4pt)#location \ ]
      #if website  != "" [#fa-solid(0xf0ac)#h(4pt)#link("https://" + website)[#website] \ ]
      #if orcid    != "" [#fa-brand(0xf8d2)#h(4pt)#link("https://orcid.org/" + orcid)[orcid.org/#orcid] \ ]
      #if scholar   != "" [#fa-brand(0xe63b)#h(4pt)#link("https://scholar.google.com/citations?user=" + scholar)[Google Scholar] \ ]
      #if github   != "" [#fa-brand(0xf09b)#h(4pt)#link("https://github.com/" + github)[github.com/#github] \ ]
      #if linkedin != "" [#fa-brand(0xf08c)#h(4pt)#link("https://linkedin.com/in/" + linkedin)[LinkedIn] \ ]
      #if bluesky  != "" [#fa-brand(0xe671)#h(4pt)#link("https://bsky.app/profile/" + bluesky)[Bluesky]]
    ]
  )
  v(4pt)
  line(length: 100%, stroke: 0.8pt + accent)
  v(4pt)

  doc
}
