library(glue)
library(stringr)

# Markdown hard line break: backslash + newline.
# Defined as a constant because glue() strips a trailing `\` before `\n`.
BR <- "\\"

# Inline raw Typst and OpenXML that push subsequent content to the right; the
# DOCX tab relies on the right tab stops in templates/reference.docx. Ignored in
# HTML, where HTML_R floats the content instead.
HFILL <- "`#h(1fr)`{=typst}`<w:r><w:tab/></w:r>`{=openxml}"

# Raw-HTML wrapper that right-aligns its content (ignored in Typst / DOCX).
HTML_R <- '`<span class="cv-right">`{=html}'
HTML_R_END <- "`</span>`{=html}"

# ---------------------------------------------------------------------------
# Localization
# ---------------------------------------------------------------------------

cv_lang <- function() {
  lang <- getOption("cv.lang", default = NULL)
  if (is.null(lang) || !nzchar(lang)) {
    lang <- Sys.getenv("CV_LANG", unset = "en")
  }
  if (!lang %in% c("en", "es")) "en" else lang
}

MONTHS <- list(
  en = c(
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
  ),
  es = c(
    "ene",
    "feb",
    "mar",
    "abr",
    "may",
    "jun",
    "jul",
    "ago",
    "sep",
    "oct",
    "nov",
    "dic"
  )
)

PRESENT <- list(en = "Present", es = "actualidad")

IN_PROGRESS <- list(en = "In progress", es = "En curso")

LINK_LABEL <- list(en = "link", es = "enlace")

TYPE_LABELS <- list(
  en = list(
    "lecture-speech" = "Invited talk",
    "conference-paper" = "Contributed talk",
    "conference-poster" = "Poster",
    "software" = "Software",
    .default = "Talk"
  ),
  es = list(
    "lecture-speech" = "Ponencia invitada",
    "conference-paper" = "Comunicación oral",
    "conference-poster" = "Póster",
    "software" = "Software",
    .default = "Ponencia"
  )
)

type_label <- function(type) {
  labels <- TYPE_LABELS[[cv_lang()]]
  if (!is.null(labels[[type]])) labels[[type]] else labels$.default
}

# ORCID records hold one language, so role and award titles are translated into
# the CV language at render time. Keys are the exact ORCID strings (after the
# rename in data.R) without any " [declined]" suffix; a title with no entry is
# shown as ORCID has it, so a title edited on ORCID needs its key updated here.
# nolint start: line_length_linter.
ROLE_LABELS <- list(
  en = c(
    "Máster universitario de Análisis Económico" = "Master's Degree in Economic Analysis",
    "Máster de Formación Permanente en Salud Pública" = "Lifelong Learning Master's in Public Health",
    "Diploma de Experto Universitario en Métodos Avanzados de Estadística Aplicada" = "University Expert Diploma in Advanced Methods of Applied Statistics"
  ),
  es = c(
    "Postdoctoral Fellow" = "Investigador postdoctoral",
    "Predoctoral Researcher" = "Investigador predoctoral",
    "Student Research Assistant" = "Asistente de investigación (estudiante)",
    "PG Certificate in Public Health" = "Certificado de Posgrado en Salud Pública",
    "Graduate Certificate in Theoretical Statistics and Probability" = "Graduate Certificate en Estadística Teórica y Probabilidad (nivel de grado)",
    "PhD in Biomedicine" = "Doctorado en Biomedicina",
    "M.Sc. in Quantitative and Computational Biology" = "Máster en Biología Cuantitativa y Computacional",
    "M.Sc. Student in Computational Science" = "Estudiante de Máster en Ciencia Computacional",
    "B.Sc. in Biotechnology" = "Grado en Biotecnología",
    "Master's thesis" = "Trabajo de fin de máster",
    "Master's internship" = "Prácticas de máster",
    "Bachelor's thesis" = "Trabajo de fin de grado",
    "Student Tuition Waiver" = "Exención de matrícula para estudiantes",
    "SNRN Best Abstract Award (Student Researchers)" = "Premio SNRN al mejor resumen (categoría de estudiantes)",
    "Outstanding Abstract by a Student" = "Premio SNRN al mejor resumen (categoría de estudiantes)",
    "Erasmus+ Traineeship Programme Scholarship" = "Beca del programa Erasmus+ Prácticas",
    "Faculty of Informatics Scholarship" = "Beca de la Facultad de Informática"
  )
)
# nolint end

DECLINED <- list(en = "[declined]", es = "[declinada]")

