# ============================================================
# plot_helpers.R
# Reusable R functions for creating ggplot2 + Plotly
# interactive visualisations.
# Documented with roxygen2-style comments.
# ============================================================

#' Create an interactive Plotly multi-country line chart
#'
#' Wraps a ggplot2 line chart inside \code{plotly::ggplotly()} to
#' produce an interactive visualisation with hover tooltips, zoom,
#' and pan controls. Designed for tidy long-format economic data.
#'
#' @param df             Filtered tibble with columns:
#'                       country, year, value.
#' @param indicator_name Character. Chart title and tooltip label.
#' @param y_label        Character. Y-axis label. Default: "Value".
#'
#' @return A \code{plotly} htmlwidget.
#'
#' @examples
#' \dontrun{
#'   p <- make_line_chart(filtered_df, "GDP Growth (%)", "Annual %")
#'   p
#' }
make_line_chart <- function(df, indicator_name, y_label = "Value") {

  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(
      x      = year,
      y      = value,
      colour = country,
      group  = country,
      text   = paste0(
        "<b>", country, "</b><br>",
        "Year: ", year, "<br>",
        indicator_name, ": ", round(value, 2), "%"
      )
    )
  ) +
    ggplot2::geom_line(linewidth = 0.9, alpha = 0.85) +
    ggplot2::geom_point(size = 1.8, alpha = 0.9) +
    ggplot2::labs(
      title  = indicator_name,
      x      = "Year",
      y      = y_label,
      colour = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title      = ggplot2::element_text(face = "bold", size = 14,
                                               margin = ggplot2::margin(b = 8)),
      legend.position = "bottom",
      legend.text     = ggplot2::element_text(size = 10),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text        = ggplot2::element_text(size = 10)
    )

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::layout(
      legend = list(
        orientation = "h",
        x           = 0,
        y           = -0.25,
        font        = list(size = 11)
      ),
      margin = list(t = 50, b = 60)
    ) %>%
    plotly::config(displayModeBar = TRUE,
                   modeBarButtonsToRemove = c("lasso2d", "select2d"))
}


#' Create a colour-coded bar chart of latest-year values
#'
#' Shows the most recent available value for each selected country
#' as a horizontal bar chart, sorted descending. Useful for
#' communicating economic insights at a glance.
#'
#' @param df             Filtered tibble with columns: country, year, value.
#' @param indicator_name Character. Chart title.
#'
#' @return A \code{plotly} htmlwidget.
#'
#' @examples
#' \dontrun{
#'   p <- make_bar_chart(filtered_df, "Inflation (%)")
#'   p
#' }
make_bar_chart <- function(df, indicator_name) {

  latest <- df %>%
    dplyr::group_by(country) %>%
    dplyr::filter(year == max(year)) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(dplyr::desc(value)) %>%
    dplyr::mutate(country = factor(country, levels = rev(country)))

  p <- ggplot2::ggplot(
    latest,
    ggplot2::aes(
      x    = value,
      y    = country,
      fill = value,
      text = paste0("<b>", country, "</b><br>",
                    indicator_name, ": ", round(value, 2), "%<br>",
                    "Year: ", year)
    )
  ) +
    ggplot2::geom_col(width = 0.65, show.legend = FALSE) +
    ggplot2::scale_fill_gradient2(
      low  = "#d73027",
      mid  = "#fee08b",
      high = "#1a9850",
      midpoint = 0
    ) +
    ggplot2::labs(
      title = paste("Latest:", indicator_name),
      x     = indicator_name,
      y     = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold", size = 14),
      panel.grid.major.y = ggplot2::element_blank()
    )

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::config(displayModeBar = FALSE)
}
