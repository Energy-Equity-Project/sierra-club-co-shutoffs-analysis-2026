# Results: Colorado Residential Energy Costs, Affordability & Insecurity

This document summarizes findings from six analysis scripts covering Colorado residential
energy for reference years 2022 and 2024. All figures are drawn from the CSVs in `outputs/`
(dated 16-06-2026). For data sources, computation methods, and caveats, see `METHODOLOGY.md`.

---

## Energy Affordability

### Average energy burden by income band

Energy burden is the share of household income spent on home energy. The table below uses
DOE LEAD 2022 data for Colorado census tracts, grouped by federal poverty level (FPL).

| FPL band | Avg household income | Avg energy burden |
|----------|----------------------|-------------------|
| 0–100%   | $9,688               | 19.1%             |
| 100–150% | $25,253              | 8.0%              |
| 150–200% | $37,169              | 5.4%              |
| 200–400% | $64,410              | 3.3%              |
| 400%+    | $175,204             | 1.3%              |

Households at or below the poverty line spend roughly 19% of income on energy — about
15 times the share paid by households above 400% FPL.

### Share of households with unaffordable burden (>6% of income)

The 6% threshold is a common policy benchmark for unaffordable energy costs.

| FPL band | Share with burden >6% |
|----------|-----------------------|
| 0–100%   | 80.1%                 |
| 100–150% | 53.4%                 |
| 150–200% | 29.9%                 |
| 200–400% | 6.6%                  |
| 400%+    | 0.3%                  |

**Statewide:** 12.0% of Colorado households — approximately 265,540 of ~2.22 million —
spend more than 6% of income on energy.

---

## Energy Insecurity

The four metrics below are drawn from nine 2024 cycles of the U.S. Census Household Pulse
Survey for Colorado. "Energy insecure" is a composite: the respondent reported any of the
three hardship behaviors more often than "never."

| Metric | Share of CO households |
|--------|------------------------|
| Energy insecure (any hardship) | **38.9%** |
| Forgoes necessities to pay energy bill | 28.9% |
| Kept home at unsafe temperature | 21.2% |
| Unable to pay energy bill | 18.4% |

Nearly four in ten Colorado households reported at least one form of energy hardship in 2024.

---

## Energy Price & Bill Changes, 2022–2024

### Residential electric rates and bills by utility ownership type

Source: EIA Form 861 (residential sector only).

| Ownership type | Rate 2022 (¢/kWh) | Rate 2024 (¢/kWh) | Rate change | Annual bill 2022 | Annual bill 2024 | Bill change |
|----------------|-------------------|--------------------|-------------|------------------|------------------|-------------|
| Coop           | 14.01             | 14.96              | +6.8%       | $1,455           | $1,511           | +3.9%       |
| IOU            | 14.45             | 15.16              | +5.0%       | $1,069           | $1,088           | +1.9%       |
| Muni           | 13.54             | 13.77              | +1.7%       | $1,059           | $1,053           | −0.5%       |

All three ownership types saw rate increases over the period; cooperatives had the largest
rate increase (+6.8%). Municipal utility annual bills fell slightly despite the rate increase,
reflecting lower consumption.

### Residential natural gas prices and bills (statewide)

Source: EIA Form 176.

| Metric | 2022 | 2024 | Change |
|--------|------|------|--------|
| Price ($/Mcf) | $12.72 | $10.58 | −16.8% |
| Average annual bill | $957 | $703 | −26.5% |
| Average monthly bill | $79.78 | $58.61 | −26.5% |
| Residential customer count | 1,891,533 | 1,937,980 | +2.5% |

Gas prices fell substantially between 2022 and 2024, driving a 26.5% reduction in the
average annual residential gas bill.

---

## Median Household Income Change, 2022–2024

Source: ACS 5-year estimates, tract-level median household income (B19013), weighted by
tract household counts (B11001).

| Year | Household-weighted median income |
|------|----------------------------------|
| 2022 | $94,234 |
| 2024 | $102,557 |
| Change | +$8,324 (+8.8%) |

*Note: this figure is a household-weighted average of tract-level ACS medians, not a true
statewide median. It serves as an approximation of income growth and should be interpreted
accordingly.*

---

## Shutoffs (disconnections due to non-payment)

Source: EIA Form 112, 2024 (first year of publication). Figures represent annual totals
(sum of 12 monthly reports). The annualized combined rate uses electric customers as the
denominator, reflecting the larger residential customer universe.

### Statewide totals

In 2024, Colorado utilities initiated approximately 138,966 residential disconnections for
non-payment — 133,699 electric and 5,267 gas.

| Metric | Value |
|--------|-------|
| Total electric shutoffs | 133,699 |
| Total gas shutoffs | 5,267 |
| Total combined shutoffs | 138,966 |
| Annualized electric shutoff rate | 5.2% |
| Annualized gas shutoff rate | 0.27% |
| Annualized combined shutoff rate | 5.4% |

### By utility ownership type

The table below reports each ownership type's share of Colorado shutoffs and its
customer-weighted shutoff rate, derived from EIA Form 112 utility-level data. Cooperative
utilities in Colorado serve electricity only; the gas columns for Coop are not applicable.

| Ownership | Electric shutoffs | Gas shutoffs | Combined shutoffs | % of combined | Electric rate | Gas rate | Combined rate |
|-----------|------------------:|-------------:|------------------:|--------------:|--------------:|---------:|--------------:|
| Coop      | 45,945            | 0            | 45,945            | 34.4%         | 7.0%          | N/A      | 7.0%          |
| IOU       | 43,621            | 4,457        | 48,078            | 36.0%         | 3.0%          | 0.26%    | 3.3%          |
| Muni      | 38,582            | 926          | 39,508            | 29.6%         | 9.2%          | 0.42%    | 9.4%          |

Municipal utilities had the highest shutoff rates — 9.2% of electric customers and 9.4%
combined — despite serving a smaller share of total customers. IOU customers were shut off
at the lowest rate (3.3% combined). Cooperatives, which serve rural and agricultural
communities, accounted for 34.4% of combined shutoffs at a 7.0% electric rate.

*Note: ownership-level figures are computed within the utility-annual dataset (after
excluding one bad-data row) and may not reconcile exactly with the statewide state-level
totals above, which come from a different source workbook.*

---

## Summary

Energy affordability burdens fall steeply by income: the lowest-income Colorado households
spend roughly 19 cents of every dollar on energy, while the highest-income households spend
about 1 cent. Even as gas bills fell and median incomes rose between 2022 and 2024, electric
rates increased across all ownership types, and nearly 4 in 10 Coloradans reported energy
hardship in 2024. Statewide, 12% of households — roughly 265,000 — face energy costs
exceeding the 6% affordability threshold. In 2024, Colorado utilities disconnected roughly
139,000 residential customers for non-payment — an annualized combined rate of 5.4% — with
municipal utility customers facing the highest shutoff rates and cooperative customers
accounting for the largest share of total shutoffs.
