# Question 3: weighted literacy rate by age band and sex, with direct labels,
# hollow markers for thin cells, and the largest gender gap annotated.

script_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- normalizePath(file.path(dirname(script_file[[1]]), ".."))
source(file.path(root, "scripts", "00_common.R"))

# ---- Band table -----------------------------------------------------------
bt <- band_table(literacy)
bt$band <- factor(bt$band, levels = band_levels)
bt$mid  <- band_mid
bt$male_thin   <- bt$male_n   < 30
bt$female_thin <- bt$female_n < 30

# Long format for plotting
long <- rbind(
  data.frame(
    band = bt$band, mid = bt$mid, sex = "Women",
    rate = bt$female_rate, n = bt$female_n, thin = bt$female_thin,
    stringsAsFactors = FALSE
  ),
  data.frame(
    band = bt$band, mid = bt$mid, sex = "Men",
    rate = bt$male_rate, n = bt$male_n, thin = bt$male_thin,
    stringsAsFactors = FALSE
  )
)
long$sex <- factor(long$sex, levels = c("Women", "Men"))
long$fill_col <- ifelse(long$thin, "white",
                        ifelse(long$sex == "Women", col_female, col_male))

# Largest absolute gap
gap_row <- bt[which.max(abs(bt$gap_pp)), ]
gap_band <- as.character(gap_row$band)
gap_mid  <- gap_row$mid
gap_f    <- gap_row$female_rate
gap_m    <- gap_row$male_rate
gap_pp   <- abs(gap_row$gap_pp)

# ---- Figure ---------------------------------------------------------------
p <- ggplot(long, aes(x = mid, y = rate, group = sex, colour = sex)) +
  geom_line(linewidth = 0.75) +
  geom_point(aes(fill = fill_col), shape = 21, size = 2.9, stroke = 0.8) +
  annotate("segment",
           x = gap_mid - 0.55, xend = gap_mid - 0.55,
           y = gap_f, yend = gap_m,
           colour = "grey25", linewidth = 0.4,
           arrow = arrow(ends = "both", length = unit(0.07, "inches"))) +
  annotate("text",
           x = gap_mid - 0.95, y = (gap_f + gap_m) / 2,
           label = paste0("Largest gap\n", sprintf("%.1f", gap_pp), " pp"),
           hjust = 1, vjust = 0.5, size = 3.1, lineheight = 0.9,
           colour = "grey20") +
  annotate("text", x = 63.2, y = bt$female_rate[bt$band == "60-64"],
           label = "Women", hjust = 0, fontface = "bold", size = 3.4,
           colour = col_female) +
  annotate("text", x = 63.2, y = bt$male_rate[bt$band == "60-64"],
           label = "Men", hjust = 0, fontface = "bold", size = 3.4,
           colour = col_male) +
  scale_colour_manual(values = c(Women = col_female, Men = col_male)) +
  scale_fill_identity() +
  scale_x_continuous(
    limits = c(10, 66),
    breaks = band_mid,
    labels = band_levels,
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    expand = c(0, 0)
  ) +
  labs(
    title = "Women's literacy falls steeply with age; the gender gap peaks at 48 points",
    x = "Age band (years)",
    y = "Weighted literacy rate (%)",
    caption = paste0(
      "Source: PSLM 2019-20 person and household files.\n",
      "Sample: 5,677 persons aged 10-64 in rural Balochistan with non-missing literacy.\n",
      "Weighted by hhweight. Hollow markers flag cells with <30 persons; none were thin."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position     = "none",
    panel.grid.minor    = element_blank(),
    panel.grid.major.x  = element_blank(),
    plot.title          = element_text(face = "bold", size = 12.2),
    plot.caption        = element_text(hjust = 0, size = 7.6, colour = "grey35"),
    plot.margin         = margin(10, 14, 16, 10)
  )

save_fig(p, "literacy.svg", width = 8.2, height = 5.7)

# ---- Printed numbers / output fragment ------------------------------------
thin <- long[long$thin, c("band", "sex", "n")]
lines <- c(
  sprintf("Q3 literacy sample: %d", nrow(literacy)),
  sprintf("Q3 women 15-19: %.1f", bt$female_rate[bt$band == "15-19"]),
  sprintf("Q3 men 15-19: %.1f", bt$male_rate[bt$band == "15-19"]),
  sprintf("Q3 women 55-59: %.1f", bt$female_rate[bt$band == "55-59"]),
  sprintf("Q3 men 55-59: %.1f", bt$male_rate[bt$band == "55-59"]),
  sprintf("Q3 largest gap: %s, %.1f pp (men %.1f, women %.1f)",
          gap_band, gap_pp, gap_m, gap_f),
  sprintf("Q3 thin cells (<30): %d", nrow(thin)),
  sprintf("Q3 smallest cell n: %d", min(bt$male_n, bt$female_n))
)
writeLines(lines, file.path(out_dir, "q3_numbers.txt"))
write.csv(bt[, c("band", "male_n", "male_rate", "female_n", "female_rate", "gap_pp")],
          file.path(out_dir, "band_table_r.csv"), row.names = FALSE)
cat(paste(lines, collapse = "\n"), "\n")
cat("Wrote figures/literacy.svg and outputs/band_table_r.csv\n")
