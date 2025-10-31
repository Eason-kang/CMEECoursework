rm(list = ls())

data = read.csv("../data/EcolArchives-E089-51-D1.csv")
library(dplyr)
library(broom)
# create a empty dataframe for saving data
results <- data.frame(
  Type.of.feeding.interaction = character(),
  Predator.lifestage = character(),
  Slope = numeric(),
  Intercept = numeric(),
  R2 = numeric(),
  F_stat = numeric(),
  P_value = numeric(),
  stringsAsFactors = FALSE
)

# Group data by group
grouped_data <- data %>% group_by(Type.of.feeding.interaction, Predator.lifestage)

# Loop each group
for (group in group_split(grouped_data)) {
  # If the current group is empty, skip it
  if (nrow(group) == 0) {
    print("Skipping empty group")
    next
  }
  
  # display the packet debugging information
  feeding_type <- unique(group$Type.of.feeding.interaction)
  predator_lifestage <- unique(group$Predator.lifestage)
  print(paste("Processing group:", feeding_type, "-", predator_lifestage))
  print(paste("Number of rows in group:", nrow(group)))
  
  # Check whether the grouped data is sufficient for regression analysis
  if (nrow(group) < 2) {
    print("Not enough data for regression, skipping this group")
    next
  }
  
  # Try to fit the regression model
  model <- tryCatch(
    lm(Predator.mass ~ Prey.mass, data = group),
    error = function(e) {
      print("Error in fitting model, skipping this group")
      return(NULL)
    }
  )
  
  # If the model fit fails, skip the grouping
  if (is.null(model)) next
  
  # Safely extract regression parameters
  tryCatch({
    slope <- coef(model)["Prey.mass"]
    intercept <- coef(model)["(Intercept)"]
    r_squared <- summary(model)$r.squared
    f_stat <- summary(model)$fstatistic[1]
    p_value <- glance(model)$p.value
    
    # Add the result to the data box
    results <- rbind(results, data.frame(
      Type.of.feeding.interaction = feeding_type,
      Predator.lifestage = predator_lifestage,
      Slope = slope,
      Intercept = intercept,
      R2 = r_squared,
      F_stat = f_stat,
      P_value = p_value,
      stringsAsFactors = FALSE
    ))
  }, error = function(e) {
    print("Error in extracting model statistics, skipping this group")
  })
}

# save results
write.csv(results, "../results/PP_Regress_Results.csv", row.names = FALSE)

library(ggplot2)

# draw a diagram

plot <- ggplot(data, aes(x = Prey.mass, y = Predator.mass, color = Predator.lifestage)) +
  geom_point(size = 1, shape = 3, alpha = 0.8) + # Scatter, transparency adjustment
  geom_smooth(method = "lm", se = TRUE, size = 0.8, fullrange = TRUE, alpha = 0.2) + # Regression line and confidence interval
  facet_wrap(~ Type.of.feeding.interaction, scales = "fixed", ncol = 1, strip.position = "right") + # Coordinate calibration fixation
  scale_x_log10(breaks = c(1e-07, 1e-03, 1e+01)) + # Logarithmic scale on the horizontal axis
  scale_y_log10(breaks = c(1e-06, 1e-02, 1e+02, 1e+06)) + # Vertical axis logarithmic scale
  labs(
    x = "Prey Mass in grams",
    y = "Predator Mass in grams",
    color = "Predator.lifestage"
  ) +
  theme_minimal() + 
  theme(
    text = element_text(size = 10), # Global font size
    legend.position = "bottom", # Adjust the legend position to the bottom
    legend.title = element_text(size = 10), # Legend title font size
    legend.text = element_text(size = 9), # Legend text font size
    strip.text.y = element_text(size = 8, angle = 0, hjust = 0.5), # Adjust the font size of the right section header
    strip.background = element_blank(), # Remove the faceted background frame
    panel.border = element_rect(color = "grey", fill = NA, linewidth = 0.5), # Panel border
    panel.grid.major = element_line(size = 0.3, color = "grey80"), # Main grid line color
    panel.grid.minor = element_blank(), # Remove the subgrid lines
    panel.spacing = unit(0.5, "lines") # Plane spacing
  )
print(plot)
#Save the chart as a PDF file
ggsave("../results/PP_Regress_Updated_Fixed.pdf", plot = plot, width = 8, height = 12)
