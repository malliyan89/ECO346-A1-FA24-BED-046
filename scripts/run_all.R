# Run every script in order and regenerate all figures, tables and numbers.
# Usage (from anywhere):
#   Rscript scripts/run_all.R

script_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(script_file)) {
  normalizePath(file.path(dirname(script_file[[1]]), ".."))
} else {
  normalizePath(getwd())
}
setwd(root)

cat("== 01 default scatterplot ==\n")
source("scripts/01_default.R")

cat("\n== 02 distribution ==\n")
source("scripts/02_distribution.R")

cat("\n== 03 literacy redesign ==\n")
source("scripts/03_literacy.R")

cat("\n== 04 Python replication ==\n")
py <- Sys.which("python")
if (!nzchar(py)) py <- Sys.which("py")
if (!nzchar(py)) stop("Python not found on PATH; install Python or run 04 manually.")
status <- system2(py, args = "scripts/04_literacy_python.py")
if (!identical(status, 0L)) stop("Python replication failed.")

cat("\n== 05 table comparison ==\n")
source("scripts/05_compare_tables.R")

cat("\n== Generated numbers ==\n")
for (f in c("q2_numbers.txt", "q3_numbers.txt", "q5_numbers.txt",
            "table_comparison.txt")) {
  cat("\n--", f, "--\n")
  cat(readLines(file.path("outputs", f)), sep = "\n")
  cat("\n")
}
cat("\nAll figures and tables regenerated.\n")
