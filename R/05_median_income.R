library(tidyverse)
library(janitor)

# ── Helper: read one year's B19013 (median income) + B11001 (households) ──────

read_year <- function(yr) {
  income_path <- paste0(
    "../../Data/us_census/acs/", yr, "/tract/B19013_co.csv"
  )
  hholds_path <- paste0(
    "../../Data/us_census/acs/", yr, "/tract/B11001_co.csv"
  )

  income <- read.csv(income_path) %>%
    clean_names() %>%
    select(geoid, median_income = estimate)

  hholds <- read.csv(hholds_path) %>%
    clean_names() %>%
    select(geoid, households = estimate)

  joined <- income %>%
    inner_join(hholds, by = "geoid")

  # Drop tracts with suppressed (NA) median income
  n_before     <- nrow(joined)
  units_before <- sum(joined$households, na.rm = TRUE)

  joined_valid <- joined %>%
    filter(!is.na(median_income))

  n_dropped     <- n_before - nrow(joined_valid)
  units_dropped <- units_before - sum(joined_valid$households, na.rm = TRUE)
  message(
    yr, ": dropped ", n_dropped, " tracts (", round(units_dropped),
    " households) with NA median income."
  )

  joined_valid %>%
    mutate(year = yr)
}

# ── Load both years ───────────────────────────────────────────────────────────

acs_data <- bind_rows(read_year(2022), read_year(2024))

# ── Household-weighted average median income per year ─────────────────────────

income_by_year <- acs_data %>%
  group_by(year) %>%
  summarise(
    weighted_median_income = sum(median_income * households) / sum(households),
    n_tracts               = n(),
    total_households       = sum(households)
  ) %>%
  ungroup()

# ── Add 2022→2024 change row ──────────────────────────────────────────────────

inc_2022 <- income_by_year$weighted_median_income[income_by_year$year == 2022]
inc_2024 <- income_by_year$weighted_median_income[income_by_year$year == 2024]

change_row <- tibble(
  year                   = NA_integer_,
  weighted_median_income = inc_2024 - inc_2022,
  n_tracts               = NA_integer_,
  total_households       = NA_integer_,
  change_type            = "absolute_2022_to_2024"
)

pct_change_row <- tibble(
  year                   = NA_integer_,
  weighted_median_income = (inc_2024 - inc_2022) / inc_2022 * 100,
  n_tracts               = NA_integer_,
  total_households       = NA_integer_,
  change_type            = "pct_change_2022_to_2024"
)

income_output <- income_by_year %>%
  mutate(change_type = "observed") %>%
  bind_rows(change_row, pct_change_row)

# ── Write output ──────────────────────────────────────────────────────────────

output_path <- paste0(
  "outputs/",
  format(Sys.Date(), "%d-%m-%Y"),
  "-co-median-income-weighted.csv"
)

write.csv(income_output, output_path, row.names = FALSE)
message("Written: ", output_path)
message(
  "Note: weighted_median_income is a household-weighted average of tract-level ",
  "ACS 5-year medians, not a true statewide median."
)
