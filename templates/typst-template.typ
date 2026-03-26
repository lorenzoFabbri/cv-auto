// Modern academic CV template for Quarto + Typst

#let accent  = rgb("#1a3a5c")
#let muted   = rgb("#6b7280")
#let divider = rgb("#d1d5db")

// Reusable CV entry block
#let cv-entry(
  role:     "",
  org:      "",
  location: "",
  dates:    "",
  details:  none,
) = {
  block(below: 0.6em)[
    #grid(
      columns: (1fr, auto),
      gutter: 4pt,
      [
        #text(weight: "semibold")[#role] \
        #text(style: "italic", fill: muted)[
          #org#if location != "" [ | #location]
        ]
      ],
      align(right + top)[
        #text(size: 8.5pt, fill: muted)[#dates]
      ]
    )
    #if details != none {
      v(2pt)
      text(size: 9.5pt)[#details]
    }
  ]
}

// Section header with ruled line
#let cv-section(title) = {
  v(0.8em)
  stack(
    dir: ttb,
    spacing: 3pt,
    text(size: 9.5pt, weight: "bold", fill: accent)[#upper(title)],
    line(length: 100%, stroke: 0.6pt + accent),
  )
  v(0.4em)
}

// Re-export for use in show file
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
      #set text(size: 8pt, fill: muted)
      #align(center)[#name --- CV --- #counter(page).display("1 of 1", both: true)]
    ]
  )

  set text(font: ("Noto Sans", "Source Sans Pro", "Helvetica Neue", "Arial"), size: 10pt)
  set par(justify: false, leading: 0.55em)

  // Heading styles
  show heading.where(level: 2): it => cv-section(it.body)
  show heading.where(level: 3): it => {
    v(0.4em)
    text(size: 9.5pt, style: "italic", fill: muted)[#it.body]
    v(0.2em)
  }

  // Style .cv-date spans (produced by render.R via [text]{.cv-date})
  // These come through as emphasis in Typst; handled via padding
  show strong: it => text(weight: "semibold")[#it.body]

  // ---- Header ----
  grid(
    columns: (1fr, auto),
    gutter: 12pt,
    [
      #text(size: 24pt, weight: "bold", fill: accent)[#name]
      #if tagline != "" {
        linebreak()
        text(size: 10pt, fill: muted)[#tagline]
      }
    ],
    align(right + horizon)[
      #set text(size: 8.5pt)
      #if email    != "" [#link("mailto:" + email)[#email] \ ]
      #if website  != "" [#link("https://" + website)[#website] \ ]
      #if github   != "" [#link("https://github.com/" + github)[github.com/#github] \ ]
      #if orcid    != "" [#link("https://orcid.org/" + orcid)[orcid.org/#orcid] \ ]
      #if location != "" [#location]
    ]
  )
  v(4pt)
  line(length: 100%, stroke: 1pt + accent)
  v(6pt)

  doc
}
