TreeHeight <- function(degrees, distance) {
  radians <- degrees * pi / 180  # Convert degrees to radians
  height <- distance * tan(radians)  # Calculate height using tangent
  return(height)
}

data_file <- "../data/trees.csv"

if (!file.exists(data_file)) {
  stop("Error: Input file '../data/trees.csv' does not exist. Please check the file path.")
}

trees <- read.csv(data_file)


trees$Tree.Height.m <- TreeHeight(trees$Angle.degrees, trees$Distance.m)

# Ensure the results directory exists
results_dir <- "../results"

# Save the updated data to a new CSV file
output_file <- file.path(results_dir, "TreeHts.csv")
write.csv(trees, file = output_file, row.names = FALSE)
