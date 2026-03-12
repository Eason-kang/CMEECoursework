rm(list = ls())
install.packages("patchwork")
library(dplyr)
library(minpack.lm)
library(stringr)
library(patchwork)
library(ggplot2)

data_file    <- "../data/modified_growth_data.csv"
results_file <- "../results/model_results.csv"
best_file    <- "../results/best_model_summary.csv"

plot_dir     <- "../results/final_plots"
summary_dir  <- "../results/final_analysis"

if (!dir.exists(plot_dir)) dir.create(plot_dir, recursive = TRUE)
if (!dir.exists(summary_dir)) dir.create(summary_dir, recursive = TRUE)

# Read data
dat <- read.csv(data_file, stringsAsFactors = FALSE)
model_results <- read.csv(results_file, stringsAsFactors = FALSE)
best_summary  <- read.csv(best_file, stringsAsFactors = FALSE)

all_ids <- unique(dat$ID)

# Helper functions
# Same pseudo-R2 idea as mini_fit.R
calc_r2 <- function(model, df) {
  if (is.null(model) || inherits(model, "try-error")) return(NA_real_)
  rss <- sum(residuals(model)^2, na.rm = TRUE)
  tss <- sum((df$logPopBio - mean(df$logPopBio, na.rm = TRUE))^2, na.rm = TRUE)
  if (tss == 0) return(NA_real_)
  1 - rss / tss
}

# Estimate starting slope (same idea as mini_fit.R)
estimate_slope <- function(df) {
  df2 <- df %>% arrange(Time)
  slopes <- diff(df2$logPopBio) / diff(df2$Time)
  slopes <- slopes[is.finite(slopes)]
  if (length(slopes) == 0) return(0.1)
  max(slopes, na.rm = TRUE)
}

# Logistic model on log scale (same as mini_fit.R)
logistic_log_model <- function(t, r, K, N0) {
  log(N0 * K * exp(r * t) / (K + N0 * (exp(r * t) - 1)))
}

# Refit logistic with multi-start (same logic as mini_fit.R)
fit_logistic_model <- function(df, n_starts = 20) {
  if (nrow(df) < 6) return(NULL)
  
  y_raw <- df$PopBio
  slope_guess <- estimate_slope(df)
  
  if (!is.finite(slope_guess) || slope_guess <= 0) slope_guess <- 0.1
  
  N0_base <- max(min(y_raw, na.rm = TRUE), 1e-6)
  K_base  <- max(y_raw, na.rm = TRUE)
  
  fit_list <- list()
  
  for (i in seq_len(n_starts)) {
    start_vals <- list(
      r  = runif(1, max(0.001, slope_guess * 0.2), max(0.05, slope_guess * 2)),
      K  = runif(1, K_base * 0.8, K_base * 1.2),
      N0 = runif(1, N0_base * 0.8, max(N0_base * 1.2, N0_base + 1e-6))
    )
    
    fit_try <- tryCatch(
      nlsLM(
        logPopBio ~ logistic_log_model(Time, r, K, N0),
        data = df,
        start = start_vals,
        lower = c(r = 0, K = 1e-8, N0 = 1e-8),
        control = nls.lm.control(maxiter = 500)
      ),
      error = function(e) NULL
    )
    
    if (!is.null(fit_try)) {
      fit_list[[length(fit_list) + 1]] <- fit_try
    }
  }
  
  if (length(fit_list) == 0) return(NULL)
  
  # Since this is the final plotting script, choose by AIC
  aic_values <- sapply(fit_list, function(m) AIC(m))
  fit_list[[which.min(aic_values)]]
}

# Fit quadratic exactly like mini_fit.R
fit_quadratic_model <- function(df) {
  tryCatch(
    lm(logPopBio ~ Time + I(Time^2), data = df),
    error = function(e) NULL
  )
}