localize_title <- function(x) {
  lang <- cv_lang()
  declined <- endsWith(x, " [declined]")
  base <- if (declined) str_remove(x, " \\[declined\\]$") else x
  labels <- ROLE_LABELS[[lang]]
  if (base %in% names(labels)) {
    base <- labels[[base]]
  }
  if (declined) paste(base, DECLINED[[lang]]) else base
}

FULL_MONTHS <- list(
  en = c(
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ),
  es = c(
    "enero",
    "febrero",
    "marzo",
    "abril",
    "mayo",
    "junio",
    "julio",
    "agosto",
    "septiembre",
    "octubre",
    "noviembre",
    "diciembre"
  )
)

# Today's month + year in the active CV language ("April 2026" /
# "abril de 2026"; Spanish joins month and year with "de")
format_today <- function() {
  lang <- cv_lang()
  m <- as.integer(format(Sys.Date(), "%m"))
  y <- format(Sys.Date(), "%Y")
  sep <- if (lang == "es") " de " else " "
  paste0(FULL_MONTHS[[lang]][m], sep, y)
}

# ---------------------------------------------------------------------------
# Date helpers
# ---------------------------------------------------------------------------

format_date <- function(d) {
  lang <- cv_lang()
  if (is.na(d) || d == "") {
    return(PRESENT[[lang]])
  }
  parts <- str_split(as.character(d), "-")[[1]]
  year <- parts[1]
  if (length(parts) >= 2 && !is.na(parts[2]) && parts[2] != "0") {
    m <- suppressWarnings(as.integer(parts[2]))
    if (!is.na(m) && m >= 1 && m <= 12) return(paste(MONTHS[[lang]][m], year))
  }
  year
}

format_date_range <- function(start, end) {
  s <- format_date(start)
  e <- format_date(end)
  if (s == e) s else paste0(s, " -- ", e)
}

# Sort a data.table by a "YYYY[-MM[-DD]]" date column, most recent first; a
# missing month sorts after the dated entries of the same year
sort_by_date_desc <- function(dt, col) {
  key <- as.character(dt[[col]])
  y <- suppressWarnings(as.integer(str_extract(key, "^\\d{4}")))
  m <- suppressWarnings(as.integer(str_match(key, "^\\d{4}-(\\d{1,2})")[, 2]))
  idx <- order(-y, -m, na.last = TRUE)
  dt[idx]
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
  dt <- sort_by_date_desc(dt, "start_date")

  lines <- vapply(
    seq_len(nrow(dt)),
    function(i) {
      row <- dt[i]
      role <- if (!is.na(row$role) && row$role != "") {
        localize_title(row$role)
      } else {
        ""
      }
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
        glue(" {HFILL} {HTML_R}{loc}{HTML_R_END}")
      } else {
        ""
      }

      detail_line <- ""
      if (!is.null(details) && row$put_code %in% names(details)) {
        detail_line <- glue("{BR}\n{details[[row$put_code]]}")
      }

      glue(
        "**{role}** {HFILL} {HTML_R}{dates}{HTML_R_END}{BR}\n",
        "{org_str}{loc_right}{detail_line}\n"
      )
    },
    character(1)
  )

  cat(paste(lines, collapse = "\n\n"), "\n")
}

