# 🌍 Global Economic Indicators Dashboard

An interactive R Shiny dashboard visualising key economic indicators
(GDP growth, inflation, unemployment) across 50+ countries using
[World Bank Open Data](https://data.worldbank.org).

## Features

- **Interactive Plotly charts** — hover, zoom, pan, toggle countries
- **Reactive filters** — country multi-select, year range slider, indicator picker
- **Latest snapshot bar chart** — colour-coded by value
- **Downloadable CSV** — export filtered data
- **R Markdown report** — reproducible analytical summary (`report.Rmd`)

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

## Indicators

| Indicator | World Bank Code | Description |
|---|---|---|
| GDP Growth (%) | NY.GDP.MKTP.KD.ZG | Annual % change in constant-price GDP |
| Inflation (%) | FP.CPI.TOTL.ZG | Annual % change in consumer price index |
| Unemployment (%) | SL.UEM.TOTL.ZS | Unemployed as % of total labour force |

## Local Setup

```r
# 1. Install packages
install.packages(c("shiny", "dplyr", "ggplot2", "plotly",
                   "wbstats", "tidyr", "DT", "rsconnect",
                   "rmarkdown", "knitr", "kableExtra"))

# 2. Run app
shiny::runApp(".")
```

## Deploy to shinyapps.io

```r
rsconnect::setAccountInfo(
  name   = "YOUR_ACCOUNT_NAME",
  token  = "YOUR_TOKEN",
  secret = "YOUR_SECRET"
)
rsconnect::deployApp(".")
```

## Data Source

World Bank Open Data · [data.worldbank.org](https://data.worldbank.org)  
Retrieved via the [`wbstats`](https://cran.r-project.org/package=wbstats) R package.

---

*Author: Boyinapalli Phani Shankar*
