library(glue)
library(stringr)

# ---------------------------------------------------------------------------
# Date helpers
# ---------------------------------------------------------------------------

#' Format an ORCID date string to "Mon YYYY" or plain "YYYY"
#'
#' @param d Character scalar as returned by orcidtr (e.g. "2022-06" or "2022").
#'   NA or empty string is treated as an open-ended / current position.
#' @return A human-readable date string.
format_date <- function(d) {
  if (is.na(d) || d == "") return("Present")
  parts <- str_split(as.character(d), "-")[[1]]
  year  <- parts[1]
  if (length(parts) >= 2 && !is.na(parts[2]) && parts[2] != "0") {
    months <- c(
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    )
    m <- suppressWarnings(as.integer(parts[2]))
    if (!is.na(m) && m >= 1 && m <= 12) return(paste(months[m], year))
  }
  year
}

#' Format a start/end pair as "Mon YYYY -- Mon YYYY" (or "-- Present")
#'
#' @param start Character scalar; passed to `format_date()`.
#' @param end   Character scalar; passed to `format_date()`.
#' @return A date-range string.
format_date_range <- function(start, end) {
  s <- format_date(start)
  e <- format_date(end)
  if (s == e) s else paste0(s, " -- ", e)
}

# ---------------------------------------------------------------------------
# Affiliation sections
# ---------------------------------------------------------------------------

#' Render affiliation records (employment, education, invited, distinctions…)
#'
#' Writes pandoc markdown to stdout (consumed by `cat()` inside a knitr chunk).
#' Expected columns from orcidtr: organization, department, role, start_date,
#' end_date, city, region, country.
#'
#' @param data    data.table returned by an orcidtr affiliation function.
#' @param show_dept Logical; whether to include the department column.
#' @param reverse  Logical; whether to reverse row order (most-recent first).
#' @return Invisible NULL (side-effect: markdown written to stdout).
render_affiliations <- function(data, show_dept = TRUE, reverse = TRUE) {
  if (is.null(data) || nrow(data) == 0) return(invisible(NULL))

  dt <- as.data.table(data)
  if (reverse) dt <- dt[rev(seq_len(nrow(dt)))]

  lines <- vapply(seq_len(nrow(dt)), function(i) {
    row  <- dt[i]
    role <- if (!is.na(row$role) && row$role != "") row$role else ""
    org  <- if (!is.na(row$organization)) row$organization else ""
    dept <- if (show_dept && !is.na(row$department) && row$department != "")
      row$department else ""
    loc_parts <- c(row$city, row$country)
    loc       <- paste(loc_parts[!is.na(loc_parts) & loc_parts != ""], collapse = ", ")
    dates     <- format_date_range(row$start_date, row$end_date)

    org_line <- paste(
      c(
        if (nchar(org)  > 0) paste0("*", org, "*"),
        if (nchar(dept) > 0) dept,
        if (nchar(loc)  > 0) loc
      ),
      collapse = " | "
    )

    glue("**{role}** [{dates}]{{.cv-date}}\n\n{org_line}\n")
  }, character(1))

  cat(paste(lines, collapse = "\n"), "\n")
}

# ---------------------------------------------------------------------------
# Funding section
# ---------------------------------------------------------------------------

#' Render funding / grants records
#'
#' Expected columns from orcidtr: title, type, organization, start_date,
#' end_date, amount, currency.
#'
#' @param data    data.table returned by `orcid_fundings()`.
#' @param reverse Logical; most-recent first.
#' @return Invisible NULL (side-effect: markdown written to stdout).
render_fundings <- function(data, reverse = TRUE) {
  if (is.null(data) || nrow(data) == 0) return(invisible(NULL))

  dt <- as.data.table(data)
  if (reverse) dt <- dt[rev(seq_len(nrow(dt)))]

  lines <- vapply(seq_len(nrow(dt)), function(i) {
    row   <- dt[i]
    title <- if (!is.na(row$title)) row$title else ""
    org   <- if (!is.na(row$organization)) row$organization else ""
    dates <- format_date_range(row$start_date, row$end_date)

    amount_str <- ""
    if (!is.na(row$amount) && !is.na(row$currency)) {
      amount_str <- glue(
        " ({row$currency} {format(as.numeric(row$amount), big.mark = ',', scientific = FALSE)})"
      )
    }

    glue("**{title}**{amount_str} [{dates}]{{.cv-date}}\n\n*{org}*\n")
  }, character(1))

  cat(paste(lines, collapse = "\n"), "\n")
}

