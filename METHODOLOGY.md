# Methodology: Colorado Energy Affordability & Insecurity Analysis (2022–2024)

This document describes the data sources, filters, and computations behind the seven summary
datasets produced for Sierra Club's Colorado energy affordability work. It is intended for
partner review and future analysts; it does not require reading the R source code.

---

## 1. Overview

The analysis quantifies Colorado residential energy costs, affordability, and insecurity
across seven themes: electric rates, natural gas prices, energy burden, energy insecurity,
median household income, disconnections for non-payment, and utility profits. The reference
years are 2022 and 2024 (or the closest available vintage per source).

All source data are national in scope; each script filters to Colorado before computing
summaries. Outputs are dated CSV files written to `outputs/`.

The seven R scripts run independently and in order:

| Order | Script | Theme |
|-------|--------|-------|
| 01 | `R/01_electric_rates_bills.R` | Electric rates & bills |
| 02 | `R/02_gas_prices_bills.R` | Natural gas prices & bills |
| 03 | `R/03_energy_burden.R` | Energy burden |
| 04 | `R/04_energy_insecurity.R` | Energy insecurity |
| 05 | `R/05_median_income.R` | Median household income |
| 06 | `R/06_shutoffs.R` | Shutoffs (disconnections for non-payment) |
| 07 | `R/07_utility_profits.R` | Utility profits |

---

## 2. Data Sources

| Theme | Dataset | Publisher | Vintage | File consumed (relative to repo root) |
|-------|---------|-----------|---------|---------------------------------------|
| Electric | EIA Form 861 — Sales to Ultimate Customers | U.S. Energy Information Administration | Data years 1990–2024; cleaned 2026-02-14 | `../../Cleaned_Data/eia/861/14-02-2026-eia-861-sales.csv` |
| Gas | EIA Form 176 — Annual Natural Gas Report (residential) | U.S. Energy Information Administration | ~1997–present; cleaned 2026-04-15 | `../../Cleaned_Data/eia/176/15-04-2026-eia-176-residential-natural-gas.csv` |
| Burden | DOE LEAD — FPL Census Tract (Low-Income Energy Affordability Data) | U.S. Department of Energy | 2022 vintage | `../../Cleaned_Data/doe/lead/co-census_tract-lead-2022.csv` |
| Insecurity | Census Household Pulse Survey — harmonized energy microdata | U.S. Census Bureau | 2024 Phase 4, Cycles 01–09 | `../../Cleaned_Data/us_census/household_pulse_survey/02-04-2026-pulse-energy-puf-harmonized.csv` |
| Income | ACS 5-year — Table B19013 (median household income) | U.S. Census Bureau | 2022 vintage (2018–2022); 2024 vintage (2020–2024) | `../../Data/us_census/acs/{year}/tract/B19013_co.csv` |
| Income (weights) | ACS 5-year — Table B11001 (total households) | U.S. Census Bureau | 2022 vintage (2018–2022); 2024 vintage (2020–2024) | `../../Data/us_census/acs/{year}/tract/B11001_co.csv` |
| Shutoffs (state) | EIA Form 112 — Monthly Disconnections, state-level | U.S. Energy Information Administration | Data year 2024; cleaned 2026-04-20 | `../../Cleaned_Data/eia/112/20-04-2026-eia-112-shutoffs.csv` |
| Shutoffs (utility) | EIA Form 112 — Annual Disconnections, utility-level with ownership | U.S. Energy Information Administration | Data year 2024; cleaned 2026-06-09 | `../../Cleaned_Data/eia/112/09-06-2026-eia-112-utility-annual.csv` |
| Profits | EPI Utility Profits tracker (2021–2025) | Energy & Policy Institute | Last updated 2026-05-08 | `../../Data/epi/2021 - 2025 Utility Profits (Make a copy to edit) _ Last Updated 5_8_26.xlsx` (sheet "Data") |

**Upstream pipelines.** The EIA and DOE LEAD cleaned files are produced by processors in
`Internal/data-pipelines/eep-pipeline-core/processors/`. The ACS files are collected via
`eep-pipeline-core/collectors/acs_collector.R`.

---

## 3. Per-Theme Methodology

### 3.1 Electric Rates & Bills (`01_electric_rates_bills.R`, EIA Form 861)

