# Question 4: the untouched default scatterplot.
# This is deliberately only ggplot(data, aes(x, y)) + geom_point():
# no theme, no labels, no title, no summary. It is committed before the
# redesign in 03_literacy.R.

script_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- normalizePath(file.path(dirname(script_file[[1]]), ".."))
source(file.path(root, "scripts", "00_common.R"))

p <- ggplot(literacy, aes(x = age, y = literate)) +
  geom_point()

save_fig(p, "default.svg", width = 7, height = 5)
cat("Wrote figures/default.svg\n")
