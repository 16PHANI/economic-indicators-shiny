# ============================================================
# app.R — Global Economic Indicators: R Shiny Dashboard
# Data source : World Bank Open Data (wbstats package)
# Author      : Boyinapalli Phani Shankar
# ============================================================

# ---- 0. Load libraries ----------------------------------------
library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(wbstats)
library(tidyr)
library(DT)

# ---- 1. Source reusable helper functions ----------------------
source("R/data_helpers.R")
source("R/plot_helpers.R")

# ---- 2. Constants ---------------------------------------------
DEFAULT_COUNTRIES <- c("India", "United States", "China",
                        "Germany", "Brazil")
ALL_INDICATORS    <- c("GDP Growth (%)", "Inflation (%)", "Unemployment (%)")
MIN_YEAR          <- 2000
MAX_YEAR          <- 2023

# ---- 3. Data loading (runs once on startup) -------------------
# Wraps the API call in tryCatch so the app starts even if
# the World Bank API is temporarily unavailable.
wb_df <- tryCatch({
  message("[INFO] Downloading World Bank data …")
  fetch_wb_data(start_year = MIN_YEAR, end_year = MAX_YEAR)
}, error = function(e) {
  message("[WARN] API unavailable — no data loaded. Error: ", e$message)
  tibble::tibble(country = character(), iso3c = character(),
                 year = integer(), indicator = character(),
                 value = numeric())
})

all_countries <- get_countries(wb_df)

