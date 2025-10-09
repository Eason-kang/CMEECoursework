#!/bin/sh
# Author:Zhiquan.Kang25@imperial.ac.uk
# Script: tabtocsv.sh
# Description: substitute the tabs in the files with commas
# Saves the output into a .csv file
# Arguments: 1 -> tab delimited file
# Date: Oct 2025
 if [ $# -ne 1 ]; then
 echo "Error: Incorrect number of arguments."
 usage
 exit 1
 fi

 if [ ! -f "$1" ]; then
    echo "Error: Input file '$1' not found."
    exit 2
fi

echo "Creating a comma delimited version of $1 ..."
cat $1 | tr -s "\t" "," >> $1.csv
echo "Done!"
exit
