# ============================================================
# data_helpers.R
# Reusable R functions for World Bank data fetching,
# cleaning, transformation, and aggregation.
# Documented with roxygen2-style comments.
# ============================================================

#' Fetch World Bank economic indicators in tidy long format
#'
#' Downloads GDP growth, inflation, and unemployment data for
#' all country-level entities using the wbstats API. Returns
#' a tidy long-format tibble ready for dplyr filtering and
#' ggplot2/Plotly visualisation.
#'
#' @param start_year Integer. First year of data range. Default 2000.
#' @param end_year   Integer. Last year of data range.  Default 2023.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{country}{Full country name (character).}
#'     \item{iso3c}{ISO 3166-1 alpha-3 code (character).}
#'     \item{year}{Numeric year (integer).}
#'     \item{indicator}{Human-readable indicator label (character).}
#'     \item{value}{Indicator value (numeric).}
#'   }
#'
#' @examples
#' \dontrun{
#'   df <- fetch_wb_data(start_year = 2010, end_year = 2023)
#'   head(df)
#' }
fetch_wb_data <- function(start_year = 2000, end_year = 2023) {

  indicator_codes <- c(
    "NY.GDP.MKTP.KD.ZG",   # GDP growth (annual %)
    "FP.CPI.TOTL.ZG",      # Inflation, CPI (annual %)
    "SL.UEM.TOTL.ZS"       # Unemployment, total (% labour force)
  )

  raw <- wbstats::wb_data(
    indicator  = indicator_codes,
    country    = "countries_only",
    start_date = start_year,
    end_date   = end_year
  )

  # Rename World Bank codes to human-readable names
  raw <- raw %>%
    dplyr::rename(
      year         = date,
      gdp_growth   = NY.GDP.MKTP.KD.ZG,
      inflation    = FP.CPI.TOTL.ZG,
      unemployment = SL.UEM.TOTL.ZS
    ) %>%
    dplyr::select(country, iso3c, year,
                  gdp_growth, inflation, unemployment)

  # Pivot from wide to tidy long format
  long_df <- raw %>%
    tidyr::pivot_longer(
      cols      = c(gdp_growth, inflation, unemployment),
      names_to  = "indicator_code",
      values_to = "value"
    ) %>%
    dplyr::mutate(
      indicator = dplyr::case_when(
        indicator_code == "gdp_growth"   ~ "GDP Growth (%)",
        indicator_code == "inflation"    ~ "Inflation (%)",
        indicator_code == "unemployment" ~ "Unemployment (%)",
        TRUE                             ~ indicator_code
      )
    ) %>%
    dplyr::filter(!is.na(value)) %>%
    dplyr::select(country, iso3c, year, indicator, value) %>%
    dplyr::arrange(country, indicator, year)

  long_df
}


#' Get sorted vector of unique country names from a dataset
#'
#' @param df Tibble produced by \code{fetch_wb_data()}.
#'
#' @return Character vector of country names, sorted alphabetically.
#'
#' @examples
#' \dontrun{
#'   countries <- get_countries(df)
#' }
get_countries <- function(df) {
  sort(unique(df$country))
}


#' Filter dataset by countries, year range, and indicator
#'
#' Applies dplyr filters to subset the tidy long-format tibble
#' returned by \code{fetch_wb_data()} for use in reactive Shiny
#' contexts or standalone analysis.
#'
#' @param df         Tibble from \code{fetch_wb_data()}.
#' @param countries  Character vector of country names to include.
#' @param year_range Integer vector of length 2: \code{c(start, end)}.
#' @param indicator  Character. One of \code{"GDP Growth (%)"},
#'                   \code{"Inflation (%)"}, or \code{"Unemployment (%)"}.
#'
#' @return Filtered tibble with the same columns as the input.
#'
#' @examples
#' \dontrun{
#'   sub <- filter_data(df,
#'     countries  = c("India", "China"),
#'     year_range = c(2010, 2023),
#'     indicator  = "GDP Growth (%)")
#' }
filter_data <- function(df, countries, year_range, indicator) {
  ind <- indicator  # local copy avoids NSE column-name collision
  df %>%
    dplyr::filter(
      country   %in% countries,
      dplyr::between(year, year_range[1], year_range[2]),
      indicator == ind
    )
}


#' Compute summary statistics per country for a filtered dataset
#'
#' Calculates mean, minimum, maximum, and most-recent value for
#' each country. Suitable for display as a formatted table.
#'
#' @param df Filtered tibble from \code{filter_data()}.
#'
#' @return A tibble with columns:
#'   Country, Mean, Min, Max, Latest (all rounded to 2 d.p.).
#'
#' @examples
#' \dontrun{
#'   stats <- compute_summary(filtered_df)
#' }
compute_summary <- function(df) {
  df %>%
    dplyr::group_by(Country = country) %>%
    dplyr::summarise(
      Mean   = round(mean(value,  na.rm = TRUE), 2),
      Min    = round(min(value,   na.rm = TRUE), 2),
      Max    = round(max(value,   na.rm = TRUE), 2),
      Latest = round(dplyr::last(value, order_by = year), 2),
      .groups = "drop"
    ) %>%
    dplyr::arrange(Country)
}
