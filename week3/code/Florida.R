#!/usr/bin/env Rscript
# Author: Zhiquan Kang
# Script: Florida.R
# Description: Analyze temperature data in Key West, Florida, to determine trends over time using Spearman's rank correlation and randomization.
# Outputs: Histogram plot and summary statistics.
# Date: Oct 2025

# Load required package
install.packages("tidyverse")

# Clear environment
rm(list = ls())  # Remove all objects from the current environment to avoid conflicts

# Load the dataset
load("../data/KeyWestAnnualMeanTemperature.RData")  # Load temperature data

# Inspect dataset
ls()  # List loaded objects in the environment
head(ats)  # Display the first few rows of the dataset
# Scatter plot to visualize temperature trends over time
plot(ats)

##############################################
# Function: Generate randomized correlations
# Input: repeats -> Number of randomizations
# Output: A vector of Spearman's rho values for each randomization
Sample_Random <- function(repeats) {
  correlations <- numeric(repeats)  # Preallocate vector for correlations
  
  # Loop to generate randomized correlations
  for (i in 1:repeats) {
    shuffled_temp <- sample(ats$Temp, length(ats$Temp), replace = TRUE) 
    # Randomize temperature data
    spearman_res <- cor.test(ats$Year, shuffled_temp, method = "spearman")
    # Calculate Spearman's rank correlation
    correlations[i] <- as.numeric(spearman_res$estimate)  # Store the rho value
  }
  
  return(correlations)  # Return all generated correlations
}

# Calculate actual correlation
actual_cor <- cor(ats$Year, ats$Temp, method = "spearman")

# Generate random correlations
set.seed(123)  # For reproducibility of results
Random_corrs <- Sample_Random(20000)  # Generate 1,000 random correlations

# Count how many random correlations exceed the actual correlation
num_above_actual <- sum(Random_corrs > as.numeric(actual_cor))  # Calculate how many exceed observed rho
cat("Number of random correlations greater than observed rho:", num_above_actual, "\n")  # Print the count
