library(tidyverse)
library(janitor)

# ── Part A: Statewide totals (state-level monthly file) ───────────────────────

shutoffs_state_raw <- read.csv(
  "../../Cleaned_Data/eia/112/20-04-2026-eia-112-shutoffs.csv"
) %>%
  clean_names()

co_state <- shutoffs_state_raw %>%
  filter(state == "Colorado", year == 2024)

co_statewide <- co_state %>%
  summarise(
    total_electric_shutoffs  = sum(electric_shutoffs, na.rm = TRUE),
    total_gas_shutoffs       = sum(gas_shutoffs, na.rm = TRUE),
    total_combined_shutoffs  = total_electric_shutoffs + total_gas_shutoffs,
    avg_electric_customers   = mean(electric_customers, na.rm = TRUE),
    avg_gas_customers        = mean(gas_customers, na.rm = TRUE)
  ) %>%
  mutate(
    combined_shutoff_rate  = total_combined_shutoffs / avg_electric_customers,
    electric_shutoff_rate  = total_electric_shutoffs / avg_electric_customers,
    gas_shutoff_rate       = total_gas_shutoffs / avg_gas_customers
  )

output_statewide <- paste0(
  "outputs/",
  format(Sys.Date(), "%d-%m-%Y"),
  "-co-shutoffs-statewide.csv"
)

write.csv(co_statewide, output_statewide, row.names = FALSE)
message("Written: ", output_statewide)

# ── Part B: By ownership type (utility-annual file) ───────────────────────────

shutoffs_util_raw <- read.csv(
  "../../Cleaned_Data/eia/112/09-06-2026-eia-112-utility-annual.csv"
) %>%
  clean_names()

co_util <- shutoffs_util_raw %>%
  filter(
    state == "CO",
    is.na(bad_data_flag) | bad_data_flag != "Y"
  ) %>%
  mutate(
    ownership_label = case_when(
      ownership == "Investor Owned" ~ "IOU",
      ownership == "Municipal"      ~ "Muni",
      ownership == "Cooperative"    ~ "Coop"
    )
  )

# Aggregate by ownership × energy_type, then pivot wide
co_util_agg <- co_util %>%
  group_by(ownership_label, energy_type) %>%
  summarise(
    shutoffs       = sum(shutoffs, na.rm = TRUE),
    customer_count = sum(customer_count, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  pivot_wider(
    names_from  = energy_type,
    values_from = c(shutoffs, customer_count)
  ) %>%
  mutate(
    shutoffs_electric       = coalesce(shutoffs_electric, 0),
    shutoffs_gas            = coalesce(shutoffs_gas, 0),
    customer_count_electric = coalesce(customer_count_electric, 0),
    customer_count_gas      = coalesce(customer_count_gas, 0)
  )

# Shares and rates
co_by_ownership <- co_util_agg %>%
  mutate(
    combined_shutoffs    = shutoffs_electric + shutoffs_gas,
    pct_electric_shutoffs = shutoffs_electric / sum(shutoffs_electric) * 100,
    pct_gas_shutoffs      = shutoffs_gas / sum(shutoffs_gas[shutoffs_gas > 0]) * 100,
    pct_combined_shutoffs = combined_shutoffs / sum(combined_shutoffs) * 100,
    electric_shutoff_rate = case_when(
      customer_count_electric > 0 ~ shutoffs_electric / customer_count_electric,
      TRUE ~ NA_real_
    ),
    gas_shutoff_rate = case_when(
      customer_count_gas > 0 ~ shutoffs_gas / customer_count_gas,
      TRUE ~ NA_real_
    ),
    combined_shutoff_rate = case_when(
      customer_count_electric > 0 ~ combined_shutoffs / customer_count_electric,
      TRUE ~ NA_real_
    )
  )

output_ownership <- paste0(
  "outputs/",
  format(Sys.Date(), "%d-%m-%Y"),
  "-co-shutoffs-by-ownership.csv"
)

write.csv(co_by_ownership, output_ownership, row.names = FALSE)
message("Written: ", output_ownership)
