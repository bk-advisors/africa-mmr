# africa-mmr

Interactive horizontal bar chart of **maternal mortality ratios (MMR per 100,000 live births)** across African countries, using the latest reported year per country from the WHO Global Health Observatory.

**Live chart:** https://bk-advisors.github.io/africa-mmr/

## Outputs

| Asset | Purpose | Path |
|-------|---------|------|
| Interactive HTML | GitHub Pages landing page (ggiraph tooltips) | [index.html](index.html) |
| Portrait PNG (4:5) | LinkedIn image post (3000×3750 @ 300 dpi) | [output/africa-mmr.png](output/africa-mmr.png) |
| Landscape PNG (1.91:1) | LinkedIn link share (4200×2200 @ 300 dpi) | [output/africa-mmr-wide.png](output/africa-mmr-wide.png) |

## Data

| Column | Source | Indicator |
|--------|--------|-----------|
| `mmr`, `low`, `high` | WHO GHO | **MDG_0000000026** — Maternal mortality ratio, modeled, per 100,000 live births |
| `country` | WHO GHO country dimension | `DIMENSION/COUNTRY/DimensionValues` |

`R/prep_africa_mmr.R` selects the latest year per African country and joins on the country dimension for full names. Raw JSON dumps (`data/who_*_raw.json`) are gitignored — see the header of that script for the curl commands to re-fetch them (R's `fromJSON()` on the URL fails on Windows due to TLS).

## Repo layout

```
interactive-africa-mmr.qmd   Quarto source for the interactive chart
index.html                   Rendered self-contained output (served by Pages)
_quarto.yml                  Quarto project config
data/africa_mmr.csv          Cleaned dataset (country, code, year, mmr, low, high)
R/
  theme_bka.R                BKA-branded ggplot2 theme (local copy)
  prep_africa_mmr.R          Raw WHO JSON  ->  africa_mmr.csv
  africa-mmr-linkedin.R      Generates the portrait + landscape PNGs
  audit_figures.R            Verifies post claims against the CSV
  validate_sources.R         Cross-checks CSV vs the live WHO API
  fetch_validation_data.R    Caches API responses to .rds for reports
output/                      Publication-ready PNGs
```

## Build

All commands run from the repo root.

```bash
# 1. Refresh CSV from raw WHO JSON (see R/prep_africa_mmr.R header for curl)
Rscript R/prep_africa_mmr.R

# 2. Verify numeric claims used in the LinkedIn post
Rscript R/audit_figures.R

# 3. Cross-check CSV against live WHO API
Rscript R/validate_sources.R

# 4. LinkedIn PNGs -> output/
Rscript R/africa-mmr-linkedin.R

# 5. Interactive HTML -> index.html
quarto render interactive-africa-mmr.qmd
```

`_quarto.yml`'s `render:` key lists only `interactive-africa-mmr.qmd`, so the RStudio "Render" button won't accidentally build standalone reports.

## Chart conventions

- Countries are sorted ascending by `mmr`; ordering is locked in via `factor(country, levels = country)` so ggplot draws lowest at the bottom, highest at the top.
- `LABEL_THRESHOLD <- 200`: bars ≥ 200 get white in-bar labels; bars < 200 get blue outside-bar labels. This constant is duplicated in both the qmd and `R/africa-mmr-linkedin.R` — keep them in sync.
- BKA palette: navy `#242852` (bars/title), amber `#F8A623` (brand stripe), dark blue `#005CB9` (outside-bar labels), grey `#606060` (subtitle/caption/gridlines).

## Deployment

- GitHub Pages serves from `main` branch root (`/`).
- After pushing to `main`, Pages redeploys automatically (1–2 min).
- The qmd's YAML sets `output-file: index.html` so Pages serves it as the landing page.
- `.nojekyll` prevents Jekyll from processing the site.

## Requirements

R packages: `ggplot2`, `dplyr`, `patchwork`, `ggiraph`, `scales`, `jsonlite`. Quarto CLI for HTML rendering.
