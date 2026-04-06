library(glue)
library(stringr)

# Markdown hard line break: backslash + newline.
# Defined as a constant because glue() strips a trailing `\` before `\n`.
BR <- "\\"

# Inline raw Typst that pushes subsequent content to the right.
# Silently ignored in non-Typst outputs (HTML, DOCX).
HFILL <- "`#h(1fr)`{=typst}"

# ---------------------------------------------------------------------------
# Date helpers
# ---------------------------------------------------------------------------

format_date <- function(d) {
  if (is.na(d) || d == "") {
    return("Present")
  }
  parts <- str_split(as.character(d), "-")[[1]]
  year <- parts[1]
  if (length(parts) >= 2 && !is.na(parts[2]) && parts[2] != "0") {
    months <- c(
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    )
    m <- suppressWarnings(as.integer(parts[2]))
    if (!is.na(m) && m >= 1 && m <= 12) return(paste(months[m], year))
  }
  year
}

format_date_range <- function(start, end) {
  s <- format_date(start)
  e <- format_date(end)
  if (s == e) s else paste0(s, " -- ", e)
}

# Sort a data.table by a date column (year prefix), most recent first
sort_by_year_desc <- function(dt, col) {
  dt[,
    .y := suppressWarnings(as.integer(str_extract(
      as.character(get(col)),
      "^\\d{4}"
    )))
  ]
  dt <- dt[order(-.y, na.last = TRUE)]
  dt[, .y := NULL]
  dt
}

# ---------------------------------------------------------------------------
# Affiliation sections
# ---------------------------------------------------------------------------

#' Render affiliation records (employment, education, invited, distinctions...)
#'
#' @param data      data.table returned by an orcidtr affiliation function.
#' @param show_dept Logical; include department column.
#' @param hide_end  Logical; suppress end date (useful for awards/distinctions).
#' @param details   Named list of extra detail strings keyed by ORCID put_code.
render_affiliations <- function(
  data,
  show_dept = TRUE,
  hide_end = FALSE,
  details = NULL
) {
  if (is.null(data) || nrow(data) == 0) {
    return(invisible(NULL))
  }

  dt <- as.data.table(data)
  dt <- sort_by_year_desc(dt, "start_date")

  lines <- vapply(
    seq_len(nrow(dt)),
    function(i) {
      row <- dt[i]
      role <- if (!is.na(row$role) && row$role != "") row$role else ""
      org <- if (!is.na(row$organization)) row$organization else ""
      dept <- if (show_dept && !is.na(row$department) && row$department != "") {
        row$department
      } else {
        ""
      }
      loc_parts <- c(row$city, row$country)
      loc <- paste(
        loc_parts[!is.na(loc_parts) & loc_parts != ""],
        collapse = ", "
      )
      dates <- if (hide_end) {
        format_date(row$start_date)
      } else {
        format_date_range(row$start_date, row$end_date)
      }

      org_parts <- c(
        if (nchar(org) > 0) paste0("*", org, "*"),
        if (nchar(dept) > 0) dept
      )
      org_str <- paste(org_parts[nchar(org_parts) > 0], collapse = " | ")

      loc_right <- if (nchar(loc) > 0) {
        glue(" {HFILL} {loc}")
      } else {
        ""
      }

      detail_line <- ""
      if (!is.null(details) && row$put_code %in% names(details)) {
        detail_line <- glue("{BR}\n{details[[row$put_code]]}")
      }

      glue(
        "**{role}** {HFILL} {dates}{BR}\n",
        "{org_str}{loc_right}{detail_line}\n"
      )
    },
    character(1)
  )

  cat(paste(lines, collapse = "\n\n"), "\n")
}

# ---------------------------------------------------------------------------
# Funding section
# ---------------------------------------------------------------------------