**Input:** `14-02-2026-eia-861-sales.csv` — annual utility-level sales data (revenue,
kilowatt-hours, customer counts) broken out by sector and ownership type.

**Filter:** State = `CO`; years ∈ {2022, 2024}; sector = residential; ownership type ∈
{`Investor Owned`, `Municipal`, `Cooperative`} (relabeled `IOU`, `Muni`, `Coop`).

**Aggregation:** Records are grouped by ownership label × year, then summed:
- `total_revenue_usd` = Σ residential revenue (USD)
- `total_kwh` = Σ residential kWh delivered
- `total_customers` = Σ residential customer accounts

**Derived metrics (pooled-ratio method):**
- `avg_rate_cents_per_kwh` = `total_revenue_usd / total_kwh × 100`
- `avg_annual_bill` = `total_revenue_usd / total_customers`
- `avg_monthly_bill` = `avg_annual_bill / 12`

Pooling revenue and kWh before dividing avoids weighting bias that would arise from
averaging per-utility rates.

**Output shape:** Wide — one row per ownership type, with 2022 and 2024 columns for each
metric plus absolute and percentage change columns.

---

### 3.2 Natural Gas Prices & Bills (`02_gas_prices_bills.R`, EIA Form 176)

**Input:** `15-04-2026-eia-176-residential-natural-gas.csv` — state-year panel of
residential natural gas metrics pre-computed by the EIA 176 processor.

**Filter:** State = `Colorado`; years ∈ {2022, 2024}.

**Metrics used (pre-computed in cleaned file):**
- `residential_nat_gas_price_dollar_per_mcf` — price per thousand cubic feet
- `avg_annual_residential_nat_gas_bill` — average annual customer bill (USD)
- `avg_monthly_residential_nat_gas_bill` — average monthly customer bill (USD)
- `residential_nat_gas_customer_count` — number of residential customers

No further aggregation is performed; values are taken as-is from the cleaned file.

**Output shape:** Wide — one row (statewide), with 2022 and 2024 columns for each metric
plus absolute and percentage change columns.

---

### 3.3 Energy Burden (`03_energy_burden.R`, DOE LEAD 2022)

**Input:** `co-census_tract-lead-2022.csv` — tract-level DOE LEAD data for Colorado,
including energy cost and income variables pre-weighted by housing unit counts.

The script produces two separate computations and two output files.

#### (a) Weighted average burden by FPL — aggregate-ratio method

Records are grouped by `fpl150` (federal poverty level band). Within each band, four
cost/income components are aggregated by summing their pre-weighted products and valid-unit
counts from the LEAD file:

| Component | Weighted-product column | Valid-units column |
|-----------|------------------------|-------------------|
| Electricity | `elep_x_units` | `elep_valid_units` |
| Gas | `gasp_x_units` | `gasp_valid_units` |
| Other fuel | `fulp_x_units` | `fulp_valid_units` |
| Income | `hincp_x_units` | `hincp_valid_units` |

Per-component average: `avg_cost = Σ(cost × units) / Σ(valid_units)`

Energy burden: `avg_energy_burden = (avg_electric_cost + avg_gas_cost + avg_other_cost) / avg_income`

This aggregate-ratio method pools costs and incomes across tracts before dividing, avoiding
the bias that arises from averaging tract-level burden ratios directly.

#### (b) Share and count of households with unaffordable burden (>6%)

Rows with `avg_income` = NA or ≤ 0 are dropped (count of dropped rows and housing units
is logged to console).

Per remaining row, a row-level energy burden is computed:

`row_energy = coalesce(avg_electricity_cost, 0) + coalesce(avg_gas_cost, 0) + coalesce(avg_other_fuel_cost, 0)`

`row_burden = row_energy / avg_income`

`unaffordable = (row_burden > 0.06)`

Results are weighted by `units` (housing units per tract-FPL row) to produce counts and
shares of households with unaffordable burden — reported both per FPL band and statewide.

**Output shape:** Two files:
- `…-co-energy-burden-by-fpl.csv` — one row per FPL band; columns from both (a) and (b).
- `…-co-energy-burden-summary.csv` — one statewide row with total households, count
  unaffordable, and share unaffordable.

---

