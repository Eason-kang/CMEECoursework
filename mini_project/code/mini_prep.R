rm(list = ls())
library(dplyr)

# 1. Load raw dataset

growth_data <- read.csv(
  "../data/logistic_growth_data.csv",
  stringsAsFactors = FALSE)
   
meta_data <- read.csv(
  "../data/logistic_growth_meta_data.csv",
  stringsAsFactors = FALSE)

# 2. Create dataset IDs

# Convert citation text into numeric labels
growth_data$citation_id <- as.numeric(
  factor(growth_data$Citation,
         levels = unique(growth_data$Citation))
)

# Create unique dataset identifier
growth_data$ID <- paste(
  growth_data$Species,
  growth_data$Temp,
  growth_data$Medium,
  growth_data$citation_id,
  sep = "_"
)

# 3. Inspect problematic values

missing_values <- sum(is.na(growth_data))
negative_popbio <- sum(growth_data$PopBio < 0, na.rm = TRUE)
zero_popbio <- sum(growth_data$PopBio == 0, na.rm = TRUE)
negative_time <- sum(growth_data$Time < 0, na.rm = TRUE)


# 4. Basic data cleaning
# Remove rows unsuitable for log transform
growth_clean <- growth_data %>%
  filter(
    !is.na(Time),
    !is.na(PopBio),
    is.finite(Time),
    is.finite(PopBio),
    PopBio > 0,
    Time >= 0
  ) %>%
  arrange(ID, Time)

# Add logarithmic columns
growth_clean$logPopBio <- log(growth_clean$PopBio)
growth_clean$log10PopBio <- log10(growth_clean$PopBio)

# 5. Save cleaned dataset
write.csv(
  growth_clean,
  "../data/modified_growth_data.csv",
  row.names = FALSE
)