#' Render funding / grants records
#'
#' @param data data.table returned by `orcid_funding()`.
render_fundings <- function(data) {
  if (is.null(data) || nrow(data) == 0) {
    return(invisible(NULL))
  }

  dt <- as.data.table(data)
  dt <- sort_by_year_desc(dt, "start_date")

  lines <- vapply(
    seq_len(nrow(dt)),
    function(i) {
      row <- dt[i]
      title <- if (!is.na(row$title)) row$title else ""
      org <- if (!is.na(row$organization)) row$organization else ""
      dates <- format_date_range(row$start_date, row$end_date)

      amount_str <- ""
      if (!is.na(row$amount) && !is.na(row$currency)) {
        amount_str <- glue(
          " ({row$currency} {format(as.numeric(row$amount), big.mark = ',', scientific = FALSE)})"
        )
      }

      glue(
        "**{title}**{amount_str} {HFILL} {dates}{BR}\n",
        "*{org}*\n"
      )
    },
    character(1)
  )

  cat(paste(lines, collapse = "\n\n"), "\n")
}

# ---------------------------------------------------------------------------
# Publications
# ---------------------------------------------------------------------------

#' Highlight a surname in an author string with markdown bold
highlight_author <- function(author_str, pattern = "Fabbri") {
  str_replace_all(author_str, paste0("(\\b", pattern, "\\b[^,;]*)"), "**\\1**")
}

#' Format a CrossRef author list-column entry into "Family Initials, ..."
format_author_list <- function(authors_nested) {
  if (is.null(authors_nested) || length(authors_nested) == 0) {
    return("")
  }
  au <- tryCatch(as.data.frame(authors_nested), error = function(e) NULL)
  if (is.null(au) || nrow(au) == 0) {
    return("")
  }

  names_vec <- mapply(
    function(given, family) {
      initials <- paste0(str_extract_all(given, "\\b[A-Z]")[[1]], collapse = "")
      paste0(family, " ", initials)
    },
    au$given,
    au$family
  )

  paste(names_vec, collapse = ", ")
}

#' Render publications list enriched with CrossRef metadata
#'
#' @param works_dt       data.table of works from `orcid_works()`.
#' @param highlight_name Surname to bold in author lists.
#' @param fetch_crossref Logical; set FALSE to skip CrossRef.
render_publications <- function(
  works_dt,
  highlight_name = "Fabbri",
  fetch_crossref = TRUE
) {
  if (is.null(works_dt) || nrow(works_dt) == 0) {
    return(invisible(NULL))
  }

  dt <- as.data.table(works_dt)
  dt[, doi := tolower(trimws(doi))]
  has_doi <- !is.na(dt$doi) & dt$doi != ""
  enriched <- dt

  if (fetch_crossref && any(has_doi)) {
    cr <- tryCatch(
      rcrossref::cr_works(dois = dt$doi[has_doi])$data,
      error = function(e) NULL
    )
    if (!is.null(cr)) {
      cr_df <- as.data.frame(cr)
      cr_df$doi <- tolower(trimws(cr_df$doi))
      if ("container.title" %in% names(cr_df)) {
        names(cr_df)[names(cr_df) == "container.title"] <- "journal_cr"
      }
      enriched <- merge(
        as.data.frame(dt),
        cr_df,
        by = "doi",
        all.x = TRUE,
        suffixes = c("", "_cr")
      )
    }
  }

  enriched$.pub_year <- suppressWarnings(
    as.integer(str_extract(as.character(enriched$publication_date), "^\\d{4}"))
  )
  enriched <- enriched[order(-enriched$.pub_year, na.last = TRUE), ]
  enriched$.pub_year <- NULL

  lines <- vapply(
    seq_len(nrow(enriched)),
    function(i) {
      row <- enriched[i, ]

      title <- if (!is.na(row$title)) str_squish(row$title) else "(no title)"
      authors <- ""
      if ("author" %in% names(row) && !is.null(row$author[[1]])) {
        authors <- format_author_list(row$author[[1]])
        authors <- highlight_author(authors, highlight_name)
      }

      journal <- ""
      if ("journal_cr" %in% names(row) && !is.na(row$journal_cr)) {
        journal <- row$journal_cr
      } else if ("journal" %in% names(row) && !is.na(row$journal)) {
        journal <- row$journal
      }

      pub_date <- if (
        "published.print" %in% names(row) && !is.na(row$published.print)
      ) {
        row$published.print
      } else {
        row$publication_date
      }
      year <- if (!is.na(pub_date) && pub_date != "") {
        str_extract(as.character(pub_date), "^\\d{4}")
      } else {
        ""
      }

      vol_str <- ""
      if ("volume" %in% names(row) && !is.na(row$volume)) {
        vol_str <- row$volume
        if ("issue" %in% names(row) && !is.na(row$issue)) {
          vol_str <- paste0(vol_str, "(", row$issue, ")")
        }
        if ("page" %in% names(row) && !is.na(row$page)) {
          vol_str <- paste0(vol_str, ":", row$page)
        }
      }

      doi_str <- if (
        "doi" %in% names(row) && !is.na(row$doi) && row$doi != ""
      ) {
        glue("[doi:{row$doi}](https://doi.org/{row$doi})")
      } else {
        ""
      }

      parts <- c(
        if (nchar(authors) > 0) paste0(authors, "."),
        glue("{title}."),
        if (nchar(journal) > 0) paste0("*", journal, ".*"),
        if (nchar(year) > 0 || nchar(vol_str) > 0) {
          paste0(year, if (nchar(vol_str) > 0) paste0(";", vol_str), ".")
        },
        doi_str
      )
      paste(parts[nchar(parts) > 0], collapse = " ")
    },
    character(1)
  )

  cat(paste(paste0(seq_along(lines), ". ", lines), collapse = "\n\n"), "\n")
}

