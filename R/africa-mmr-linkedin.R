# =============================================================================
# africa-mmr-linkedin.R
# Standalone Economist-style horizontal barplot of African maternal mortality.
# Produces two PNG files in output/ for LinkedIn:
#   1. africa-mmr.png       — 4:5 portrait  (best for image posts)
#   2. africa-mmr-wide.png  — 1.91:1 landscape (best for link shares)
#
# Reengineered from The Economist's "Escape artists" chart
# (r-graph-gallery.com/web-horizontal-barplot-with-labels-the-economist.html)
#
# Run from project root:
#   Rscript R/africa-mmr-linkedin.R
#
# Data source: WHO Global Health Observatory indicator MDG_0000000026
#              processed into data/africa_mmr.csv via R/prep_africa_mmr.R
# =============================================================================

library(ggplot2)
library(dplyr)
library(patchwork)
source("R/theme_bka.R")

# ---- Load real WHO MMR data (47 African countries, 2023) ----
mmr <- read.csv("data/africa_mmr.csv") %>%
  arrange(mmr) %>%
  mutate(country = factor(country, levels = country))

# ---- BKA palette (deliberately not Economist blue+red) ----
BAR_FILL    <- "#242852"   # BKA navy — sober, authoritative bar fill
BRAND_COLOR <- "#F8A623"   # BKA amber — warm accent stripe
LABEL_BLUE  <- "#005CB9"   # BKA dark blue — only for outside-bar labels
BKA_NAVY    <- "#242852"   # title text
BKA_GREY    <- "#606060"   # subtitle, caption, gridlines

LABEL_THRESHOLD <- 200

# ---- Main horizontal barplot ----
plt <- ggplot(mmr, aes(x = mmr, y = country)) +
  geom_col(fill = BAR_FILL, width = 0.7) +
  scale_x_continuous(
    limits = c(0, 1050),
    breaks = seq(0, 1000, by = 200),
    labels = scales::comma,
    expand = c(0, 0),
    position = "top"
  ) +
  scale_y_discrete(expand = expansion(add = c(0, 0.6))) +
  geom_label(
    data = subset(mmr, mmr < LABEL_THRESHOLD),
    aes(x = mmr, label = country),
    hjust = 0, nudge_x = 12,
    colour = LABEL_BLUE, fill = "white",
    linewidth = NA, label.padding = unit(0.18, "lines"),
    family = "Lato", size = 4
  ) +
  geom_text(
    data = subset(mmr, mmr >= LABEL_THRESHOLD),
    aes(x = 0, label = country),
    hjust = 0, nudge_x = 15,
    colour = "white", family = "Lato",
    size = 4, fontface = "bold"
  ) +
  labs(x = NULL, y = NULL) +
  theme_bka() +
  theme(
    panel.grid.major.x = element_line(color = "#A8BAC4", linewidth = 0.3),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.title.x       = element_blank(),
    axis.title.y       = element_blank(),
    axis.line.y.left   = element_line(color = "black"),
    axis.text.y        = element_blank(),
    axis.ticks         = element_blank(),
    axis.text.x.top    = element_text(family = "Lato", size = 13, color = BKA_GREY),
    plot.margin        = margin(15, 25, 15, 15)
  )

# ---- Brand bar header (BKA amber rule + signature mark) ----
brand_bar <- ggplot() +
  annotate("rect", xmin = 0, xmax = 1,    ymin = 0.55, ymax = 0.70, fill = BRAND_COLOR) +
  annotate("rect", xmin = 0, xmax = 0.04, ymin = 0.05, ymax = 0.55, fill = BRAND_COLOR) +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  theme_void()

# ---- Compose with patchwork ----
build_plot <- function(title_size, subtitle_size, caption_size) {
  (brand_bar / plt) +
    plot_layout(heights = c(0.025, 1)) +
    plot_annotation(
      title    = "Only 4 of 47 African countries meet\nthe SDG maternal-mortality target",
      subtitle = "Maternal deaths per 100,000 live births (WHO, 2023)\nNigeria's rate (993) is 25\u00d7 Cabo Verde's (40); SDG 3.1 target is < 70",
      caption  = paste0(
        "Source: WHO Global Health Observatory, indicator MDG_0000000026 (retrieved Apr 2026) | BKA analysis\n",
        "Visualization: BK Advisors \u2014 bk-advisors.github.io"
      ),
      theme = theme(
        plot.title    = element_text(family = "Lato", face = "bold",
                                     size = title_size, color = BKA_NAVY,
                                     margin = margin(t = 8, b = 4),
                                     lineheight = 1.15),
        plot.subtitle = element_text(family = "Lato", size = subtitle_size,
                                     color = BKA_GREY,
                                     margin = margin(b = 14),
                                     lineheight = 1.2),
        plot.caption  = element_text(family = "Lato", size = caption_size,
                                     color = BKA_GREY, hjust = 0,
                                     margin = margin(t = 12))
      )
    )
}

# ---- Save portrait version (4:5 ratio — best for LinkedIn image posts) ----
ggsave("output/africa-mmr.png",
       plot  = build_plot(title_size = 22, subtitle_size = 13, caption_size = 10),
       width = 10, height = 12.5, dpi = 300, bg = "white")
cat("Saved: output/africa-mmr.png (3000 x 3750 px @ 300dpi)\n")

# ---- Save landscape version (1.91:1 ratio — best for LinkedIn link shares) ----
ggsave("output/africa-mmr-wide.png",
       plot  = build_plot(title_size = 19, subtitle_size = 11, caption_size = 9),
       width = 14, height = 7.33, dpi = 300, bg = "white")
cat("Saved: output/africa-mmr-wide.png (4200 x 2200 px @ 300dpi)\n")

cat("\nDone! Two files ready for LinkedIn.\n")
