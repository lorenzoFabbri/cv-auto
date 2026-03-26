# Run once to bootstrap the project environment.
# After this, use renv::restore() to reproduce it on any machine.

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::init(bare = TRUE)

pkgs <- c(
  "orcidtr",     # ORCID data
  "rcrossref",   # CrossRef API for full publication metadata
  "data.table",  # fast tabular data (used by orcidtr)
  "glue",        # string interpolation
  "stringr",     # string helpers
  "lintr",       # linting
  "knitr",       # required by Quarto R engine
  "rmarkdown"    # required by Quarto R engine
)

renv::install(pkgs)
renv::snapshot()