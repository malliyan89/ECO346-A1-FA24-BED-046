# Question 5 check: compare the R and Python band tables.
# The two tables must agree to one decimal place.

script_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(script_file)) {
  normalizePath(file.path(dirname(script_file[[1]]), ".."))
} else {
  normalizePath(getwd())
}
out_dir <- file.path(root, "outputs")

r_tab <- read.csv(file.path(out_dir, "band_table_r.csv"), stringsAsFactors = FALSE)
p_tab <- read.csv(file.path(out_dir, "band_table_python.csv"), stringsAsFactors = FALSE)

stopifnot(identical(r_tab$band, p_tab$band))
stopifnot(identical(r_tab$male_n, p_tab$male_n))
stopifnot(identical(r_tab$female_n, p_tab$female_n))

num_cols <- c("male_rate", "female_rate", "gap_pp")
max_diff <- max(abs(as.matrix(r_tab[num_cols]) - as.matrix(p_tab[num_cols])))
round_match <- all(
  round(as.matrix(r_tab[num_cols]), 1) == round(as.matrix(p_tab[num_cols]), 1)
)

lines <- c(
  sprintf("Q5 table check: %s", if (round_match) "PASS" else "FAIL"),
  sprintf("Maximum absolute difference before rounding: %.10f", max_diff),
  sprintf("All 11 bands and counts identical: %s",
          if (identical(r_tab$band, p_tab$band) &&
              identical(r_tab$male_n, p_tab$male_n) &&
              identical(r_tab$female_n, p_tab$female_n)) "yes" else "no"),
  sprintf("All rates agree to one decimal: %s", if (round_match) "yes" else "no")
)
writeLines(lines, file.path(out_dir, "table_comparison.txt"))
cat(paste(lines, collapse = "\n"), "\n")

if (!round_match) stop("R and Python band tables do not agree to one decimal.")
