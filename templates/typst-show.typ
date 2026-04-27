// Quarto partial: applies the cv-template function with YAML front matter values
#import "templates/typst-template.typ": cv-template

#show: cv-template.with(
  lang:     "$lang$",
  name:     "$title$",
  tagline:  "$cv-tagline$",
  email:    "$cv-email$",
  location: "$cv-location$",
  website:  "$cv-website$",
  orcid:    "$cv-orcid$",
  scholar:  "$cv-scholar$",
  github:   "$cv-github$",
  linkedin: "$cv-linkedin$",
  bluesky:  "$cv-bluesky$",
)