# Generate smooth prediction lines
get_predictions_for_plot <- function(df, id_value) {
  df <- df %>% arrange(Time)
  
  x_grid <- data.frame(
    Time = seq(min(df$Time, na.rm = TRUE),
               max(df$Time, na.rm = TRUE),
               length.out = 200)
  )
  
  out_list <- list()
  
  # Quadratic
  fit_quad <- fit_quadratic_model(df)
  if (!is.null(fit_quad)) {
    pred_quad <- predict(fit_quad, newdata = x_grid)
    out_list[[length(out_list) + 1]] <- data.frame(
      ID = id_value,
      Time = x_grid$Time,
      Fitted = pred_quad,
      Model = "Quadratic"
    )
  }
  
  # Logistic
  fit_log <- fit_logistic_model(df, n_starts = 20)
  if (!is.null(fit_log)) {
    pred_log <- predict(fit_log, newdata = x_grid)
    out_list[[length(out_list) + 1]] <- data.frame(
      ID = id_value,
      Time = x_grid$Time,
      Fitted = pred_log,
      Model = "Logistic"
    )
  }
  
  if (length(out_list) == 0) return(NULL)
  bind_rows(out_list)
}

# Safe file name
safe_filename <- function(x) {
  x <- gsub("[^A-Za-z0-9_\\-]", "_", x)
  x <- gsub("_+", "_", x)
  x
}

# 1) Plot every curve with models overlaid
plot_success <- 0

for (this_id in all_ids) {
  subdat <- dat %>%
    filter(ID == this_id) %>%
    arrange(Time)
  
  if (nrow(subdat) < 4 || length(unique(subdat$Time)) < 4) {
    cat("Skipping plot for", this_id, "- too few points.\n")
    next
  }
  
  pred_df <- get_predictions_for_plot(subdat, this_id)
  
  if (is.null(pred_df)) {
    cat("Skipping plot for", this_id, "- no model could be fitted.\n")
    next
  }
  
  best_aicc <- best_summary %>%
    filter(ID == this_id) %>%
    pull(Best_by_AICc)
  
  best_bic <- best_summary %>%
    filter(ID == this_id) %>%
    pull(Best_by_BIC)
  
  if (length(best_aicc) == 0) best_aicc <- NA
  if (length(best_bic) == 0) best_bic <- NA
  
  wrapped_id <- str_wrap(as.character(this_id), width = 35)
  
  p <- ggplot(subdat, aes(x = Time, y = logPopBio)) +
    geom_point(size = 2, colour = "black") +
    geom_line(
      data = pred_df,
      aes(x = Time, y = Fitted, colour = Model),
      linewidth = 1
    ) +
    theme_bw(base_size = 12) +
    labs(
      title = paste0(
        "ID: ", wrapped_id,
        "\nBest by AICc: ", best_aicc,
        " | Best by BIC: ", best_bic
      ),
      x = "Time",
      y = "log(PopBio)"
    ) +
    theme(
      plot.title = element_text(size = 11, hjust = 0.5),
      legend.position = "bottom"
    )
  
  out_file <- file.path(plot_dir, paste0(safe_filename(this_id), ".png"))
  ggsave(out_file, p, width = 7, height = 5, dpi = 300)
  
  plot_success <- plot_success + 1
  cat("Saved plot:", out_file, "\n")
}

# 2) Statistical summary

# Successful fits
success_counts <- model_results %>%
  group_by(model) %>%
  summarise(
    Success_Count = sum(converged, na.rm = TRUE),
    Total = n(),
    Success_Rate = Success_Count / Total,
    .groups = "drop"
  )

# AIC / AICc / BIC / R2 summary
summary_table <- model_results %>%
  group_by(model) %>%
  summarise(
    Mean_R2   = mean(R2, na.rm = TRUE),
    SD_R2     = sd(R2, na.rm = TRUE),
    Mean_AIC  = mean(AIC, na.rm = TRUE),
    SD_AIC    = sd(AIC, na.rm = TRUE),
    Mean_AICc = mean(AICc, na.rm = TRUE),
    SD_AICc   = sd(AICc, na.rm = TRUE),
    Mean_BIC  = mean(BIC, na.rm = TRUE),
    SD_BIC    = sd(BIC, na.rm = TRUE),
    .groups = "drop"
  )

