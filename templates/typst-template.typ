// Academic CV template for Quarto + Typst

#let accent  = rgb("#1a3a5c")
#let muted   = rgb("#6b7280")

// Section header with ruled line
#let cv-section(title) = {
  v(1.2em)
  text(size: 9pt, weight: "bold", fill: accent)[#upper(title)]
  v(3pt)
  line(length: 100%, stroke: 0.5pt + accent)
  v(0.5em)
}

#let cv-template(
  name:     "",
  tagline:  "",
  email:    "",
  website:  "",
  github:   "",
  orcid:    "",
  location: "",
  doc,
) = {
  set page(
    paper:  "a4",
    margin: (x: 1.8cm, top: 1.5cm, bottom: 1.5cm),
    footer: context [
      #set text(size: 7.5pt, fill: muted)
      #align(center)[#name --- CV --- #counter(page).display("1 of 1", both: true)]
    ]
  )

  set text(font: ("Helvetica Neue", "Arial"), size: 10pt)
  // spacing controls the gap between paragraphs (= between CV entries)
  set par(justify: false, leading: 0.55em, spacing: 0.9em)

  // Section headers (level 2)
  show heading.where(level: 2): it => cv-section(it.body)

  // Subsection headers (level 3)
  show heading.where(level: 3): it => {
    v(0.5em)
    text(size: 8.5pt, weight: "bold", fill: accent)[#upper(it.body)]
    v(2pt)
    line(length: 100%, stroke: 0.3pt + muted)
    v(0.35em)
  }

  show strong: it => text(weight: "semibold")[#it.body]

  // ---- Header ----
  // Clean up \@ escaping that Pandoc inserts for @ in Typst strings
  let clean-email = email.replace("\\@", "@")

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
      #set text(size: 8.5pt, fill: muted)
      #if clean-email != "" [#link("mailto:" + clean-email)[#clean-email] \ ]
      #if website  != "" [#link("https://" + website)[#website] \ ]
      #if github   != "" [#link("https://github.com/" + github)[github.com/#github] \ ]
      #if orcid    != "" [#link("https://orcid.org/" + orcid)[orcid.org/#orcid] \ ]
      #if location != "" [#location]
    ]
  )
  v(4pt)
  line(length: 100%, stroke: 0.8pt + accent)
  v(6pt)

  doc
}
