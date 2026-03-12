install.packages("minpack.lm")
# install.packages("MuMIn")
rm(list = ls())

library(dplyr)
library(minpack.lm)   # for nlsLM
# library(MuMIn)        # for AICc

# 1. Read cleaned dataset
dat <- read.csv(
  "../data/modified_growth_data.csv",
  stringsAsFactors = FALSE
)  
all_ids <- unique(dat$ID)

# 2. Utility functions
# Compute model statistics manually from residuals
calc_model_stats <- function(model, df) {
  if (is.null(model) || inherits(model, "try-error")) {
    return(list(
      R2 = NA_real_,
      AIC = NA_real_,
      AICc = NA_real_,
      BIC = NA_real_
    ))
  }
  
  # residuals
  res <- tryCatch(as.numeric(residuals(model)), error = function(e) NULL)
  if (is.null(res)) {
    return(list(
      R2 = NA_real_,
      AIC = NA_real_,
      AICc = NA_real_,
      BIC = NA_real_
    ))
  }
  
  # sample size and number of parameters
  n <- length(res)
  k <- length(coef(model))
  
  # RSS
  rss <- sum(res^2, na.rm = TRUE)
  
  # TSS for pseudo-R2
  tss <- sum((df$logPopBio - mean(df$logPopBio, na.rm = TRUE))^2, na.rm = TRUE)
  r2 <- if (tss == 0) NA_real_ else 1 - rss / tss
  
  # avoid log(0)
  if (!is.finite(rss) || rss <= 0) rss <- 1e-12
  
  # Information criteria
  aic_val <- n * log(rss / n) + 2 * k
  bic_val <- n * log(rss / n) + log(n) * k
  
  # small-sample corrected AIC
  if ((n - k - 1) > 0) {
    aicc_val <- aic_val + (2 * k * (k + 1)) / (n - k - 1)
  } else {
    aicc_val <- NA_real_
  }
  
  list(
    R2 = r2,
    AIC = aic_val,
    AICc = aicc_val,
    BIC = bic_val
  )
}

# Safe extraction of model statistics
extract_stats <- function(model, df, model_name) {
  if (is.null(model) || inherits(model, "try-error")) {
    return(tibble(
      model = model_name,
      converged = FALSE,
      R2 = NA_real_,
      AIC = NA_real_,
      AICc = NA_real_,
      BIC = NA_real_
    ))
  }
  
  stat <- calc_model_stats(model, df)
  
  tibble(
    model = model_name,
    converged = TRUE,
    R2 = stat$R2,
    AIC = stat$AIC,
    AICc = stat$AICc,
    BIC = stat$BIC
  )
}

# Extract coefficients safely
extract_coefs <- function(model, id_value, model_name) {
  
  # return NULL for obviously invalid objects
  if (is.null(model) || inherits(model, "try-error")) {
    return(NULL)
  }
  
  # safely try to get coefficients
  cf <- tryCatch(coef(model), error = function(e) NULL)
  
  # if coefficients cannot be extracted, return NULL
  if (is.null(cf)) {
    return(NULL)
  }
  
  # make sure coefficient vector has names
  term_names <- names(cf)
  if (is.null(term_names)) {
    term_names <- paste0("par", seq_along(cf))
  }
  
  tibble(
    ID = id_value,
    model = model_name,
    term = term_names,
    estimate = as.numeric(cf)
  )
}

# Estimate starting growth rate
estimate_slope <- function(df) {
  df2 <- df %>% arrange(Time)
  slopes <- diff(df2$logPopBio) / diff(df2$Time)
  slopes <- slopes[is.finite(slopes)]
  if (length(slopes) == 0) return(0.1)
  max(slopes, na.rm = TRUE)
}

# 3. Define logistic model
# Logistic growth model on original scale, returned on log scale
logistic_log_model <- function(t, r, K, N0) {
  log(N0 * K * exp(r * t) / (K + N0 * (exp(r * t) - 1)))
}

# 4. Fit logistic model with multi-start
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
  
  aicc_values <- sapply(
    fit_list,
    function(m) tryCatch(AICc(m), error = function(e) Inf)
  )
  
  fit_list[[which.min(aicc_values)]]
}

# 5. Containers for output
stats_list <- list()
coef_list  <- list()

# 6. Main loop over IDs
run_no <- 0

for (this_id in all_ids) {
  run_no <- run_no + 1
  cat("Fitting ID", run_no, "of", length(all_ids), ":", this_id, "\n")
  
  subdat <- dat %>%
    filter(ID == this_id) %>%
    arrange(Time)
  
  if (length(unique(subdat$Time)) < 4) {
    cat("Skipping", this_id, "- too few unique time points.\n")
    next
  }
  
  # Linear model: Quadratic
  fit_quad <- tryCatch(
    lm(logPopBio ~ Time + I(Time^2), data = subdat),
    error = function(e) NULL
  )
  
  # Nonlinear model: Logistic
  fit_logistic <- fit_logistic_model(subdat, n_starts = 20)
  
  # Collect model statistics
  one_result <- bind_rows(
    extract_stats(fit_quad, subdat, "Quadratic"),
    extract_stats(fit_logistic, subdat, "Logistic")
  ) %>%
    mutate(
      ID = this_id,
      n_points = nrow(subdat)
    ) %>%
    select(ID, model, n_points, converged, R2, AIC, AICc, BIC)
  
  stats_list[[length(stats_list) + 1]] <- one_result
  
  # Collect coefficients
  one_coef <- bind_rows(
    extract_coefs(fit_quad, this_id, "Quadratic"),
    extract_coefs(fit_logistic, this_id, "Logistic")
  )
  
  coef_list[[length(coef_list) + 1]] <- one_coef
}

# 7. Combine outputs
model_results <- bind_rows(stats_list)
model_coeffs  <- bind_rows(coef_list)

# 8. Select best model
best_summary <- model_results %>%
  group_by(ID) %>%
  summarise(
    Best_by_AICc = if (all(is.na(AICc))) NA_character_ else model[which.min(AICc)],
    Best_by_BIC  = if (all(is.na(BIC)))  NA_character_ else model[which.min(BIC)],
    .groups = "drop"
  )

print(best_summary %>% count(Best_by_AICc))
print(best_summary %>% count(Best_by_BIC))

# 9. Save outputs
write.csv(
  model_results,
  "../results/model_results.csv",
  row.names = FALSE
)

write.csv(
  model_coeffs,
  "../results/model_coefficients.csv",
  row.names = FALSE
)

write.csv(
  best_summary,
  "../results/best_model_summary.csv",
  row.names = FALSE
)