# ---------------------------------------------------------------------------
# Publications
# ---------------------------------------------------------------------------

#' Highlight a surname in an author string with markdown bold
#'
#' @param author_str Character scalar; a comma-separated author list.
#' @param pattern    Regex pattern matching the surname to bold.
#' @return Modified author string with the matching author in `**...**`.
highlight_author <- function(author_str, pattern = "Fabbri") {
  str_replace_all(author_str, paste0("(\\b", pattern, "\\b[^,;]*)"), "**\\1**")
}

#' Format a CrossRef author list-column entry into "Family Initials, …"
#'
#' @param authors_nested A list-column element (data.frame) from rcrossref.
#' @return A character scalar of comma-separated abbreviated author names.
format_author_list <- function(authors_nested) {
  if (is.null(authors_nested) || length(authors_nested) == 0) return("")
  au <- tryCatch(as.data.frame(authors_nested), error = function(e) NULL)
  if (is.null(au) || nrow(au) == 0) return("")

  names_vec <- mapply(function(given, family) {
    initials <- paste0(str_extract_all(given, "\\b[A-Z]")[[1]], collapse = "")
    paste0(family, " ", initials)
  }, au$given, au$family)

  paste(names_vec, collapse = ", ")
}

#' Render a publications list enriched with CrossRef metadata
#'
#' Fetches full citation data (author list, volume, issue, pages) from
#' CrossRef for entries that carry a DOI; falls back to ORCID-only data
#' for entries without one.  Outputs a numbered markdown list.
#'
#' @param works_dt      data.table of works from `orcid_works()`.
#' @param highlight_name Surname to bold in author lists.
#' @param fetch_crossref Logical; set FALSE to skip the CrossRef API call.
#' @return Invisible NULL (side-effect: markdown written to stdout).
render_publications <- function(works_dt,
                                highlight_name = "Fabbri",
                                fetch_crossref = TRUE) {
  if (is.null(works_dt) || nrow(works_dt) == 0) return(invisible(NULL))

  dt      <- as.data.table(works_dt)
  has_doi <- !is.na(dt$doi) & dt$doi != ""
  enriched <- dt

  if (fetch_crossref && any(has_doi)) {
    cr <- tryCatch(
      rcrossref::cr_works(dois = dt$doi[has_doi], .progress = FALSE)$data,
      error = function(e) NULL
    )
    if (!is.null(cr)) {
      cr_dt <- as.data.table(cr)
      setnames(
        cr_dt,
        intersect(names(cr_dt), "container.title"),
        "journal_cr"
      )
      enriched <- merge(dt, cr_dt, by = "doi", all.x = TRUE, suffixes = c("", "_cr"))
    }
  }

  lines <- vapply(seq_len(nrow(enriched)), function(i) {
    row <- enriched[i]

    title   <- if (!is.na(row$title)) str_squish(row$title) else "(no title)"
    authors <- ""
    if ("author" %in% names(row) && !is.null(row$author[[1]])) {
      authors <- format_author_list(row$author[[1]])
      authors <- highlight_author(authors, highlight_name)
    }

    journal <- ""
    if ("journal_cr" %in% names(row) && !is.na(row$journal_cr)) {
      journal <- row$journal_cr
    } else if (!is.na(row$journal)) {
      journal <- row$journal
    }

    pub_date <- if ("published.print" %in% names(row) && !is.na(row$published.print))
      row$published.print else row$publication_date
    year <- if (!is.na(pub_date) && pub_date != "")
      str_extract(as.character(pub_date), "^\\d{4}") else ""

    vol_str <- ""
    if ("volume" %in% names(row) && !is.na(row$volume)) {
      vol_str <- row$volume
      if ("issue" %in% names(row) && !is.na(row$issue)) vol_str <- paste0(vol_str, "(", row$issue, ")")
      if ("page"  %in% names(row) && !is.na(row$page))  vol_str <- paste0(vol_str, ":", row$page)
    }

    doi_str <- if (!is.na(row$doi) && row$doi != "")
      glue("[doi:{row$doi}](https://doi.org/{row$doi})") else ""

    parts <- c(
      if (nchar(authors) > 0) authors,
      glue("{title}."),
      if (nchar(journal) > 0) paste0("*", journal, ".*"),
      if (nchar(year) > 0 || nchar(vol_str) > 0)
        paste0(year, if (nchar(vol_str) > 0) paste0(";", vol_str), "."),
      doi_str
    )
    paste(parts[nchar(parts) > 0], collapse = " ")
  }, character(1))

  cat(paste(paste0(seq_along(lines), ". ", lines), collapse = "\n\n"), "\n")
}

