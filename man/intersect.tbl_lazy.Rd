% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/verb-set-ops.R
\name{intersect.tbl_lazy}
\alias{intersect.tbl_lazy}
\alias{union.tbl_lazy}
\alias{union_all.tbl_lazy}
\alias{setdiff.tbl_lazy}
\title{SQL set operations}
\usage{
\method{intersect}{tbl_lazy}(x, y, copy = FALSE, ..., all = FALSE)

\method{union}{tbl_lazy}(x, y, copy = FALSE, ..., all = FALSE)

\method{union_all}{tbl_lazy}(x, y, copy = FALSE, ...)

\method{setdiff}{tbl_lazy}(x, y, copy = FALSE, ..., all = FALSE)
}
\arguments{
\item{x, y}{A pair of lazy data frames backed by database queries.}

\item{copy}{If \code{x} and \code{y} are not from the same data source,
and \code{copy} is \code{TRUE}, then \code{y} will be copied into a
temporary table in same database as \code{x}. \verb{*_join()} will automatically
run \code{ANALYZE} on the created table in the hope that this will make
you queries as efficient as possible by giving more data to the query
planner.

This allows you to join tables across srcs, but it's potentially expensive
operation so you must opt into it.}

\item{...}{Not currently used; provided for future extensions.}

\item{all}{If \code{TRUE}, includes all matches in output, not just unique rows.}
}
\description{
These are methods for the dplyr generics \code{dplyr::intersect()},
\code{dplyr::union()}, and \code{dplyr::setdiff()}. They are translated to
\code{INTERSECT}, \code{UNION}, and \code{EXCEPT} respectively.
}
