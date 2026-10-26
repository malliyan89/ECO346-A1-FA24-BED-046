# Question 2: weighted histogram of annual education spending on a log10
# scale, with the weighted median and 90th percentile marked.

script_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- normalizePath(file.path(dirname(script_file[[1]]), ".."))
source(file.path(root, "scripts", "00_common.R"))

# ---- Numbers ---------------------------------------------------------------
st <- students_in
n_students <- nrow(students)
n_plotted  <- nrow(st)
n_excluded <- n_students - n_plotted

med_w  <- wquantile(st$ed_total, st$hhweight, 0.50)
p10_w  <- wquantile(st$ed_total, st$hhweight, 0.10)
p90_w  <- wquantile(st$ed_total, st$hhweight, 0.90)
med_u  <- median(st$ed_total)
ratio  <- p90_w / p10_w

# ---- Bins: 0.1 log10 units from 2.0 to 6.0 --------------------------------
st$lx <- log10(st$ed_total)
edges <- seq(2, 6, by = 0.1)
edges[length(edges)] <- 6
idx <- findInterval(st$lx, edges, rightmost.closed = TRUE)

w_bin <- tapply(st$hhweight, factor(idx, levels = seq_len(length(edges) - 1)), sum)
w_bin[is.na(w_bin)] <- 0

bins <- data.frame(
  start = edges[-length(edges)],
  end   = edges[-1]
)
bins$mid <- (bins$start + bins$end) / 2
bins$density <- as.numeric(w_bin) / (sum(st$hhweight) * 0.1)
stopifnot(all(bins$density >= 0), abs(sum(bins$density * 0.1) - 1) < 1e-8)

ymax <- max(bins$density)

# ---- Figure ---------------------------------------------------------------
p <- ggplot(bins, aes(xmin = start, xmax = end, ymin = 0, ymax = density)) +
  geom_rect(fill = "#4C78A8", colour = NA) +
  geom_vline(xintercept = log10(med_w), linetype = "dashed",
             linewidth = 0.55, colour = "grey15") +
  geom_vline(xintercept = log10(p90_w), linetype = "dashed",
             linewidth = 0.55, colour = "grey15") +
  annotate("label", x = log10(med_w), y = ymax * 1.08,
           label = paste0("Weighted median\nRs ", fmt_rupee(med_w)),
           hjust = 1.05, vjust = 1, size = 3.1, lineheight = 0.9,
           linewidth = 0, fill = "white", colour = "grey15") +
  annotate("label", x = log10(p90_w), y = ymax * 1.08,
           label = paste0("Weighted 90th percentile\nRs ", fmt_rupee(p90_w)),
           hjust = -0.05, vjust = 1, size = 3.1, lineheight = 0.9,
           linewidth = 0, fill = "white", colour = "grey15") +
  scale_x_continuous(
    limits = c(2, 6),
    breaks = 2:6,
    labels = c("100", "1,000", "10,000", "100,000", "1,000,000"),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, ymax * 1.18),
    breaks = pretty_breaks(5),
    expand = c(0, 0)
  ) +
  labs(
    title = "The top tenth of students spend 31 times what the bottom tenth spend",
    x = "Annual education spending per student (rupees, log scale)",
    y = "Density per log10 unit",
    caption = paste0(
      "Source: PSLM 2019-20 person and household files.\n",
      "Sample: ", n_students, " students in rural Balochistan with spending > 0; ",
      n_plotted, " plotted (one below Rs 100 excluded).\n",
      "Weighted by hhweight; bins are 0.1 log10 units across Rs 100-1,000,000."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title         = element_text(face = "bold", size = 12.5),
    plot.caption       = element_text(hjust = 0, size = 7.6, colour = "grey35"),
    plot.margin        = margin(10, 28, 16, 10)
  )

save_fig(p, "distribution.svg", width = 8.2, height = 5.6)

# ---- Printed numbers / output fragment ------------------------------------
lines <- c(
  sprintf("Q2 students (ed_total > 0): %d", n_students),
  sprintf("Q2 plotted in Rs 100-1,000,000: %d", n_plotted),
  sprintf("Q2 excluded outside range: %d", n_excluded),
  sprintf("Q2 weighted median: Rs %s", fmt_rupee(med_w)),
  sprintf("Q2 unweighted median: Rs %s", fmt_rupee(med_u)),
  sprintf("Q2 weighted p10: Rs %s", fmt_rupee(p10_w)),
  sprintf("Q2 weighted p90: Rs %s", fmt_rupee(p90_w)),
  sprintf("Q2 p90/p10: %.2f", ratio)
)
writeLines(lines, file.path(out_dir, "q2_numbers.txt"))
cat(paste(lines, collapse = "\n"), "\n")
cat("Wrote figures/distribution.svg\n")
