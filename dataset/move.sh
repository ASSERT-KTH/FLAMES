#!/bin/bash

# Specify the path to your main folder
main_folder="smart-contract-fiesta/organized_contracts"

# Specify the name of the new folder that will contain the second-level folders
new_folder="smart-contract-fiesta/flattened"

# Create the new folder if it doesn't exist
mkdir -p "$new_folder"

# Move all second-level folders into the new folder
find "$main_folder" -mindepth 2 -maxdepth 2 -type d -exec mv {} "$new_folder" \;

echo "Folders flattened successfully."
