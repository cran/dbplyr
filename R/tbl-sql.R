#' Create an SQL tbl (abstract)
#'
#' Generally, you should no longer need to provide a custom `tbl()`
#' method.
#' The default `tbl.DBIConnect` method should work in most cases.
#'
#' @keywords internal
#' @export
#' @param subclass name of subclass
#' @param ... needed for agreement with generic. Not otherwise used.
#' @param vars Provide column names as a character vector
#'   to avoid retrieving them from the database.
#'   Mainly useful for better performance when creating
#'   multiple `tbl` objects.
#' @param check_from `r lifecycle::badge("deprecated")`
tbl_sql <- function(subclass,
                    src,
                    from,
                    ...,
                    vars = NULL,
                    check_from = deprecated()) {
  # Can't use check_dots_used(), #1429
  check_character(vars, allow_null = TRUE)
  if (lifecycle::is_present(check_from)) {
    lifecycle::deprecate_warn("2.5.0", "tbl_sql(check_from)")
  }

  is_suspicious <- is_bare_string(from) && grepl(".", from, fixed = TRUE)
  source <- as_table_source(from, con = src$con)

  withCallingHandlers(
    vars <- vars %||% dbplyr_query_fields(src$con, source),
    error = function(err) {
      if (!is_suspicious) return()

      cli::cli_abort(
        c(
          "Failed to find table {source}.",
          i = "Did you mean {.code from = I({.str {from}})}?"
        ),
        parent = err
      )
    }
  )

  dplyr::make_tbl(
    c(subclass, "sql", "lazy"),
    src = src,
    lazy_query = lazy_query_remote(source, vars)
  )
}

#' @importFrom dplyr same_src
#' @export
same_src.tbl_sql <- function(x, y) {
  inherits(y, "tbl_sql") && same_src(x$src, y$src)
}

# Grouping methods -------------------------------------------------------------

#' @importFrom dplyr group_size
#' @export
group_size.tbl_sql <- function(x) {
  df <- x %>%
    summarise(n = n()) %>%
    collect()
  df$n
}

#' @importFrom dplyr n_groups
#' @export
n_groups.tbl_sql <- function(x) {
  if (length(groups(x)) == 0) return(1L)

  df <- x %>%
    summarise() %>%
    ungroup() %>%
    summarise(n = n()) %>%
    collect()
  df$n
}

# Standard data frame methods --------------------------------------------------

#' @export
print.tbl_sql <- function(x, ..., n = NULL, width = NULL, n_extra = NULL) {
  cat_line(format(x, ..., n = n, width = width, n_extra = n_extra))
  invisible(x)
}

#' @export
as.data.frame.tbl_sql <- function(x,
                                  row.names = NULL,
                                  optional = NULL,
                                  ...,
                                  n = Inf) {
  as.data.frame(collect(x, n = n))
}

#' @export
#' @importFrom tibble tbl_sum
tbl_sum.tbl_sql <- function(x) {
  grps <- op_grps(x$lazy_query)
  sort <- op_sort(x$lazy_query)
  c(
    # Can be overwritten by tbl_format_header.tbl_lazy:
    "Source" = tbl_desc(x),
    "Database" = dbplyr_connection_describe(x$src$con),
    "Groups" = if (length(grps) > 0) commas(grps),
    "Ordered by" = if (length(sort) > 0) commas(deparse_all(sort))
  )
}

tbl_desc <- function(x, rows_total = NA_integer_) {
  paste0(
    op_desc(x$lazy_query),
    " [",
    op_rows(x$lazy_query, rows_total),
    " x ",
    big_mark(op_cols(x$lazy_query)),
    "]"
  )
}
