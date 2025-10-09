#!/bin/sh
# Author:Zhiquan.Kang25@imperial.ac.uk
# Script: csvtospace.sh
# Description: substitute the commas in the files with tabs
# Saves the output into a .txt file
# Arguments: 1 -> comma delimited file
# Date: Oct 2025

# Check if correct number of arguments is provided
# "$#" gives the total number of arguments that were passed to the script when it was executed.
if [ $# -ne 1 ]; then 
    echo "Error: Wrong number of arguments."
    usage
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: Input file '$1' not found."
    exit 2
fi

echo "Creating a space delimited version of $1 ..."
cat $1 | tr -s "," "\t" >> $1.txt
echo "Done!"
exit