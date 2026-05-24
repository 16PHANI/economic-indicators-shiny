# 🌍 Global Economic Indicators Dashboard

[![Live App](https://img.shields.io/badge/Live%20App-shinyapps.io-blue?style=flat-square&logo=r)](https://economic-indicators-shiny.shinyapps.io/economic-indicators-shiny/)
[![GitHub](https://img.shields.io/badge/GitHub-16PHANI-black?style=flat-square&logo=github)](https://github.com/16PHANI/economic-indicators-shiny)
[![R](https://img.shields.io/badge/R-4.6.0-276DC3?style=flat-square&logo=r)](https://www.r-project.org/)

An interactive R Shiny dashboard visualising key economic indicators
(GDP growth, inflation, unemployment) across 50+ countries using
[World Bank Open Data](https://data.worldbank.org).

**🔗 Live:** https://economic-indicators-shiny.shinyapps.io/economic-indicators-shiny/  
**📁 Repo:** https://github.com/16PHANI/economic-indicators-shiny

---

## Features

- **Interactive Plotly charts** — hover, zoom, pan, toggle countries
- **Reactive filters** — country multi-select, year range slider, indicator picker
- **Latest snapshot bar chart** — colour-coded by value
- **Downloadable CSV** — export filtered data
- **R Markdown report** — reproducible analytical summary (`report.Rmd`)

---

## Tech Stack

| Layer | Tools |
|---|---|
| Data | `wbstats`, `dplyr`, `tidyr` |
| Visualisation | `ggplot2`, `plotly` |
| App framework | `shiny` |
| Tables | `DT` |
| Documentation | roxygen2-style inline comments |
| Report | R Markdown (`report.Rmd`) |
| Deployment | shinyapps.io via `rsconnect` |

---

## Indicators

| Indicator | World Bank Code | Description |
|---|---|---|
| GDP Growth (%) | NY.GDP.MKTP.KD.ZG | Annual % change in constant-price GDP |
| Inflation (%) | FP.CPI.TOTL.ZG | Annual % change in consumer price index |
| Unemployment (%) | SL.UEM.TOTL.ZS | Unemployed as % of total labour force |

---

## Project Structure

```
economic-indicators-shiny/
├── app.R                  # Main Shiny application
├── R/
│   ├── data_helpers.R     # Data fetching & transformation (roxygen2 documented)
│   └── plot_helpers.R     # ggplot2 + Plotly chart functions (roxygen2 documented)
├── report.Rmd             # Standalone R Markdown analytical report
├── www/
│   └── styles.css         # Custom dashboard styling
├── README.md
├── DESCRIPTION
└── .gitignore
```

---

## Local Setup

```r
# 1. Install packages
install.packages(c("shiny", "dplyr", "ggplot2", "plotly",
                   "wbstats", "tidyr", "DT", "rsconnect",
                   "rmarkdown", "knitr", "kableExtra"))

# 2. Run app
shiny::runApp(".")
```

---

## Generate R Markdown Report

```r
rmarkdown::render(
  "report.Rmd",
  params = list(
    countries  = c("India", "United States", "China"),
    start_year = 2010,
    end_year   = 2023,
    indicator  = "GDP Growth (%)"
  )
)
```

---

## Deploy to shinyapps.io

```r
rsconnect::setAccountInfo(
  name   = "YOUR_ACCOUNT_NAME",
  token  = "YOUR_TOKEN",
  secret = "YOUR_SECRET"
)
rsconnect::deployApp(".")
```

---

## Data Source

World Bank Open Data · [data.worldbank.org](https://data.worldbank.org)  
Retrieved via the [`wbstats`](https://cran.r-project.org/package=wbstats) R package.

---

*Author: Boyinapalli Phani Shankar*  
*Published: May 2025 · [Live Dashboard](https://economic-indicators-shiny.shinyapps.io/economic-indicators-shiny/)*