# ---------------------------------------------------------------------------
# Talks / Conferences / Posters / Software
# ---------------------------------------------------------------------------

#' Render talks, conference papers, posters, or software from ORCID works
#'
#' @param works_dt data.table filtered from `orcid_works()`.
#' @param number   Logical; prefix each entry with a number.
render_talks <- function(works_dt, number = FALSE) {
  if (is.null(works_dt) || nrow(works_dt) == 0) {
    return(invisible(NULL))
  }

  dt <- as.data.table(works_dt)
  dt <- sort_by_year_desc(dt, "publication_date")

  lines <- vapply(
    seq_len(nrow(dt)),
    function(i) {
      row <- dt[i]
      title <- if (!is.na(row$title)) row$title else "(no title)"
      conf <- if (!is.na(row$journal) && row$journal != "") row$journal else ""
      year <- if (!is.na(row$publication_date)) {
        str_extract(as.character(row$publication_date), "^\\d{4}")
      } else {
        ""
      }
      type_label <- switch(
        row$type,
        "lecture-speech" = "Invited talk",
        "conference-paper" = "Contributed talk",
        "conference-poster" = "Poster",
        "software" = "Software",
        "Talk"
      )
      url_str <- if (!is.na(row$url) && row$url != "") {
        glue(" [[link]]({row$url})")
      } else {
        ""
      }

      conf_str <- paste(c(if (nchar(conf) > 0) conf, year), collapse = ", ")
      glue("**{title}**{url_str}{BR}\n{type_label} | {conf_str}\n")
    },
    character(1)
  )

  if (number) {
    cat(paste(paste0(seq_along(lines), ". ", lines), collapse = "\n\n"), "\n")
  } else {
    cat(paste(lines, collapse = "\n\n"), "\n")
  }
}

# ---------------------------------------------------------------------------
# Memberships
# ---------------------------------------------------------------------------

#' Render professional memberships as a bullet list
render_memberships <- function(data) {
  if (is.null(data) || nrow(data) == 0) {
    return(invisible(NULL))
  }

  dt <- as.data.table(data)

  lines <- vapply(
    seq_len(nrow(dt)),
    function(i) {
      row <- dt[i]
      role <- if (!is.na(row$role) && row$role != "") row$role else ""
      org <- if (!is.na(row$organization)) row$organization else ""
      suffix <- if (nchar(role) > 0) paste0(" (", role, ")") else ""
      glue("- **{org}**{suffix}")
    },
    character(1)
  )

  cat(paste(lines, collapse = "\n"), "\n")
}
