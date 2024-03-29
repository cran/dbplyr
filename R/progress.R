# Copy in deprecated progress_estimated() from dplyr
# nocov start
progress_estimated <- function(n, min_time = 0) {
  Progress$new(n, min_time = min_time)
}

#' @importFrom R6 R6Class
Progress <- R6::R6Class("Progress",
  public = list(
    n = NULL,
    i = 0,
    init_time = NULL,
    stopped = FALSE,
    stop_time = NULL,
    min_time = NULL,
    last_update = NULL,

    initialize = function(n, min_time = 0, ...) {
      self$n <- n
      self$min_time <- min_time
      self$begin()
    },

    begin = function() {
      "Initialise timer. Call this before beginning timing."
      self$i <- 0
      self$last_update <- self$init_time <- now()
      self$stopped <- FALSE
      self
    },

    pause = function(x) {
      "Sleep for x seconds. Useful for testing."
      Sys.sleep(x)
      self
    },

    width = function() {
      getOption("width") - nchar("|100% ~ 99.9 h remaining") - 2
    },

    tick = function() {
      "Process one element"
      if (self$stopped) return(self)

      if (self$i == self$n) cli_abort("No more ticks")
      self$i <- self$i + 1
      self
    },

    stop = function() {
      if (self$stopped) return(self)

      self$stopped <- TRUE
      self$stop_time <- now()
      self
    },

    print = function(...) {
      if (!isTRUE(getOption("dplyr.show_progress")) || # user sepecifies no progress
        !interactive() || # not an interactive session
        !is.null(getOption("knitr.in.progress"))) { # dplyr used within knitr document
        return(invisible(self))
      }

      now_ <- now()
      if (now_ - self$init_time < self$min_time || now_ - self$last_update < 0.05) {
        return(invisible(self))
      }
      self$last_update <- now_

      if (self$stopped) {
        overall <- show_time(self$stop_time - self$init_time)
        if (self$i == self$n) {
          cat_line("Completed after ", overall)
          cat("\n")
        } else {
          cat_line("Killed after ", overall)
          cat("\n")
        }
        return(invisible(self))
      }

      avg <- (now() - self$init_time) / self$i
      time_left <- (self$n - self$i) * avg
      nbars <- trunc(self$i / self$n * self$width())

      cat_line(
        "|", str_rep("=", nbars), str_rep(" ", self$width() - nbars), "|",
        format(round(self$i / self$n * 100), width = 3), "% ",
        "~", show_time(time_left), " remaining"
      )

      invisible(self)
    }
  )
)

str_rep <- function(x, i) {
  paste(rep.int(x, i), collapse = "")
}

show_time <- function(x) {
  if (x < 60) {
    paste(round(x), "s")
  } else if (x < 60 * 60) {
    paste(round(x / 60), "m")
  } else {
    paste(round(x / (60 * 60)), "h")
  }
}

now <- function() proc.time()[[3]]
# nocov end
