# ---- Fetch validation data from the WHO GHO API ----
# Run this BEFORE rendering reports/data-validation-report.qmd (if used).
# Saves results to data/validation_cache.rds.
#
# Usage: Rscript R/fetch_validation_data.R

library(jsonlite)
library(dplyr)

csv <- read.csv("data/africa_mmr.csv")

# ---- 1. WHO maternal mortality indicators (sanity check that MDG_0000000026
#         is the correct indicator code among similarly-named ones) ----
cat("Fetching WHO indicator list (filter: 'maternal')...\n")
ind_url <- "https://ghoapi.azureedge.net/api/Indicator?$filter=contains(IndicatorName,%27maternal%27)"
indicators <- fromJSON(ind_url)$value %>%
  select(IndicatorCode, IndicatorName)
cat("  Found", nrow(indicators), "indicators mentioning 'maternal'\n")

# ---- 2. Full MDG_0000000026 data for Africa (latest year per country) ----
cat("Fetching WHO MDG_0000000026 (maternal mortality ratio) for Africa...\n")
mmr_url <- paste0(
  "https://ghoapi.azureedge.net/api/MDG_0000000026",
  "?$filter=ParentLocation%20eq%20%27Africa%27"
)

mmr_raw <- fromJSON(mmr_url)
mmr     <- mmr_raw$value
while (!is.null(mmr_raw[["@odata.nextLink"]])) {
  mmr_raw <- fromJSON(mmr_raw[["@odata.nextLink"]])
  mmr     <- rbind(mmr, mmr_raw$value)
}

mmr_latest <- mmr %>%
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
cat("  WHO latest-year records:", nrow(mmr_latest), "\n")

# ---- 3. WHO country dimension (Code → Title lookup) ----
cat("Fetching WHO country dimension...\n")
country_url <- "https://ghoapi.azureedge.net/api/DIMENSION/COUNTRY/DimensionValues"
countries <- fromJSON(country_url)$value %>%
  transmute(country_code = Code, country = Title)
cat("  Country dimension records:", nrow(countries), "\n")

# ---- Save everything ----
cache <- list(
  indicators = indicators,
  mmr_latest = mmr_latest,
  countries  = countries,
  fetched_at = Sys.time()
)

saveRDS(cache, "data/validation_cache.rds")
cat("\nSaved to data/validation_cache.rds\n")
cat("Timestamp:", format(cache$fetched_at), "\n")
