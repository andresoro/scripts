#!/bin/bash

# Output file
output_file="requirements-final.txt"

# Temporary file
temp_file=$(mktemp)

# Extract package names from the original requirements.txt
cut -d'=' -f1 requirements.txt | sort > "$temp_file"

# Process requirements-locked.txt and keep only packages present in both files
while IFS= read -r line
do
    package=$(echo "$line" | cut -d'=' -f1)
    if grep -q "^$package$" "$temp_file"; then
        echo "$line" >> "$output_file"
    fi
done < requirements-locked.txt

# Clean up
rm "$temp_file"

echo "Created $output_file with packages present in both files."
