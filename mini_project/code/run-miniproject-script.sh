#!/bin/bash

# Display script start
echo "Starting Bacterial Growth Model Mini Project..."

# Create necessary directories if they don't exist
mkdir -p ../result/subsets
mkdir -p ../result/results

# Step 1: Run R scripts in sequence
echo "Step 1: Running R scripts..."

echo "  - Running Data preparation.R..."
Rscript "Data preparation.R"
if [ $? -ne 0 ]; then
  echo "Error running Data preparation.R. Exiting."
  exit 1
fi

echo "  - Running Model fitting.R..."
Rscript "Model fitting.R"
if [ $? -ne 0 ]; then
  echo "Error running Model fitting.R. Exiting."
  exit 1
fi

echo "  - Running fitting_results_analysis.R..."
Rscript "fitting_results_analysis.R"
if [ $? -ne 0 ]; then
  echo "Error running fitting_results_analysis.R. Exiting."
  exit 1
fi

# Step 2: Compile LaTeX document
echo "Step 2: Compiling LaTeX document..."
echo "  - Running pdflatex first pass..."
pdflatex report.tex

echo "  - Running bibtex..."
bibtex report

echo "  - Running pdflatex second pass..."
pdflatex report.tex

echo "  - Running pdflatex final pass..."
pdflatex report.tex

# Check if the final PDF exists
if [ -f "report.pdf" ]; then
  echo "Successfully generated report.pdf!"
  echo "Mini Project completed successfully."
else
  echo "Error: Failed to generate report.pdf. Please check for errors in the LaTeX compilation."
  exit 1
fi