# Run R scripts in sequence
echo "Step 1: Running R scripts..."

echo "  - Data preparation..."
Rscript "mini_prep.R"
if [ $? -ne 0 ]; then
  echo "Error running mini_prep.R. Exiting."
  exit 1
fi

echo "  - Model fit..."
Rscript "mini_fit.R"
if [ $? -ne 0 ]; then
  echo "Error running mini_fit.R. Exiting."
  exit 1
fi

echo "  - Model result plot..."
Rscript "mini_plot.R"
if [ $? -ne 0 ]; then
  echo "Error running mini_plot.R. Exiting."
  exit 1
fi