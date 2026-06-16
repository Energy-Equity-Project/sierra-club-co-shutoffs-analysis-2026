library(tidyverse)
library(janitor)

# ── Data ──────────────────────────────────────────────────────────────────────

lead_raw <- read.csv(
  "../../Cleaned_Data/doe/lead/co-census_tract-lead-2022.csv"
) %>%
  clean_names()

# ── (a) Weighted average burden by FPL — aggregate-ratio method ───────────────
# Avoids bias from averaging ratios; pools costs and incomes across tracts first.

burden_by_fpl <- lead_raw %>%
  group_by(fpl150) %>%
  summarise(
    sum_elep_x_units   = sum(elep_x_units,  na.rm = TRUE),
    sum_elep_valid     = sum(elep_valid_units, na.rm = TRUE),
    sum_gasp_x_units   = sum(gasp_x_units,  na.rm = TRUE),
    sum_gasp_valid     = sum(gasp_valid_units, na.rm = TRUE),
    sum_fulp_x_units   = sum(fulp_x_units,  na.rm = TRUE),
    sum_fulp_valid     = sum(fulp_valid_units, na.rm = TRUE),
    sum_hincp_x_units  = sum(hincp_x_units, na.rm = TRUE),
    sum_hincp_valid    = sum(hincp_valid_units, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    avg_electric_cost  = sum_elep_x_units  / sum_elep_valid,
    avg_gas_cost       = sum_gasp_x_units  / sum_gasp_valid,
    avg_other_cost     = sum_fulp_x_units  / sum_fulp_valid,
    avg_income         = sum_hincp_x_units / sum_hincp_valid,
    avg_energy_burden  = (avg_electric_cost + avg_gas_cost + avg_other_cost) / avg_income
  )

# ── (b) Share & count of households with unaffordable burden (>6%) ────────────

lead_valid <- lead_raw %>%
  filter(!is.na(avg_income), avg_income > 0)

n_dropped <- nrow(lead_raw) - nrow(lead_valid)
units_dropped <- sum(lead_raw$units[is.na(lead_raw$avg_income) | lead_raw$avg_income <= 0],
                     na.rm = TRUE)
message(
  "Dropped ", n_dropped, " rows (", round(units_dropped),
  " units) with NA or non-positive avg_income."
)

lead_burden <- lead_valid %>%
  mutate(
    row_energy  = coalesce(avg_electricity_cost, 0) +
                  coalesce(avg_gas_cost, 0) +
                  coalesce(avg_other_fuel_cost, 0),
    row_burden  = row_energy / avg_income,
    unaffordable = row_burden > 0.06
  )

unaffordable_by_fpl <- lead_burden %>%
  group_by(fpl150) %>%
  summarise(
    n_households    = sum(units, na.rm = TRUE),
    n_unaffordable  = sum(units[unaffordable], na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(pct_unaffordable = n_unaffordable / n_households)

# Statewide totals
unaffordable_statewide <- lead_burden %>%
  summarise(
    n_households   = sum(units, na.rm = TRUE),
    n_unaffordable = sum(units[unaffordable], na.rm = TRUE)
  ) %>%
  mutate(pct_unaffordable = n_unaffordable / n_households)

# ── Combine into per-FPL output ───────────────────────────────────────────────

burden_output <- burden_by_fpl %>%
  select(
    fpl150,
    avg_electric_cost,
    avg_gas_cost,
    avg_other_cost,
    avg_income,
    avg_energy_burden
  ) %>%
  left_join(
    unaffordable_by_fpl,
    by = "fpl150"
  )

# ── Write outputs ─────────────────────────────────────────────────────────────

date_prefix <- format(Sys.Date(), "%d-%m-%Y")

write.csv(
  burden_output,
  paste0("outputs/", date_prefix, "-co-energy-burden-by-fpl.csv"),
  row.names = FALSE
)
message("Written: outputs/", date_prefix, "-co-energy-burden-by-fpl.csv")

write.csv(
  unaffordable_statewide,
  paste0("outputs/", date_prefix, "-co-energy-burden-summary.csv"),
  row.names = FALSE
)
message("Written: outputs/", date_prefix, "-co-energy-burden-summary.csv")
