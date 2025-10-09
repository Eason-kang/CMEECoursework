#!/bin/sh
# Author:Zhiquan.Kang25@imperial.ac.uk
# Script: ConcatenateTwoFiles.sh
# Description: Merge names of two files into one
# Arguments: 1 & 2 -> 3
# Date: Oct 2025
if [ "$#" -ne 2 ]; then
    echo "Error: You need input 2 arguments."
    echo "Usage: $0 <input_file1> <input_file2>"
    exit 1
fi


# Check if the input files exist
for file in "$1" "$2"; do
    if [ ! -f "$file" ]; then
        echo "Error: Your input file '$file' does not exist."
        exit 1
    fi
done

cat $1 > $3
cat $2 >> $3
echo "Merged File is"
cat $3