# ---------------------------------------------------------------------------
# Talks / Conferences / Posters
# ---------------------------------------------------------------------------

#' Render talks, conference papers, or posters from ORCID works
#'
#' Works are expected to have type in
#' `c("lecture-speech", "conference-paper", "conference-poster")`.
#' The `journal` column is used as the venue/conference name.
#'
#' @param works_dt data.table filtered from `orcid_works()`.
#' @param reverse  Logical; most-recent first.
#' @return Invisible NULL (side-effect: markdown written to stdout).
render_talks <- function(works_dt, reverse = TRUE) {
  if (is.null(works_dt) || nrow(works_dt) == 0) return(invisible(NULL))

  dt <- as.data.table(works_dt)
  if (reverse) dt <- dt[rev(seq_len(nrow(dt)))]

  lines <- vapply(seq_len(nrow(dt)), function(i) {
    row   <- dt[i]
    title <- if (!is.na(row$title)) row$title else "(no title)"
    conf  <- if (!is.na(row$journal) && row$journal != "") row$journal else ""
    year  <- if (!is.na(row$publication_date))
      str_extract(as.character(row$publication_date), "^\\d{4}") else ""
    type_label <- switch(row$type,
      "lecture-speech"    = "Invited talk",
      "conference-paper"  = "Contributed talk",
      "conference-poster" = "Poster",
      "software"          = "Software",
      "Talk"
    )
    url_str <- if (!is.na(row$url) && row$url != "")
      glue(" [[link]]({row$url})") else ""

    conf_str <- paste(c(if (nchar(conf) > 0) conf, year), collapse = ", ")
    glue("**{title}**{url_str}\n\n{type_label} | {conf_str}\n")
  }, character(1))

  cat(paste(lines, collapse = "\n"), "\n")
}

# ---------------------------------------------------------------------------
# Memberships
# ---------------------------------------------------------------------------

#' Render professional memberships as a bullet list
#'
#' @param data    data.table returned by `orcid_memberships()`.
#' @param reverse Logical; reverse row order.
#' @return Invisible NULL (side-effect: markdown written to stdout).
render_memberships <- function(data, reverse = FALSE) {
  if (is.null(data) || nrow(data) == 0) return(invisible(NULL))

  dt <- as.data.table(data)
  if (reverse) dt <- dt[rev(seq_len(nrow(dt)))]

  lines <- vapply(seq_len(nrow(dt)), function(i) {
    row  <- dt[i]
    role <- if (!is.na(row$role) && row$role != "") row$role else ""
    org  <- if (!is.na(row$organization)) row$organization else ""
    suffix <- if (nchar(role) > 0) paste0(" (", role, ")") else ""
    glue("- **{org}**{suffix}")
  }, character(1))

  cat(paste(lines, collapse = "\n"), "\n")
}
