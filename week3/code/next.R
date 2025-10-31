for (i in 1:10) {
  # Check if the number is even (divisible by 2)
  if ((i %% 2) == 0) {
    next  # Skip the rest of the loop for this iteration
  }
  # Print the number if it is odd
  print(i)
}