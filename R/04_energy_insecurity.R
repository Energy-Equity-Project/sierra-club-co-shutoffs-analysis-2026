library(tidyverse)
library(janitor)

# ── Data — read only needed columns from large (~195 MB) file ─────────────────

needed_cols <- c(
  "state", "survey_year", "survey_wave", "energy", "hse_temp", "enrgy_bill", "person_weight"
)

pulse_raw <- read.csv(
  "../../Cleaned_Data/us_census/household_pulse_survey/02-04-2026-pulse-energy-puf-harmonized.csv",
  colClasses = c(
    state         = "character",
    survey_year   = "integer",
    survey_wave   = "character",
    energy        = "character",
    hse_temp      = "character",
    enrgy_bill    = "character",
    person_weight = "numeric"
  )
) %>%
  clean_names() %>%
  select(all_of(tolower(needed_cols)))

# ── Filter to Colorado 2024 ───────────────────────────────────────────────────

hardship_values <- c("almost_every_month", "some_months", "1_or_2_months")

pulse_co <- pulse_raw %>%
  filter(state == "CO", survey_year == 2024)

cycles <- sort(unique(pulse_co$survey_wave))
message("Cycles found in CO 2024 data: ", paste(cycles, collapse = ", "))

# ── Per-cycle weighted shares ─────────────────────────────────────────────────

compute_cycle_shares <- function(df_cycle, cycle_id) {
  # Returns NULL if the cycle has no energy questions (all NA)
  energy_vars <- c("energy", "hse_temp", "enrgy_bill")
  all_na <- all(sapply(energy_vars, function(v) all(is.na(df_cycle[[v]]))))
  if (all_na) {
    message("Skipping cycle ", cycle_id, ": all energy question columns are NA.")
    return(NULL)
  }

  safe_share <- function(flag_col) {
    valid <- !is.na(flag_col)
    if (sum(valid) == 0) return(NA_real_)
    sum(df_cycle$person_weight[valid & flag_col %in% hardship_values]) /
      sum(df_cycle$person_weight[valid])
  }

  forgo_share  <- safe_share(df_cycle$energy)
  unsafe_share <- safe_share(df_cycle$hse_temp)
  unpaid_share <- safe_share(df_cycle$enrgy_bill)

  # Composite: any of the three is a hardship; denominator = ≥1 non-NA among three
  composite_valid <- !is.na(df_cycle$energy) | !is.na(df_cycle$hse_temp) | !is.na(df_cycle$enrgy_bill)
  composite_flag <- (df_cycle$energy %in% hardship_values & !is.na(df_cycle$energy)) |
                    (df_cycle$hse_temp %in% hardship_values & !is.na(df_cycle$hse_temp)) |
                    (df_cycle$enrgy_bill %in% hardship_values & !is.na(df_cycle$enrgy_bill))
  composite_share <- if (sum(composite_valid) == 0) NA_real_ else
    sum(df_cycle$person_weight[composite_valid & composite_flag]) /
    sum(df_cycle$person_weight[composite_valid])

  tibble(
    survey_wave       = cycle_id,
    forgo_necessities = forgo_share,
    unsafe_temperature = unsafe_share,
    unable_to_pay     = unpaid_share,
    energy_insecure   = composite_share
  )
}

cycle_shares <- pulse_co %>%
  split(.$survey_wave) %>%
  imap(compute_cycle_shares) %>%
  compact() %>%
  bind_rows()

contributing_cycles <- cycle_shares$survey_wave
message(
  "Cycles contributing to averages: ",
  paste(contributing_cycles, collapse = ", ")
)

# ── Average across cycles (equal weighting) ───────────────────────────────────

n_cycles <- nrow(cycle_shares)

avg_shares <- cycle_shares %>%
  summarise(
    forgo_necessities  = mean(forgo_necessities,  na.rm = TRUE),
    unsafe_temperature = mean(unsafe_temperature, na.rm = TRUE),
    unable_to_pay      = mean(unable_to_pay,      na.rm = TRUE),
    energy_insecure    = mean(energy_insecure,    na.rm = TRUE)
  ) %>%
  mutate(n_cycles_used = n_cycles)

# ── Reshape to one row per metric ─────────────────────────────────────────────

insecurity_output <- avg_shares %>%
  pivot_longer(
    cols      = c(forgo_necessities, unsafe_temperature, unable_to_pay, energy_insecure),
    names_to  = "metric",
    values_to = "share"
  ) %>%
  mutate(n_cycles_used = avg_shares$n_cycles_used)

# ── Write output ──────────────────────────────────────────────────────────────

output_path <- paste0(
  "outputs/",
  format(Sys.Date(), "%d-%m-%Y"),
  "-co-energy-insecurity.csv"
)

write.csv(insecurity_output, output_path, row.names = FALSE)
message("Written: ", output_path)
