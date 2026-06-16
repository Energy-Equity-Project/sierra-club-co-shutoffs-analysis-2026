library(tidyverse)
library(janitor)

# ── Data ──────────────────────────────────────────────────────────────────────

sales_raw <- read.csv(
  "../../Cleaned_Data/eia/861/14-02-2026-eia-861-sales.csv"
) %>%
  clean_names()

# ── Filter & label ────────────────────────────────────────────────────────────

sales_co <- sales_raw %>%
  filter(
    state == "CO",
    year %in% c(2022, 2024),
    ownership %in% c("Investor Owned", "Municipal", "Cooperative")
  ) %>%
  mutate(
    ownership_label = case_when(
      ownership == "Investor Owned" ~ "IOU",
      ownership == "Municipal"      ~ "Muni",
      ownership == "Cooperative"    ~ "Coop"
    )
  )

# ── Aggregate by ownership × year ─────────────────────────────────────────────

sales_agg <- sales_co %>%
  group_by(ownership_label, year) %>%
  summarise(
    total_revenue_usd    = sum(residential_revenue_usd, na.rm = TRUE),
    total_kwh            = sum(residential_kwh, na.rm = TRUE),
    total_customers      = sum(residential_customers, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    avg_rate_cents_per_kwh = total_revenue_usd / total_kwh * 100,
    avg_annual_bill        = total_revenue_usd / total_customers,
    avg_monthly_bill       = avg_annual_bill / 12
  )

# ── Pivot to wide (2022 vs 2024) with change columns ──────────────────────────

sales_wide <- sales_agg %>%
  select(ownership_label, year, avg_rate_cents_per_kwh, avg_annual_bill, avg_monthly_bill) %>%
  pivot_wider(
    names_from  = year,
    values_from = c(avg_rate_cents_per_kwh, avg_annual_bill, avg_monthly_bill)
  ) %>%
  rename_with(~ gsub("_2022$", "_2022", .x)) %>%
  mutate(
    rate_change_cents      = avg_rate_cents_per_kwh_2024 - avg_rate_cents_per_kwh_2022,
    rate_pct_change        = rate_change_cents / avg_rate_cents_per_kwh_2022 * 100,
    annual_bill_change_usd = avg_annual_bill_2024 - avg_annual_bill_2022,
    annual_bill_pct_change = annual_bill_change_usd / avg_annual_bill_2022 * 100,
    monthly_bill_change_usd = avg_monthly_bill_2024 - avg_monthly_bill_2022,
    monthly_bill_pct_change = monthly_bill_change_usd / avg_monthly_bill_2022 * 100
  )

# ── Write output ──────────────────────────────────────────────────────────────

output_path <- paste0(
  "outputs/",
  format(Sys.Date(), "%d-%m-%Y"),
  "-co-electric-rates-bills-by-ownership.csv"
)

write.csv(sales_wide, output_path, row.names = FALSE)
message("Written: ", output_path)
