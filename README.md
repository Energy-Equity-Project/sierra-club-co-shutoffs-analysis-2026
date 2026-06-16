# Colorado Shutoffs & Energy Affordability Analysis (2026)

Analysis for Sierra Club Colorado examining residential energy costs, affordability,
and insecurity across Colorado for 2022–2024.

## Themes

| # | Theme | Source | Geography | Years |
|---|-------|--------|-----------|-------|
| 1 | Electric rates & bill increases | EIA Form 861 | Statewide, by ownership type | 2022, 2024 |
| 2 | Residential gas price & bill increases | EIA Form 176 | Statewide | 2022, 2024 |
| 3 | Energy burden & affordability by FPL | DOE LEAD | Colorado census tracts | 2022 |
| 4 | Energy insecurity prevalence | Census Household Pulse Survey | Colorado respondents | 2024 |
| 5 | Median household income change | ACS 5-year estimates | Colorado census tracts | 2022, 2024 |

## How to Run

### Prerequisites

1. **R packages:** `tidyverse`, `janitor`
2. **B11001 household counts** (required for script 05 only):

```r
source("../../Internal/data-pipelines/eep-pipeline-core/collectors/acs_collector.R")
acs_collect(variables = "B11001_001", geography = "tract", year = 2022, state = "CO")
acs_collect(variables = "B11001_001", geography = "tract", year = 2024, state = "CO")
```

Requires `CENSUS_API_KEY` in your environment (set in `.Renviron` or shell).

### Run scripts in order

```bash
Rscript R/01_electric_rates_bills.R
Rscript R/02_gas_prices_bills.R
Rscript R/03_energy_burden.R
Rscript R/04_energy_insecurity.R
Rscript R/05_median_income.R
```

Outputs are written to `outputs/` with a `dd-mm-yyyy-` date prefix.

### Sanity checks

- Electric rate: ~12–15 ¢/kWh
- Gas price: falls 12.72 → 10.58 $/Mcf (2022→2024)
- Energy burden rises as FPL falls (monotonically)
- Energy insecurity shares between 0 and 1
- Weighted median income ~$85–95K range, rising 2022→2024

## Data Provenance

All source data is national; scripts filter to Colorado.

| Dataset | Path | Description |
|---------|------|-------------|
| EIA 861 | `../../Cleaned_Data/eia/861/14-02-2026-eia-861-sales.csv` | Utility-level sales, revenue, customers by state/year |
| EIA 176 | `../../Cleaned_Data/eia/176/15-04-2026-eia-176-residential-natural-gas.csv` | State-level residential gas prices and bills |
| DOE LEAD | `../../Cleaned_Data/doe/lead/co-census_tract-lead-2022.csv` | Tract-level energy burden, costs, income by FPL bin |
| Census Pulse | `../../Cleaned_Data/us_census/household_pulse_survey/02-04-2026-pulse-energy-puf-harmonized.csv` | Harmonized household energy hardship microdata |
| ACS B19013 | `../../Data/us_census/acs/{year}/tract/B19013_co.csv` | Tract-level median household income |
| ACS B11001 | `../../Data/us_census/acs/{year}/tract/B11001_co.csv` | Tract-level total households (weighting) |

## Methodology

### Electric rates & bills (EIA 861)
Residential sector only. Utilities grouped by ownership type (IOU, Municipal, Cooperative).
Average rate = total residential revenue / total residential kWh × 100 (¢/kWh).
Average annual bill = total residential revenue / total residential customers.

### Gas prices & bills (EIA 176)
Pre-computed state-level averages from the cleaned file. Colorado rows only.

### Energy burden (DOE LEAD)
**(a) Weighted average burden per FPL bin** — aggregate-ratio method:
`burden = (electric + gas + other_fuel) / income`, where each component is computed as
`sum(cost × units) / sum(valid_units)` across tracts within each FPL bin. This avoids
bias from averaging individual rates rather than pooling costs and incomes.

**(b) Share of households with unaffordable burden (>6%)** — row-level:
Row energy cost = sum of average electric, gas, and other fuel costs per unit.
Rows with zero/NA income are excluded (count logged). Threshold: >6% of income.

### Energy insecurity (Census Pulse)
Computed per survey cycle (2024 cycles 01–09), then averaged equally across cycles.
Hardship = any response other than "never" (excludes non-response). Composite
"energy insecure" = respondent flagged ANY of the three hardship indicators.

### Median income (ACS)
Household-weighted average of tract-level median incomes:
`weighted_income = sum(tract_median × tract_households) / sum(tract_households)`.
**Note:** this is an approximation of the statewide weighted-average median, not a true
statewide median. Tracts with suppressed (NA) median income are dropped and logged.
