# Sourced automatically by testthat::test_dir() before tests run.
# Loads all pure-logic functions from R/ (app.R is at the project root and is
# NOT sourced here).
r_files <- list.files(file.path("..", "..", "R"), pattern = "[.][Rr]$", full.names = TRUE)
invisible(lapply(r_files, source))
