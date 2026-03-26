library(orcidtr)
library(data.table)
library(rcrossref)

#' ORCID identifier for the CV owner
ORCID_ID <- "0000-0003-3031-322X"

#' Fetch one ORCID section, returning an empty data.table on failure
#'
#' @param fn Function from orcidtr to call.
#' @param ... Arguments forwarded to `fn`.
#' @return A data.table (possibly empty).
safe_fetch <- function(fn, ...) {
  tryCatch(fn(...), error = function(e) {
    message("Warning: could not fetch ", deparse(substitute(fn)), ": ", e$message)
    data.table()
  })
}

#' All public ORCID sections for the CV owner
#'
#' A named list of data.tables, one per ORCID section.
cv_data <- list(
  employments    = safe_fetch(orcid_employments,       ORCID_ID),
  educations     = safe_fetch(orcid_educations,        ORCID_ID),
  invited        = safe_fetch(orcid_invited_positions, ORCID_ID),
  fundings       = safe_fetch(orcid_fundings,          ORCID_ID),
  distinctions   = safe_fetch(orcid_distinctions,      ORCID_ID),
  services       = safe_fetch(orcid_services,          ORCID_ID),
  memberships    = safe_fetch(orcid_memberships,       ORCID_ID),
  qualifications = safe_fetch(orcid_qualifications,    ORCID_ID),
  works          = safe_fetch(orcid_works,              ORCID_ID)
)

#' Works subsets by type — used directly in index.qmd chunks
journal_articles <- cv_data$works[type == "journal-article"]
preprints        <- cv_data$works[type %in% c("preprint", "posted-content")]
talks            <- cv_data$works[type %in% c("lecture-speech", "conference-paper")]
posters          <- cv_data$works[type == "conference-poster"]
software         <- cv_data$works[type == "software"]
