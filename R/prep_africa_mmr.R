# prep_africa_mmr.R
# Processes the raw WHO Global Health Observatory MMR JSON into a clean CSV
# of African countries' latest reported maternal mortality ratio (MMR per
# 100,000 live births), with full country names from the WHO country dimension.
#
# Run from project root:
#   Rscript R/prep_africa_mmr.R
#
# Inputs (download via bash curl — R can't reach the WHO API directly on Windows):
#   curl -fsSL "https://ghoapi.azureedge.net/api/MDG_0000000026" \
#        -o data/who_mmr_raw.json
#   curl -fsSL "https://ghoapi.azureedge.net/api/DIMENSION/COUNTRY/DimensionValues" \
#        -o data/who_countries_raw.json
#
# Output:
#   data/africa_mmr.csv  — country, country_code, year, mmr, low, high

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
})

cat("Processing WHO MMR data...\n")

mmr_raw       <- fromJSON("data/who_mmr_raw.json")$value
countries_raw <- fromJSON("data/who_countries_raw.json")$value

# ---- Country code → full name lookup ----
country_lookup <- countries_raw %>%
  transmute(country_code = Code, country = Title)

# ---- Take the latest year per African country ----
africa_mmr <- mmr_raw %>%
  filter(ParentLocation == "Africa", SpatialDimType == "COUNTRY") %>%
  group_by(SpatialDim) %>%
  slice_max(TimeDim, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    country_code = SpatialDim,
    year         = as.integer(TimeDim),
    mmr          = NumericValue,
    low          = Low,
    high         = High
  ) %>%
  left_join(country_lookup, by = "country_code") %>%
  arrange(desc(mmr)) %>%
  select(country, country_code, year, mmr, low, high)

cat("  African countries with MMR:", nrow(africa_mmr), "\n")
cat("  Year range:", min(africa_mmr$year), "-", max(africa_mmr$year), "\n")
cat("  MMR range: ", round(min(africa_mmr$mmr)), "-", round(max(africa_mmr$mmr)), "\n")

write.csv(africa_mmr, "data/africa_mmr.csv", row.names = FALSE)
cat("Wrote: data/africa_mmr.csv\n")
