# Shared setup: project paths, PSLM data, sample definitions, weighted
# statistics, and plotting defaults.
#
# This file is sourced by the numbered scripts. It locates the repository
# root from the top-level script's --file argument, so the scripts can be
# run from any working directory:
#   Rscript scripts/01_default.R
#   Rscript scripts/run_all.R

root_from_args <- function() {
  f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  if (length(f) == 0L) return(normalizePath(getwd()))
  normalizePath(file.path(dirname(f[[1]]), ".."))
}

root    <- root_from_args()
data_dir <- file.path(root, "data")
fig_dir  <- file.path(root, "figures")
out_dir  <- file.path(root, "outputs")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

suppressPackageStartupMessages({
  library(ggplot2)
  library(svglite)
  library(scales)
})

# ---- Data -----------------------------------------------------------------
person <- read.csv(file.path(data_dir, "pslm_person_subset.csv"),
                   stringsAsFactors = FALSE)
hh <- read.csv(file.path(data_dir, "pslm_hh_subset.csv"),
               stringsAsFactors = FALSE)

stopifnot(!anyDuplicated(hh$hhid))
dat <- merge(person,
             hh[, c("hhid", "hhweight", "prov_code", "urban_rural")],
             by = "hhid", all.x = TRUE, sort = FALSE)
stopifnot(nrow(dat) == nrow(person), !anyNA(dat$hhweight))

# Variant 6 = Balochistan rural (prov_code 4, urban_rural 1).
variant <- subset(dat, prov_code == 4 & urban_rural == 1)

# ---- Sample definitions ----------------------------------------------------
band_levels <- c("10-14", "15-19", "20-24", "25-29", "30-34", "35-39",
                 "40-44", "45-49", "50-54", "55-59", "60-64")
band_mid <- seq(12, 62, by = 5)

add_band <- function(d) {
  d$band <- cut(d$age, breaks = seq(10, 65, 5), right = FALSE,
                labels = band_levels, include.lowest = TRUE)
  d
}

# Literacy sample: aged 10-64, non-missing literate.
literacy <- add_band(subset(variant, age >= 10 & age <= 64 & !is.na(literate)))

# Students: ed_total > 0. The figure keeps the Rs 100-1,000,000 window.
students    <- subset(variant, !is.na(ed_total) & ed_total > 0)
students_in <- subset(students, ed_total >= 100 & ed_total <= 1e6)

# ---- Weighted statistics ---------------------------------------------------
wmean <- function(x, w) sum(x * w) / sum(w)

# Weighted quantile definition used by the assignment: sort by x, accumulate
# the weight share, and take the smallest x whose cumulative share reaches
# or exceeds p. This is deliberately not stats::quantile().
wquantile <- function(x, w, p) {
  o <- order(x)
  x <- x[o]
  w <- w[o]
  x[which(cumsum(w) / sum(w) >= p)[1]]
}

band_table <- function(d) {
  rows <- lapply(band_levels, function(b) {
    s <- subset(d, band == b)
    m <- subset(s, sex == 1)
    f <- subset(s, sex == 2)
    data.frame(
      band        = b,
      male_n      = nrow(m),
      male_rate   = 100 * wmean(m$literate, m$hhweight),
      female_n    = nrow(f),
      female_rate = 100 * wmean(f$literate, f$hhweight),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out$gap_pp <- out$male_rate - out$female_rate
  out
}

fmt_rupee <- function(x) formatC(round(x), format = "d", big.mark = ",")

# ---- Plot defaults ---------------------------------------------------------
col_male   <- "#0072B2"
col_female <- "#D55E00"

save_fig <- function(p, filename, width = 8, height = 5) {
  ggsave(filename = file.path(fig_dir, filename), plot = p,
         width = width, height = height, device = svglite::svglite)
  # Optional low-resolution PNG for on-screen checking only. The committed
  # deliverable is always the SVG above.
  if (isTRUE(getOption("eco346.qa_png")) || identical(Sys.getenv("ECO346_QA"), "1")) {
    qa_dir <- Sys.getenv("ECO346_QA_DIR", unset = tempdir())
    dir.create(qa_dir, showWarnings = FALSE, recursive = TRUE)
    qa <- file.path(qa_dir, sub("\\.svg$", ".png", filename))
    ggsave(qa, p, width = width, height = height,
           device = ragg::agg_png, dpi = 150)
    cat("QA PNG:", qa, "\n")
  }
  invisible(file.path(fig_dir, filename))
}