### 3.4 Energy Insecurity (`04_energy_insecurity.R`, Census Household Pulse Survey)

**Input:** `02-04-2026-pulse-energy-puf-harmonized.csv` — harmonized Pulse Survey microdata.
Only seven columns are read to reduce memory use from the ~195 MB file:
`state`, `survey_year`, `survey_wave`, `energy`, `hse_temp`, `enrgy_bill`, `person_weight`.

**Filter:** State = `CO`; `survey_year` = 2024 (Cycles 01–09 of Phase 4).

**Hardship definition:** A response is a hardship if it equals `almost_every_month`,
`some_months`, or `1_or_2_months` (i.e., anything other than `never` or NA).

**Per-cycle computation:** For each survey wave (cycle), three person-weighted hardship
shares are computed over respondents with a valid (non-NA) response to that question:

| Metric | Source column |
|--------|--------------|
| `forgo_necessities` | `energy` — went without necessities to pay an energy bill |
| `unsafe_temperature` | `hse_temp` — kept home at unsafe temperature to manage costs |
| `unable_to_pay` | `enrgy_bill` — unable to pay an energy bill in full |

Weighted share formula: `Σ person_weight[hardship & valid] / Σ person_weight[valid]`

**Composite `energy_insecure`:** A respondent is flagged energy-insecure if they reported
any of the three hardships. The denominator is all respondents with at least one non-NA
response among the three questions.

`energy_insecure_share = Σ person_weight[composite_valid & composite_flag] / Σ person_weight[composite_valid]`

Cycles in which all three energy question columns are entirely NA are skipped and logged.

**Cross-cycle average:** The four per-cycle shares are averaged across contributing cycles
with equal weight (simple mean, `na.rm = TRUE`).

**Output shape:** Long — one row per metric (`forgo_necessities`, `unsafe_temperature`,
`unable_to_pay`, `energy_insecure`) with columns `metric`, `share`, and `n_cycles_used`.

---

### 3.5 Median Household Income (`05_median_income.R`, ACS 5-Year)

**Inputs (per year):**
- `B19013_co.csv` — tract-level median household income (ACS Table B19013, `estimate` column)
- `B11001_co.csv` — tract-level total households (ACS Table B11001, `estimate` column)

Both files are read for 2022 (2018–2022 5-year) and 2024 (2020–2024 5-year). The two tables
are inner-joined on `GEOID`.

**Exclusions:** Tracts with a suppressed (NA) median income are dropped. The count of
dropped tracts and the corresponding household total are logged to console.

**Weighted median income:**

`weighted_median_income = Σ(median_income × households) / Σ households`

This is a household-weighted average of tract-level ACS 5-year medians. It is an
**approximation of the statewide median, not a true statewide median**, and is documented
as such in the output file.

**Output shape:** Four rows — one observed value per year (2022, 2024), one absolute change
row (`absolute_2022_to_2024`), and one percentage change row (`pct_change_2022_to_2024`),
identified by a `change_type` column.

---

### 3.6 Shutoffs (`06_shutoffs.R`, EIA Form 112)

EIA Form 112 (first published for data year 2024) collects monthly utility-reported
disconnections for non-payment. The script produces two outputs from two complementary
source files.

#### (a) Statewide totals — annual basis

**Input:** `20-04-2026-eia-112-shutoffs.csv` — monthly state-level disconnection data.

**Filter:** State = `Colorado`; year = 2024 (12 monthly rows).

**Aggregation:** Summed across all 12 months to produce annual totals:
- `total_electric_shutoffs` = Σ monthly electric shutoffs
- `total_gas_shutoffs` = Σ monthly gas shutoffs
- `total_combined_shutoffs` = total electric + total gas
- `avg_electric_customers` = mean monthly electric customer count
- `avg_gas_customers` = mean monthly gas customer count

Reporting shutoffs as annual totals (rather than monthly averages) is consistent with how
disconnections are typically reported in policy contexts and makes the scale interpretable.

**Derived rates (annualized):**
- `combined_shutoff_rate = total_combined_shutoffs / avg_electric_customers`
  (electric customers used as the denominator for the combined rate, reflecting the larger
  and more comparable customer universe)
- `electric_shutoff_rate = total_electric_shutoffs / avg_electric_customers`
- `gas_shutoff_rate = total_gas_shutoffs / avg_gas_customers`

