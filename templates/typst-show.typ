// Quarto partial: applies the cv-template function with YAML front matter values
#import "templates/typst-template.typ": cv-template

#show: cv-template.with(
  name:     "$title$",
  tagline:  "$cv-tagline$",
  email:    "$cv-email$",
  website:  "$cv-website$",
  github:   "$cv-github$",
  orcid:    "$cv-orcid$",
  location: "$cv-location$",
)