#' Render education with completed degrees first and ongoing programmes
#' (no end date) under an "In progress" subheading
#'
#' @param data    data.table returned by `orcid_educations()`.
#' @param details Named list of extra detail strings keyed by ORCID put_code.
render_education <- function(data, details = NULL) {
  ongoing <- is.na(data$end_date) | data$end_date == ""
  render_affiliations(data[!ongoing], details = details)
  if (any(ongoing)) {
    cat("\n\n###", IN_PROGRESS[[cv_lang()]], "\n\n")
    render_affiliations(data[ongoing], details = details)
  }
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
  dt <- sort_by_date_desc(dt, "start_date")

  lines <- vapply(
    seq_len(nrow(dt)),
    function(i) {
      row <- dt[i]
      title <- if (!is.na(row$title)) localize_title(row$title) else ""
      org <- if (!is.na(row$organization)) row$organization else ""
      dates <- format_date_range(row$start_date, row$end_date)

      amount_str <- ""
      if (!is.na(row$amount) && !is.na(row$currency)) {
        amount_str <- glue(
          " ({row$currency} {format(as.numeric(row$amount), big.mark = ',', scientific = FALSE)})"
        )
      }

      glue(
        "**{title}**{amount_str} {HFILL} {HTML_R}{dates}{HTML_R_END}{BR}\n",
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
#'
#' Lists longer than `max_authors` keep the first three authors and `keep_name`,
#' marking gaps with an ellipsis and a cut tail with "et al.".
format_author_list <- function(
  authors_nested,
  max_authors = Inf,
  keep_name = NULL
) {
  if (is.null(authors_nested) || length(authors_nested) == 0) {
    return("")
  }
  au <- tryCatch(as.data.frame(authors_nested), error = function(e) NULL)
  if (is.null(au) || nrow(au) == 0) {
    return("")
  }

  names_vec <- mapply(
    function(given, family) {
      initials <- paste0(
        str_extract_all(given, "\\b[[:upper:]]")[[1]],
        collapse = ""
      )
      if (nzchar(initials)) paste0(family, " ", initials) else family
    },
    au$given,
    au$family
  )

  if (length(names_vec) > max_authors) {
    own <- if (is.null(keep_name)) {
      NA
    } else {
      which(str_detect(names_vec, paste0("\\b", keep_name, "\\b")))[1]
    }
    keep <- sort(unique(c(1:3, if (!is.na(own)) own)))
    shown <- character(0)
    for (j in seq_along(keep)) {
      if (j > 1 && keep[j] > keep[j - 1] + 1) {
        shown <- c(shown, "…")
      }
      shown <- c(shown, names_vec[keep[j]])
    }
    if (max(keep) < length(names_vec)) {
      shown <- c(shown, "et al.")
    }
    names_vec <- shown
  }

  paste(names_vec, collapse = ", ")
}

#' Crossref article number for a DOI, or NA
#'
#' rcrossref drops Crossref's article-number field, which online-only journals
#' use instead of a page range.
crossref_article_number <- function(doi) {
  resp <- httr2::request(paste0("https://api.crossref.org/works/", doi)) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform()
  number <- httr2::resp_body_json(resp)$message[["article-number"]]
  if (is.null(number)) NA_character_ else number
}

# Author metadata the DOI registries get wrong, keyed by lower-case DOI, with
# names written "Family, Given". Crossref splits some compound names at the
# wrong space, so AUTHOR_NAME_FIXES maps the registered family name to the
# corrected name. figshare registers only the uploader, so AUTHOR_LISTS gives
# those posters the author list printed on the poster itself.
AUTHOR_NAME_FIXES <- list(
  "10.1016/j.envint.2023.107856" = c(
    "Ramón González" = "González, Juan Ramón",
    "Lun Yuan" = "Yuan, Wen Lun"
  )
)

HELIX_EDC_POSTER <- c(
  "Fabbri, Lorenzo",
  "Garlantezec, Ronan",
  "Thomsen, Cathrine",
  "Wright, John",
  "Slama, Remy",
  "Heude, Barbara",
  "Grazuleviciene, Regina",
  "Chatzi, Leda",
  "Lau, Chung-Ho E",
  "Siskos, Alexandros P",
  "Keun, Hector",
  "Casas, Maribel",
  "Vrijheid, Martine",
  "Maitre, Lea"
)

AUTHOR_LISTS <- list(
  # EURION Cluster Annual Meeting 2022
  "10.6084/m9.figshare.18888155.v1" = HELIX_EDC_POSTER,
  # PPTOX-VII 2022
  "10.6084/m9.figshare.17708729.v2" = HELIX_EDC_POSTER,
  # PASC 2017
  "10.6084/m9.figshare.17708726.v3" = c(
    "Fabbri, Lorenzo",
    "Ummadisingu, Avinash",
    "Dutta, Ritabrata",
    "Janalik, Radim",
    "Mira, Antonietta",
    "Schenk, Olaf",
    "Schoengens, Marcel"
  )
)

#' Split "Family, Given" names into a given/family data frame
split_names <- function(x) {
  parts <- str_split_fixed(x, ", ", 2)
  data.frame(given = parts[, 2], family = parts[, 1])
}

#' Apply AUTHOR_NAME_FIXES for `doi` to a given/family author data frame
fix_author_names <- function(au, doi) {
  fixes <- AUTHOR_NAME_FIXES[[tolower(doi)]]
  if (is.null(au) || is.null(fixes)) {
    return(au)
  }
  hit <- au$family %in% names(fixes)
  fixed <- split_names(fixes[au$family[hit]])
  au$given[hit] <- fixed$given
  au$family[hit] <- fixed$family
  au
}

#' Author list for a registered DOI, or NULL when it cannot be trusted
#'
#' Uses doi.org content negotiation, which covers DataCite DOIs (figshare) as
#' well as Crossref ones. A DOI in AUTHOR_LISTS takes its list from there. Any
#' other figshare record names only its uploader, so a list with fewer than two
#' authors is treated as unknown rather than printed as sole authorship.
doi_authors <- function(doi) {
  listed <- AUTHOR_LISTS[[tolower(doi)]]
  if (!is.null(listed)) {
    return(split_names(listed))
  }
  resp <- httr2::request(paste0("https://doi.org/", doi)) |>
    httr2::req_headers(Accept = "application/vnd.citationstyles.csl+json") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform()
  au <- httr2::resp_body_json(resp)$author
  if (length(au) < 2) {
    return(NULL)
  }
  au <- data.frame(
    given = vapply(au, function(a) a$given %||% "", character(1)),
    family = vapply(
      au,
      function(a) a$family %||% a$literal %||% "",
      character(1)
    )
  )
  fix_author_names(au, doi)
}

#' Render publications list enriched with CrossRef metadata
#'
#' @param works_dt       data.table of works from `orcid_works()`.
#' @param highlight_name Surname to bold in author lists.
#' @param fetch_crossref Logical; set FALSE to skip CrossRef.
#' @param max_authors    Shorten author lists longer than this (see
#'   `format_author_list()`).
render_publications <- function(
  works_dt,
  highlight_name = "Fabbri",
  fetch_crossref = TRUE,
  max_authors = Inf
) {
  if (is.null(works_dt) || nrow(works_dt) == 0) {
    return(invisible(NULL))
  }

  dt <- as.data.table(works_dt)
  dt[, doi := tolower(trimws(doi))]
  has_doi <- !is.na(dt$doi) & dt$doi != ""
  enriched <- dt

  # A CrossRef error stops the render: without it every entry loses its authors
  # and journal, and CI would deploy that degraded list.
  if (fetch_crossref && any(has_doi)) {
    cr_df <- as.data.frame(rcrossref::cr_works(dois = dt$doi[has_doi])$data)
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
        authors <- format_author_list(
          fix_author_names(row$author[[1]], row$doi),
          max_authors,
          highlight_name
        )
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
        page <- if ("page" %in% names(row)) row$page else NA
        if (is.na(page) && fetch_crossref && !is.na(row$doi) && row$doi != "") {
          page <- crossref_article_number(row$doi)
        }
        if (!is.na(page)) {
          vol_str <- paste0(vol_str, ":", page)
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
        # A shortened list already ends in "et al."
        if (nchar(authors) > 0) {
          paste0(authors, if (!endsWith(authors, ".")) ".")
        },
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
#' @param works_dt       data.table filtered from `orcid_works()`.
#' @param number         Logical; prefix each entry with a number.
#' @param authors        Logical; add the author list from the DOI metadata,
#'   so co-authored contributions do not read as one's own presentations.
#' @param highlight_name Surname to bold in author lists.
#' @param max_authors    Shorten author lists longer than this.
render_talks <- function(
  works_dt,
  number = FALSE,
  authors = FALSE,
  highlight_name = "Fabbri",
  max_authors = Inf
) {
  if (is.null(works_dt) || nrow(works_dt) == 0) {
    return(invisible(NULL))
  }

  dt <- as.data.table(works_dt)
  dt <- sort_by_date_desc(dt, "publication_date")

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
      label <- type_label(row$type)
      url_str <- if (!is.na(row$url) && row$url != "") {
        glue(" [[{LINK_LABEL[[cv_lang()]]}]]({row$url})")
      } else {
        ""
      }

      author_line <- ""
      if (authors && !is.na(row$doi) && row$doi != "") {
        au <- doi_authors(row$doi)
        if (!is.null(au)) {
          au_str <- format_author_list(au, max_authors, highlight_name)
          # paste0, not glue: glue trims the trailing newline after BR
          author_line <- paste0(
            highlight_author(au_str, highlight_name),
            BR,
            "\n"
          )
        }
      }

      conf_str <- paste(c(if (nchar(conf) > 0) conf, year), collapse = ", ")
      glue("**{title}**{url_str}{BR}\n{author_line}{label} | {conf_str}\n")
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

#' Render professional memberships as a dated bullet list, most recent first
render_memberships <- function(data) {
  if (is.null(data) || nrow(data) == 0) {
    return(invisible(NULL))
  }

  dt <- as.data.table(data)
  dt <- sort_by_date_desc(dt, "start_date")

  lines <- vapply(
    seq_len(nrow(dt)),
    function(i) {
      row <- dt[i]
      role <- if (!is.na(row$role) && row$role != "") row$role else ""
      org <- if (!is.na(row$organization)) row$organization else ""
      suffix <- if (nchar(role) > 0) paste0(" (", role, ")") else ""
      dates <- format_date_range(row$start_date, row$end_date)
      glue("- **{org}**{suffix} {HFILL} {HTML_R}{dates}{HTML_R_END}")
    },
    character(1)
  )

  cat(paste(lines, collapse = "\n"), "\n")
}