**Output shape:** One statewide row.

#### (b) By ownership type — utility-annual basis

**Input:** `09-06-2026-eia-112-utility-annual.csv` — 2024 annual totals per utility × fuel,
enriched with ownership type (`Investor Owned`, `Municipal`, `Cooperative`), 12-month mean
customer counts, and a `bad_data_flag`.

**Filter:** State = `CO`; rows with `bad_data_flag = "Y"` excluded. One CO row is flagged
("Fort Morgan City of - CO", gas), consistent with the dataset's own percentile methodology.

**Ownership labels:** Relabeled with `case_when()` to match the convention in script 01:
`Investor Owned` → `IOU`, `Municipal` → `Muni`, `Cooperative` → `Coop`.

**Aggregation:** Records are grouped by `ownership_label × energy_type`, then summed
(`shutoffs`, `customer_count`). The result is pivoted wide so each ownership type occupies
one row with separate electric and gas columns. Cooperative gas columns resolve to 0 (no CO
coop gas utilities); zeros are preserved via `coalesce(., 0)`.

**Derived metrics:**
- `combined_shutoffs = shutoffs_electric + shutoffs_gas`
- **Ownership shares** (within the utility-annual CO universe):
  - `pct_electric_shutoffs = shutoffs_electric / Σ shutoffs_electric × 100`
  - `pct_gas_shutoffs = shutoffs_gas / Σ shutoffs_gas × 100` (denominator excludes Coop which is 0)
  - `pct_combined_shutoffs = combined_shutoffs / Σ combined_shutoffs × 100`
- **Customer-weighted shutoff rates** (pooled-ratio — equivalent to a customer-weighted
  average of utility-level rates):
  - `electric_shutoff_rate = shutoffs_electric / customer_count_electric`
  - `gas_shutoff_rate = shutoffs_gas / customer_count_gas` (NA for Coop, no gas customers)
  - `combined_shutoff_rate = combined_shutoffs / customer_count_electric`

**Reconciliation note:** Utility-level shares are computed within the utility-annual dataset.
Because the two source workbooks differ and one bad-data row is excluded, the utility-annual
CO totals may not exactly match the state-level file's CO totals.

**Output shape:** Three rows — one per ownership type (IOU / Muni / Coop).

---

### 3.7 Utility Profits (`07_utility_profits.R`, EPI)

**Input:** EPI Utility Profits tracker Excel file, sheet "Data" — ~110 utility rows with a
single header row. Profit figures are in $millions. The file is read with `readxl::read_excel()`
and column names are standardized with `clean_names()`, yielding columns such as `utility`,
`service_state_s`, `x2021_profit_millions`, `x2025_profit_millions`,
`x2021_profit_portion_of_bill_percent`, and `x2025_profit_portion_of_bill_percent`.

**Character-to-numeric conversion:** Profit and bill-share columns import as character because
some rows contain the string `"N/A"`. All four metric columns are wrapped in `as.numeric()`,
which converts `"N/A"` to `NA` automatically.

**Filter:** `service_state_s` is a comma-separated list of state abbreviations. The script
filters using `str_detect(service_state_s, "\\bCO\\b")` (word-boundary anchors) to match
"CO" exactly without catching state codes that contain "CO" as a substring. This matches
**one utility: "Xcel (electric subsidiaries)"**.

**Derived metrics:**
- `profit_change_musd = profit_2025_musd − profit_2021_musd`
- `profit_pct_growth = profit_change_musd / profit_2021_musd × 100`
- `bill_share_2021_pct = as.numeric(x2021_profit_portion_of_bill_percent) × 100`
  (EPI stores shares as decimals, e.g. 0.1319; multiplying by 100 yields percentage points)
- `bill_share_2025_pct = as.numeric(x2025_profit_portion_of_bill_percent) × 100`

**Output shape:** One row (Xcel only), printed to console. No CSV is written; results are
reported directly in `results.md`.

**Caveats:**
- Xcel's figures are an 8-state aggregate across its "electric subsidiaries" service territory
  (CO, MI, MN, NM, ND, SD, TX, WI; HQ in Minnesota). They are not Colorado-specific profit.
  Black Hills (which serves Colorado) appears in the EPI dataset under SD/WY/MT/NV only;
  Tri-State and PSCo are absent. Xcel is the only Colorado-serving utility in the dataset.
