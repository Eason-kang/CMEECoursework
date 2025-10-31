# Load the necessary libraries
library(ggplot2)
library(dplyr)

# Read the data
data <- read.csv("../data/EcolArchives-E089-51-D1.csv")

# Calculate logarithmic values
data <- data %>%
  mutate(log_predator_mass = log(Predator.mass),
         log_prey_mass = log(Prey.mass),
         log_size_ratio = log(Prey.mass / Predator.mass))

# Calculate statistics for each type of feeding interaction
results <- data %>%
  group_by(Type.of.feeding.interaction) %>%
  summarise(
    mean_log_predator_mass = mean(log_predator_mass, na.rm=TRUE),
    median_log_predator_mass = median(log_predator_mass, na.rm=TRUE),
    mean_log_prey_mass = mean(log_prey_mass, na.rm=TRUE),
    median_log_prey_mass = median(log_prey_mass, na.rm=TRUE),
    mean_log_size_ratio = mean(log_size_ratio, na.rm=TRUE),
    median_log_size_ratio = median(log_size_ratio, na.rm=TRUE)
  )

# Save the statistical data to a CSV file
write.csv(results, "../results/PP_Results.csv", row.names = FALSE)

# Create and save histograms
feeding_types <- unique(data$Type.of.feeding.interaction)

# Create histograms for predator mass
pdf("../results/Pred_Subplots.pdf")
par(mfrow = c(3, 2))
for(feeding_type in feeding_types) {
  hist(subset(data, Type.of.feeding.interaction == feeding_type)$log_predator_mass,
       main = paste("Predator Mass -", feeding_type),
       xlab = "Log(Predator Mass)")
}
dev.off()

# Create histograms for prey mass
pdf("../results/Prey_Subplots.pdf")
par(mfrow = c(3, 2))
for(feeding_type in feeding_types) {
  hist(subset(data, Type.of.feeding.interaction == feeding_type)$log_prey_mass,
       main = paste("Prey Mass -", feeding_type),
       xlab = "Log(Prey Mass)")
}
dev.off()

# Create histograms for size ratio
pdf("../results/SizeRatio_Subplots.pdf")
par(mfrow = c(3, 2))
for(feeding_type in feeding_types) {
  hist(subset(data, Type.of.feeding.interaction == feeding_type)$log_size_ratio,
       main = paste("Size Ratio -", feeding_type),
       xlab = "Log(Size Ratio)")
}
dev.off()