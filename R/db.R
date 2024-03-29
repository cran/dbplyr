#' Miscellaneous database generics
#'
#' * `db_connection_describe()` provides a short string describing the
#'   database connection, helping users tell which database a table comes
#'   from. It should be a single line, and ideally less than 60 characters wide.
#'
#' * `dbplyr_edition()` declares which version of the dbplyr API you want.
#'    See below for more details.
#'
#' * `db_col_types()` returns the column types of a table.
#'
#' @section dbplyr 2.0.0:
#' dbplyr 2.0.0 renamed a number of generics so that they could be cleanly moved
#' from dplyr to dbplyr. If you have an existing backend, you'll need to rename
#' the following methods.
#'
#' * `dplyr::db_desc()` -> `dbplyr::db_connection_describe()` (also note that
#'    the argument named changed from `x` to `con`).
#'
#' @family generic
#' @keywords internal
#' @name db-misc
#' @aliases NULL
NULL

dbplyr_connection_describe <- function(con, ...) {
  dbplyr_fallback(con, "db_desc", ...)
}
#' @export
#' @importFrom dplyr db_desc
db_desc.DBIConnection <- function(x) {
  db_connection_describe(x)
}
#' @export
#' @rdname db-misc
db_connection_describe <- function(con, ...) {
  check_dots_used()
  UseMethod("db_connection_describe")
}
# nocov start
#' @export
db_connection_describe.DBIConnection <- function(con, ...) {
  class(con)[[1]]
}
# nocov end


#' @rdname db-misc
#' @export
sql_join_suffix <- function(con, suffix, ...) {
  UseMethod("sql_join_suffix")
}
#' @export
sql_join_suffix.DBIConnection <- function(con, suffix, ...) {
  suffix %||% c(".x", ".y")
}

#' @rdname db-misc
#' @export
db_sql_render <- function(con, sql, ..., cte = FALSE, sql_options = NULL) {
  check_bool(cte)
  if (cte) {
    lifecycle::deprecate_soft(
      when = "2.4.0",
      what = "db_sql_render(cte)",
      with = I("db_sql_render(sql_options = sql_options(cte = TRUE))")
    )
    sql_options <- sql_options %||% sql_options(cte = TRUE)
    out <- db_sql_render(con, sql, ..., sql_options = sql_options)
    return(out)
  }

  if (is.null(sql_options)) {
    sql_options <- sql_options()

    out <- db_sql_render(con, sql, ..., sql_options = sql_options)
    return(out)
  }

  UseMethod("db_sql_render")
}
#' @export
db_sql_render.DBIConnection <- function(con, sql, ..., cte = FALSE, sql_options = NULL) {
  sql_render(sql, con = con, ..., sql_options = sql_options)
}

#' @rdname db-misc
#' @export
db_col_types <- function(con, table, call) {
  if (is_null(table)) {
    return(NULL)
  }

  UseMethod("db_col_types")
}

#' @export
db_col_types.TestConnection <- function(con, table, call) {
  NULL
}

#' @export
db_col_types.DBIConnection <- function(con, table, call) {
  NULL
}
# add a default method so that packages that haven't implemented `db_col_types()`
# keep working, e.g. {Pool}
#' @export
db_col_types.default <- function(con, table, call) {
  NULL
}

#' Options for generating SQL
#'
#' @param cte If `FALSE`, the default, subqueries are used. If `TRUE` common
#'   table expressions are used.
#' @param use_star If `TRUE`, the default, `*` is used to select all columns of
#'   a table. If `FALSE` all columns are explicitly selected.
#' @param qualify_all_columns If `FALSE`, the default, columns are only
#'   qualified with the table they come from if the same column name appears in
#'   multiple tables.
#'
#' @return A <dbplyr_sql_options> object.
#' @export
#'
#' @examples
#' library(dplyr, warn.conflicts = FALSE)
#' lf1 <- lazy_frame(key = 1, a = 1, b = 2)
#' lf2 <- lazy_frame(key = 1, a = 1, c = 3)
#'
#' result <- left_join(lf1, lf2, by = "key") %>%
#'   filter(c >= 3)
#'
#' show_query(result)
#' sql_options <- sql_options(cte = TRUE, qualify_all_columns = TRUE)
#' show_query(result, sql_options = sql_options)
sql_options <- function(cte = FALSE, use_star = TRUE, qualify_all_columns = FALSE) {
  check_bool(cte)
  check_bool(use_star)
  check_bool(qualify_all_columns)

  data <- list(
    cte = cte,
    use_star = use_star,
    qualify_all_columns = qualify_all_columns
  )
  class(data) <- "dbplyr_sql_options"
  data
}

as_sql_options <- function(x, error_arg = caller_arg(x), error_call = caller_env()) {
  if (is.null(x)) {
    x <- sql_options()
    return(x)
  }

  if (!inherits(x, "dbplyr_sql_options")) {
    stop_input_type(
      x = x,
      what = I("an object created by `sql_options()`"),
      arg = error_arg,
      call = error_call
    )
  }

  x
}

#' @export
print.dbplyr_sql_options <- function(x, ...) {
  if (x$cte) {
    cte <- "Use CTE"
  } else {
    cte <- "Use subqueries"
  }

  if (x$use_star) {
    star <- "Use {.val SELECT *} where possible"
  } else {
    star <- "Explicitly select all columns"
  }

  if (x$qualify_all_columns) {
    join_table_name <- "Qualify all columns"
  } else {
    join_table_name <- "Qualify only ambiguous columns"
  }

  msg <- c(cte, star, join_table_name)
  msg <- set_names(msg, "*")
  cli::cli_inform(msg)
}

#' @rdname db-misc
#' @export
dbplyr_edition <- function(con) {
  UseMethod("dbplyr_edition")
}
#' @export
dbplyr_edition.default <- function(con) {
  1L
}
# Needed because pool uses an object of call Pool/R6

# fallback helper ---------------------------------------------------------

dbplyr_fallback <- function(con, .generic, ...) {
  if (dbplyr_edition(con) >= 2) {
    # Always call DBIConnection method which contains the default implementation
    fun <- sym(paste0(.generic, ".DBIConnection"))
  } else {
    class <- class(con)[[1]]
    warn(
      c(
        paste0("<", class, "> uses an old dbplyr interface"),
        i = "Please install a newer version of the package or contact the maintainer"
      ),
      .frequency = "regularly",
      .frequency_id = paste0(class, "-edition")
    )
    fun <- call("::", quote(dplyr), sym(.generic))
  }
  eval_bare(expr((!!fun)(con, ...)))
}