- EPI is an energy policy advocacy organization; treat figures as directionally indicative
  rather than regulatory-grade financial data.

---

## 4. Cross-Cutting Conventions

- **R packages:** `tidyverse`, `janitor`; pipe operator `%>%`; column names standardized
  via `clean_names()`.
- **Conditional logic:** `case_when()` used for multi-way recoding (e.g., ownership labels).
- **Ungrouping:** `ungroup()` called after every `summarise()`.
- **Output filenames:** `dd-mm-yyyy-<descriptor>.csv` via `format(Sys.Date(), "%d-%m-%Y")`.
- **Data not copied into repo:** all source files are referenced by relative path to the
  shared `Data/` and `Cleaned_Data/` directories.

---

## 5. Outputs

| Output file (date prefix omitted) | Produced by | Contents |
|-----------------------------------|-------------|----------|
| `…-co-electric-rates-bills-by-ownership.csv` | `01_electric_rates_bills.R` | Rate (¢/kWh), annual bill, monthly bill by ownership type (IOU/Muni/Coop); 2022 & 2024 values; absolute and % change |
| `…-co-gas-prices-bills.csv` | `02_gas_prices_bills.R` | Gas price ($/Mcf), annual bill, monthly bill, customer count; 2022 & 2024; absolute and % change |
| `…-co-energy-burden-by-fpl.csv` | `03_energy_burden.R` | Avg electric/gas/other costs, avg income, avg burden, % unaffordable, household count — per FPL band |
| `…-co-energy-burden-summary.csv` | `03_energy_burden.R` | Statewide total households, count with burden >6%, share with burden >6% |
| `…-co-energy-insecurity.csv` | `04_energy_insecurity.R` | Share energy insecure (composite + three component metrics); n_cycles_used |
| `…-co-median-income-weighted.csv` | `05_median_income.R` | Household-weighted average median income for 2022 and 2024; absolute and % change; n_tracts and total_households per year |
| `…-co-shutoffs-statewide.csv` | `06_shutoffs.R` | 2024 annual electric, gas, and combined shutoff totals; avg customer counts; annualized electric, gas, and combined shutoff rates |
| `…-co-shutoffs-by-ownership.csv` | `06_shutoffs.R` | Electric, gas, and combined shutoffs and customer counts; % share of CO shutoffs; shutoff rates — per ownership type (IOU/Muni/Coop) |
| *(none)* | `07_utility_profits.R` | No CSV produced; results (Xcel profit 2021 & 2025, change, bill share) are printed to console and reported directly in `results.md` |

---

## 6. Reproducibility & Prerequisites

### Run order

Run each script from the repo root in numerical order:

```
Rscript R/01_electric_rates_bills.R
Rscript R/02_gas_prices_bills.R
Rscript R/03_energy_burden.R
Rscript R/04_energy_insecurity.R
Rscript R/05_median_income.R
Rscript R/06_shutoffs.R
Rscript R/07_utility_profits.R
```

Scripts 01–04, 06, and 07 have no prerequisites beyond the source files listed in Section 2.

### Prerequisite for script 05: download B11001 household counts

Before running `05_median_income.R`, the ACS B11001 tract files must be present. Download
them using the workspace ACS collector (requires `CENSUS_API_KEY` in the environment):

```r
source("../../Internal/data-pipelines/eep-pipeline-core/collectors/acs_collector.R")
acs_collect(variables = "B11001_001", geography = "tract", year = 2022, state = "CO")
acs_collect(variables = "B11001_001", geography = "tract", year = 2024, state = "CO")
```

### Known path note for B11001

The `acs_collector.R` script hardcodes its output path relative to the
`eep-pipeline-core/` directory (`../../../Data/…`). When invoked from this repo (which sits
two levels below the workspace root at `External/sierra-club-co-shutoffs-analysis-2026/`),
the collector writes files one level above the workspace root rather than into the workspace
`Data/` folder. The B11001 CO files were therefore manually relocated into
`Energy Equity Project/Data/us_census/acs/{2022,2024}/tract/`, which is the path that
script 05's `../../Data/…` references resolve to correctly.