# Best model counts
best_aicc_counts <- best_summary %>%
  count(Best_by_AICc, name = "Count_AICc")

best_bic_counts <- best_summary %>%
  count(Best_by_BIC, name = "Count_BIC")

best_model_counts <- full_join(
  best_aicc_counts,
  best_bic_counts,
  by = c("Best_by_AICc" = "Best_by_BIC")
) %>%
  rename(Model = Best_by_AICc)

best_model_counts[is.na(best_model_counts)] <- 0

# Save tables
write.csv(success_counts,
          file.path(summary_dir, "success_counts.csv"),
          row.names = FALSE)

write.csv(summary_table,
          file.path(summary_dir, "model_summary_statistics.csv"),
          row.names = FALSE)

write.csv(best_model_counts,
          file.path(summary_dir, "best_model_counts.csv"),
          row.names = FALSE)

# 3) Best-model bar plot
plot_best_df <- bind_rows(
  best_summary %>%
    count(Best_by_AICc) %>%
    mutate(Criterion = "AICc") %>%
    rename(Model = Best_by_AICc, Count = n),
  best_summary %>%
    count(Best_by_BIC) %>%
    mutate(Criterion = "BIC") %>%
    rename(Model = Best_by_BIC, Count = n)
)

p_best <- ggplot(plot_best_df, aes(x = Model, y = Count, fill = Criterion)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = Count),
            position = position_dodge(width = 0.9),
            vjust = -0.25) +
  theme_bw(base_size = 12) +
  labs(
    title = "Best model counts by AICc and BIC",
    x = "Model",
    y = "Number of IDs"
  )

ggsave(file.path(summary_dir, "best_model_counts_barplot.png"),
       p_best, width = 7, height = 5, dpi = 300)


# 4) Representative figure
rep_quad <- best_summary %>%
  filter(Best_by_AICc == "Quadratic") %>%
  slice(1) %>%
  pull(ID)

rep_log <- best_summary %>%
  filter(Best_by_AICc == "Logistic") %>%
  slice(1) %>%
  pull(ID)

rep_ids <- c(rep_quad, rep_log)
rep_ids <- rep_ids[!is.na(rep_ids)]

make_single_plot <- function(this_id) {
  subdat <- dat %>% filter(ID == this_id) %>% arrange(Time)
  pred_df <- get_predictions_for_plot(subdat, this_id)
  
  best_aicc <- best_summary %>%
    filter(ID == this_id) %>%
    pull(Best_by_AICc)
  
  ggplot(subdat, aes(x = Time, y = logPopBio)) +
    geom_point(size = 2, colour = "black") +
    geom_line(
      data = pred_df,
      aes(x = Time, y = Fitted, colour = Model),
      linewidth = 1
    ) +
    theme_bw(base_size = 12) +
    labs(
      title = paste0("ID: ", str_wrap(as.character(this_id), 30),
                     "\nBest by AICc: ", best_aicc),
      x = "Time",
      y = "log(PopBio)"
    ) +
    theme(
      plot.title = element_text(size = 10, hjust = 0.5),
      legend.position = "bottom"
    )
}

if (length(rep_ids) >= 1) {
  rep_plots <- lapply(rep_ids, make_single_plot)
  
  if (length(rep_plots) == 1) {
    final_rep_plot <- rep_plots[[1]]
  } else {
    final_rep_plot <- wrap_plots(rep_plots, ncol = 2) +
      plot_annotation(
        title = "Representative growth curves with overlaid fitted models",
        tag_levels = "A"
      )
  }
  
  ggsave(file.path(summary_dir, "representative_best_fits.png"),
         final_rep_plot, width = 10, height = 5, dpi = 300)
}
