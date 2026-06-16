library(tidyverse)
library(janitor)

# ── Data ──────────────────────────────────────────────────────────────────────

gas_raw <- read.csv(
  "../../Cleaned_Data/eia/176/15-04-2026-eia-176-residential-natural-gas.csv"
) %>%
  clean_names()

# ── Filter to Colorado, 2022 & 2024 ──────────────────────────────────────────

gas_co <- gas_raw %>%
  filter(
    state == "Colorado",
    year %in% c(2022, 2024)
  ) %>%
  select(
    year,
    residential_nat_gas_price_dollar_per_mcf,
    avg_annual_residential_nat_gas_bill,
    avg_monthly_residential_nat_gas_bill,
    residential_nat_gas_customer_count
  )

# ── Pivot to wide and compute changes ─────────────────────────────────────────

gas_wide <- gas_co %>%
  pivot_wider(
    names_from  = year,
    values_from = c(
      residential_nat_gas_price_dollar_per_mcf,
      avg_annual_residential_nat_gas_bill,
      avg_monthly_residential_nat_gas_bill,
      residential_nat_gas_customer_count
    )
  ) %>%
  mutate(
    price_change_dollar_per_mcf   = residential_nat_gas_price_dollar_per_mcf_2024 -
                                      residential_nat_gas_price_dollar_per_mcf_2022,
    price_pct_change              = price_change_dollar_per_mcf /
                                      residential_nat_gas_price_dollar_per_mcf_2022 * 100,
    annual_bill_change_usd        = avg_annual_residential_nat_gas_bill_2024 -
                                      avg_annual_residential_nat_gas_bill_2022,
    annual_bill_pct_change        = annual_bill_change_usd /
                                      avg_annual_residential_nat_gas_bill_2022 * 100,
    monthly_bill_change_usd       = avg_monthly_residential_nat_gas_bill_2024 -
                                      avg_monthly_residential_nat_gas_bill_2022,
    monthly_bill_pct_change       = monthly_bill_change_usd /
                                      avg_monthly_residential_nat_gas_bill_2022 * 100
  )

# ── Write output ──────────────────────────────────────────────────────────────

output_path <- paste0(
  "outputs/",
  format(Sys.Date(), "%d-%m-%Y"),
  "-co-gas-prices-bills.csv"
)

write.csv(gas_wide, output_path, row.names = FALSE)
message("Written: ", output_path)
