library(orcidtr)
library(data.table)
#' ORCID identifier for the CV owner
ORCID_ID <- "0000-0003-3031-322X"

#' All public ORCID sections for the CV owner
#'
#' A named list of data.tables, one per ORCID section. A failed request stops
#' the render instead of dropping the section, so CI fails and Pages keeps the
#' last good CV; orcidtr already retries transient errors.
cv_data <- list(
  employments = orcid_employments(ORCID_ID),
  educations = orcid_educations(ORCID_ID),
  invited = orcid_invited_positions(ORCID_ID),
  fundings = orcid_funding(ORCID_ID),
  distinctions = orcid_distinctions(ORCID_ID),
  services = orcid_services(ORCID_ID),
  memberships = orcid_memberships(ORCID_ID),
  qualifications = orcid_qualifications(ORCID_ID),
  works = orcid_works(ORCID_ID)
)

# Display role titles consistently: ORCID stores "Postdoctoral Researcher",
# but the CV (and website) use "Postdoctoral Fellow" throughout.
if (!is.null(cv_data$employments) && nrow(cv_data$employments) > 0) {
  is_postdoc <- cv_data$employments$role == "Postdoctoral Researcher"
  cv_data$employments$role[is_postdoc] <- "Postdoctoral Fellow"
}

#' Works subsets by type — used directly in CV chunks
journal_articles <- cv_data$works[type == "journal-article"]
conference_papers <- cv_data$works[type == "conference-paper"]
posters <- cv_data$works[type == "conference-poster"]
software <- cv_data$works[type == "software"]

# CRAN DOIs carry the venue "CRAN: Contributed Packages"; "CRAN" reads better.
software[, journal := sub(": Contributed Packages$", "", journal)]
