# Utility profits sourced from the Energy & Policy Institute (EPI) profit tracker.
# The dataset covers ~110 utilities nationally; filtering to "CO" matches only one:
# "Xcel (electric subsidiaries)". Xcel's figures are an 8-state aggregate
# (CO, MI, MN, NM, ND, SD, TX, WI) — not Colorado-specific profit. EPI is an advocacy
# source; treat figures as directionally indicative, not regulatory-grade financials.
# No CSV is written; results are printed to console and reported in results.md.

library(tidyverse)
library(janitor)
library(readxl)

profits_raw <- read_excel(
  "../../Data/epi/2021 - 2025 Utility Profits (Make a copy to edit) _ Last Updated 5_8_26.xlsx",
  sheet = "Data"
) %>%
  clean_names()

# Filter to utilities serving Colorado (word-boundary match to avoid substring hits)
co_profits <- profits_raw %>%
  filter(str_detect(service_state_s, "\\bCO\\b"))

# Profit columns import as character because some rows contain "N/A"
co_summary <- co_profits %>%
  transmute(
    utility,
    service_states       = service_state_s,
    profit_2021_musd     = as.numeric(x2021_profit_millions),
    profit_2025_musd     = as.numeric(x2025_profit_millions),
    profit_change_musd   = profit_2025_musd - profit_2021_musd,
    profit_pct_growth    = profit_change_musd / profit_2021_musd * 100,
    bill_share_2021_pct  = as.numeric(x2021_profit_portion_of_bill_percent) * 100,
    bill_share_2025_pct  = as.numeric(x2025_profit_portion_of_bill_percent) * 100
  )

message("Colorado utilities matched: ", nrow(co_summary))
print(co_summary)
