# ---- Validate CSV against the original WHO source ----
# Fetches the maternal-mortality-ratio indicator (MDG_0000000026) from WHO GHO,
# takes the latest year per African country, and compares it to data/africa_mmr.csv.
#
# Requires: jsonlite, dplyr
# Usage:    Rscript R/validate_sources.R

library(jsonlite)
library(dplyr)

csv <- read.csv("data/africa_mmr.csv")
csv_codes <- unique(csv$country_code)

cat("=== CSV SUMMARY ===\n")
cat("Countries:", length(csv_codes), "\n")
cat("Rows:    ", nrow(csv), "\n")
cat("Year range:", min(csv$year), "-", max(csv$year), "\n\n")


# =========================================================================
# 1. WHO GHO — Maternal mortality ratio (MDG_0000000026)
#    Note: WHO hosts several maternal-mortality indicators. MDG_0000000026 is
#    the modeled MMR (deaths per 100,000 live births) used for SDG 3.1.
# =========================================================================
cat("=== FETCHING WHO MMR DATA ===\n")

mmr_url <- paste0(
  "https://ghoapi.azureedge.net/api/MDG_0000000026",
  "?$filter=ParentLocation%20eq%20%27Africa%27"
)

mmr_raw <- fromJSON(mmr_url)
mmr     <- mmr_raw$value

# Handle pagination
while (!is.null(mmr_raw[["@odata.nextLink"]])) {
  mmr_raw <- fromJSON(mmr_raw[["@odata.nextLink"]])
  mmr     <- rbind(mmr, mmr_raw$value)
}

# Latest year per country (matches prep_africa_mmr.R logic)
who <- mmr %>%
  filter(SpatialDimType == "COUNTRY") %>%
  group_by(SpatialDim) %>%
  slice_max(TimeDim, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    country_code = SpatialDim,
    year         = as.integer(TimeDim),
    who_mmr      = as.numeric(NumericValue),
    who_low      = as.numeric(Low),
    who_high     = as.numeric(High)
  )

cat("WHO latest-year records:", nrow(who), "\n\n")


# =========================================================================
# 2. Compare: CSV mmr vs WHO mmr
# =========================================================================
cat("=== MMR COMPARISON: CSV vs WHO ===\n")

mmr_check <- csv %>%
  select(country_code, year, csv_mmr = mmr) %>%
  inner_join(who, by = c("country_code", "year"))

mmr_check <- mmr_check %>%
  mutate(
    diff     = csv_mmr - who_mmr,
    pct_diff = ifelse(who_mmr > 0,
                      round((diff / who_mmr) * 100, 2), NA)
  )

exact   <- sum(mmr_check$diff == 0, na.rm = TRUE)
total   <- nrow(mmr_check)
matched <- sum(abs(mmr_check$pct_diff) < 1, na.rm = TRUE)

cat("Rows matched (country+year):", total, "of", nrow(csv), "CSV rows\n")
cat("Exact matches:", exact,   "/", total, "\n")
cat("Within 1% tolerance:", matched, "/", total, "\n")

mismatches <- mmr_check %>%
  filter(diff != 0) %>%
  arrange(desc(abs(pct_diff)))

if (nrow(mismatches) > 0) {
  cat("\nTop discrepancies (mmr):\n")
  print(head(mismatches, 15))
} else {
  cat("All MMR values match exactly.\n")
}


# =========================================================================
# 3. Compare: CSV uncertainty bounds vs WHO bounds
# =========================================================================
cat("\n=== UNCERTAINTY BOUNDS COMPARISON: CSV vs WHO ===\n")

bounds_check <- csv %>%
  select(country_code, year, csv_low = low, csv_high = high) %>%
  inner_join(who %>% select(country_code, year, who_low, who_high),
             by = c("country_code", "year")) %>%
  mutate(
    low_diff  = csv_low  - who_low,
    high_diff = csv_high - who_high
  )

cat("Low bound exact matches: ", sum(bounds_check$low_diff  == 0, na.rm = TRUE),
    "/", nrow(bounds_check), "\n")
cat("High bound exact matches:", sum(bounds_check$high_diff == 0, na.rm = TRUE),
    "/", nrow(bounds_check), "\n")


# =========================================================================
# 4. Coverage: countries in CSV but not in WHO (and vice versa)
# =========================================================================
cat("\n=== COVERAGE GAPS ===\n")

who_codes <- unique(who$country_code)

in_csv_not_who <- setdiff(csv_codes, who_codes)
in_who_not_csv <- setdiff(who_codes, csv_codes)

if (length(in_csv_not_who) > 0) {
  cat("In CSV but not in WHO:", paste(in_csv_not_who, collapse = ", "), "\n")
} else {
  cat("All CSV countries found in WHO data.\n")
}

if (length(in_who_not_csv) > 0) {
  cat("In WHO but not in CSV:", paste(in_who_not_csv, collapse = ", "), "\n")
} else {
  cat("All WHO African countries are in the CSV.\n")
}

cat("\n=== VALIDATION COMPLETE ===\n")