# ---- 4. UI ----------------------------------------------------
ui <- fluidPage(

  # ---- 4a. Page metadata & CSS --------------------------------
  tags$head(
    tags$title("Global Economic Indicators"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),

  # ---- 4b. Header bar -----------------------------------------
  div(class = "app-header",
    h3("🌍 Global Economic Indicators Dashboard",
       style = "margin:0; display:inline;"),
    tags$small(" · World Bank Open Data",
               style = "color:#aaa; font-size:0.75em; margin-left:8px;")
  ),

  # ---- 4c. Main layout ----------------------------------------
  sidebarLayout(

    # -- Sidebar ------------------------------------------------
    sidebarPanel(
      width = 3,

      h5("Controls", style = "font-weight:700; margin-bottom:12px;"),

      selectizeInput(
        inputId  = "countries",
        label    = "Countries (up to 10):",
        choices  = all_countries,
        selected = DEFAULT_COUNTRIES,
        multiple = TRUE,
        options  = list(
          maxItems    = 10,
          placeholder = "Type to search …"
        )
      ),

      sliderInput(
        inputId = "year_range",
        label   = "Year Range:",
        min     = MIN_YEAR,
        max     = MAX_YEAR,
        value   = c(2005, MAX_YEAR),
        step    = 1,
        sep     = "",
        ticks   = FALSE
      ),

      radioButtons(
        inputId  = "indicator",
        label    = "Indicator:",
        choices  = ALL_INDICATORS,
        selected = "GDP Growth (%)"
      ),

      hr(style = "margin: 16px 0;"),

      # Indicator descriptions
      uiOutput("indicator_desc"),

      hr(style = "margin: 16px 0;"),
      p(tags$b("Data source: "),
        tags$a("World Bank Open Data",
               href   = "https://data.worldbank.org",
               target = "_blank"),
        style = "font-size:0.8em; color:#888; margin:0;"),
      p("Retrieved via the ",
        tags$code("wbstats"), " R package.",
        style = "font-size:0.78em; color:#aaa; margin-top:4px;")
    ),

    # -- Main panel --------------------------------------------
    mainPanel(
      width = 9,

      tabsetPanel(
        id = "main_tabs",

        # ── Tab 1: Time-series chart ─────────────────────────
        tabPanel(
          title = "📈 Trend Chart",
          br(),
          uiOutput("data_status"),
          plotlyOutput("line_chart", height = "380px"),
          br(),
          div(style = "font-size:0.85em; color:#555;",
            p(icon("info-circle"),
              " Hover over lines for exact values.
               Click country names in legend to toggle.
               Double-click legend entry to isolate one country."))
        ),

        # ── Tab 2: Bar chart (latest snapshot) ──────────────
        tabPanel(
          title = "📊 Latest Snapshot",
          br(),
          plotlyOutput("bar_chart", height = "380px"),
          br(),
          div(style = "font-size:0.85em; color:#555;",
            p(icon("info-circle"),
              " Shows the most recent year's value per country.
               Colour scale: red = low, green = high."))
        ),

        # ── Tab 3: Data table ────────────────────────────────
        tabPanel(
          title = "📋 Summary Table",
          br(),
          h5("Summary Statistics by Country"),
          DT::dataTableOutput("summary_dt"),
          br(),
          downloadButton("download_data",
                         "Download filtered data (.csv)",
                         class = "btn-sm btn-default")
        ),

        # ── Tab 4: Analytical report ─────────────────────────
        tabPanel(
          title = "📄 Report",
          br(),
          div(class = "report-box",
            uiOutput("report_content")
          )
        )
      ) # end tabsetPanel
    ) # end mainPanel
  ) # end sidebarLayout
) # end fluidPage


# ---- 5. Server ------------------------------------------------
server <- function(input, output, session) {

  # ---- 5a. Reactive: filtered data ----------------------------
  filtered <- reactive({
    req(input$countries, input$year_range, input$indicator)
    validate(
      need(length(input$countries) > 0,
           "Please select at least one country.")
    )
    filter_data(
      df         = wb_df,
      countries  = input$countries,
      year_range = input$year_range,
      indicator  = input$indicator
    )
  })

  # ---- 5b. Data status banner ---------------------------------
  output$data_status <- renderUI({
    df <- filtered()
    n  <- nrow(df)
    if (n == 0) {
      div(class = "alert alert-warning",
          "⚠️ No data found for the selected filters.
           Try broadening the year range or adding more countries.")
    } else {
      div(style = "font-size:0.82em; color:#666; margin-bottom:4px;",
          sprintf("Showing %s observations for %s countries · %s–%s",
                  format(n, big.mark = ","),
                  length(input$countries),
                  input$year_range[1],
                  input$year_range[2]))
    }
  })

  # ---- 5c. Line chart -----------------------------------------
  output$line_chart <- renderPlotly({
    df <- filtered()
    validate(need(nrow(df) > 0, "No data for the selected filters."))
    make_line_chart(df, input$indicator)
  })

  # ---- 5d. Bar chart (latest year snapshot) -------------------
  output$bar_chart <- renderPlotly({
    df <- filtered()
    validate(need(nrow(df) > 0, "No data for the selected filters."))
    make_bar_chart(df, input$indicator)
  })

  # ---- 5e. Summary DT table -----------------------------------
  output$summary_dt <- DT::renderDataTable({
    df <- filtered()
    validate(need(nrow(df) > 0, "No data to summarise."))
    tbl <- compute_summary(df)
    DT::datatable(
      tbl,
      rownames  = FALSE,
      options   = list(pageLength = 15, dom = "tp",
                       columnDefs = list(
                         list(className = "dt-center",
                              targets   = 1:4)
                       )),
      caption   = htmltools::tags$caption(
        style = "caption-side: top; font-size:0.9em; color:#555;",
        paste("Indicator:", input$indicator,
              "| Period:", input$year_range[1], "–", input$year_range[2])
      )
    ) %>%
      DT::formatRound(columns = c("Mean", "Min", "Max", "Latest"),
                      digits  = 2)
  })

  # ---- 5f. CSV download ---------------------------------------
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("economic_data_",
             gsub(" ", "_", tolower(input$indicator)), "_",
             input$year_range[1], "_", input$year_range[2],
             ".csv")
    },
    content = function(file) {
      utils::write.csv(filtered(), file, row.names = FALSE)
    }
  )

  # ---- 5g. Indicator description sidebar ----------------------
  output$indicator_desc <- renderUI({
    desc <- switch(input$indicator,
      "GDP Growth (%)"    = "Annual % change in inflation-adjusted GDP.
                             Positive = economic expansion.",
      "Inflation (%)"     = "Annual % change in consumer price index.
                             High values indicate rapid price increases.",
      "Unemployment (%)"  = "Unemployed persons as % of total labour force
                             (ILO modelled estimates)."
    )
    div(style = "font-size:0.82em; color:#666; line-height:1.45;",
        p(tags$b("What this measures:"), br(), desc))
  })

  # ---- 5h. Report tab content ---------------------------------
  output$report_content <- renderUI({
    df  <- filtered()
    tbl <- if (nrow(df) > 0) compute_summary(df) else NULL

    tagList(
      h4(paste("Economic Indicators Report —", input$indicator)),
      tags$hr(),
      tags$table(class = "report-meta",
        tags$tr(
          tags$td(tags$b("Indicator:")),
          tags$td(input$indicator)),
        tags$tr(
          tags$td(tags$b("Countries:")),
          tags$td(paste(input$countries, collapse = ", "))),
        tags$tr(
          tags$td(tags$b("Period:")),
          tags$td(paste(input$year_range[1], "–", input$year_range[2]))),
        tags$tr(
          tags$td(tags$b("Observations:")),
          tags$td(format(nrow(df), big.mark = ",")))
      ),
      tags$hr(),
      h5("Summary Statistics"),
      if (!is.null(tbl)) {
        renderTable(tbl, striped = TRUE, hover = TRUE,
                    bordered = TRUE, digits = 2)
      } else {
        p("No data for the selected filters.")
      },
      tags$hr(),
      p(tags$b("Data source:"),
        tags$a("World Bank Open Data",
               href = "https://data.worldbank.org", target = "_blank"),
        "· Retrieved via wbstats R package · ",
        tags$em(paste("Report generated:", Sys.Date())),
        style = "font-size:0.82em; color:#888;")
    )
  })

} # end server


# ---- 6. Launch app --------------------------------------------
shinyApp(ui = ui, server = server)
