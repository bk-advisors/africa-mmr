# ---- Audit key figures used in LinkedIn post and chart ----
# Run this script to verify claims before publishing.
# Usage: Rscript R/audit_figures.R

library(dplyr)
library(scales)

df <- read.csv("data/africa_mmr.csv")

cat("=== DATA OVERVIEW ===\n")
cat("Countries:", n_distinct(df$country), "\n")
cat("Year range:", min(df$year), "-", max(df$year), "\n")

# ---- 1. Chart/post claim: '4 of 47 countries meet the SDG target' ----
SDG_TARGET <- 70   # SDG 3.1: < 70 maternal deaths per 100,000 live births
cat("\n=== CLAIM: 'Only 4 of 47 African countries meet the SDG target (<", SDG_TARGET, ")' ===\n")
n_total  <- nrow(df)
meet_sdg <- df %>% filter(mmr < SDG_TARGET) %>% arrange(mmr)
cat("Total African countries reporting:", n_total, "\n")
cat("Countries with MMR <", SDG_TARGET, ":", nrow(meet_sdg), "\n")
if (nrow(meet_sdg) > 0) {
  meet_sdg %>%
    mutate(label = paste0("  ", country, ": ", round(mmr))) %>%
    pull(label) %>%
    cat(sep = "\n")
  cat("\n")
}

# ---- 2. Highest MMR country (LinkedIn post calls out Nigeria) ----
cat("\n=== CLAIM: 'Nigeria's rate (993)' ===\n")
top <- df %>% slice_max(mmr, n = 1)
cat("Highest MMR country:", top$country, "—", round(top$mmr),
    "(year:", top$year, ")\n")

# ---- 3. Ratio claim: 'Nigeria's rate is 25x Cabo Verde's (40)' ----
cat("\n=== CLAIM: 'Nigeria is 25x Cabo Verde (40)' ===\n")
ng <- df$mmr[df$country_code == "NGA"]
cv <- df$mmr[df$country_code == "CPV"]
if (length(ng) && length(cv)) {
  cat("Nigeria:   ", round(ng), "\n")
  cat("Cabo Verde:", round(cv), "\n")
  cat("Ratio:     ", round(ng / cv, 1), "x\n")
} else {
  cat("Could not find NGA or CPV in data.\n")
}

# ---- 4. Distribution buckets used in the chart label threshold (200) ----
LABEL_THRESHOLD <- 200
cat("\n=== CHART LABEL THRESHOLD: bars >=", LABEL_THRESHOLD, "get white in-bar label ===\n")
cat("Bars >=", LABEL_THRESHOLD, ":", sum(df$mmr >= LABEL_THRESHOLD), "\n")
cat("Bars <", LABEL_THRESHOLD, ":",  sum(df$mmr <  LABEL_THRESHOLD), "\n")

# ---- 5. Summary stats ----
cat("\n=== SUMMARY STATS ===\n")
cat("Min  MMR:", round(min(df$mmr)),     "\n")
cat("Max  MMR:", round(max(df$mmr)),     "\n")
cat("Mean MMR:", round(mean(df$mmr), 1), "\n")
cat("Med  MMR:", round(median(df$mmr)),  "\n")

# ---- 6. Data freshness — what year is each row from? ----
cat("\n=== DATA FRESHNESS (year distribution) ===\n")
df %>%
  count(year, name = "n_countries") %>%
  arrange(desc(year)) %>%
  mutate(label = paste0("  ", year, ": ", n_countries, " countries")) %>%
  pull(label) %>%
  cat(sep = "\n")

cat("\n\n=== AUDIT COMPLETE ===\n")
