#!/bin/bash

# Check if the secret name is passed as an argument
if [ -z $1 ]; then
    echo "A secret name must be provided as an argument"
    exit 1
fi

secret_name=$1

# Check if the secret exists
secret_exists=$(gcloud secrets list --format='value(name)' | grep $secret_name)

if [ -z "$secret_exists" ]; then
    echo "The secret $secret_name does not exist"
    exit 1
fi

# Get the latest version number of the secret
start_version_number=$(gcloud secrets versions list $secret_name --format='value(name)' --limit 1)

# Create random names for the temp files
random_file_name="temp_file_$RANDOM.txt"
random_backup_name="before_changes_$RANDOM.txt"

# Get the latest version of the secret and store it in a temp file
gcloud secrets versions access --secret $secret_name latest > "$random_file_name"

# Create a backup copy of the temp file
cp -a "$random_file_name" "$random_backup_name"

# Open the temp file in the default editor or vi if no editor is set
if [ -z "$EDITOR" ]; then
    vi "$random_file_name"
else
    $EDITOR "$random_file_name"
fi

# Show the changes that will be applied
echo "Changes to be applied:"
diff "$random_backup_name" "$random_file_name"

# Ask for confirmation before adding the new version
read -p "Do you want to continue? (y/n)" choice
if [ "$choice" == "y" ]; then
    current_version_number=$(gcloud secrets versions list $secret_name --format='value(name)' --limit 1)
    if [ "$start_version_number" != "$current_version_number" ]; then
        echo "A new version of the secret has been added since this script was started"
        echo "Aborting the operation"
        # Remove the temp files
        rm "$random_file_name" "$random_backup_name"
        exit 1
    else
        # Add the new version of the secret
        gcloud secrets versions add $secret_name --data-file="$random_file_name"
        if [ $? -eq 0 ]; then
            echo "Successfully added a new version of the secret"
        else
            echo "Failed to add a new version of the secret"
        fi
    fi
else
    echo "Aborting the operation"
fi

# Remove the temp files
rm "$random_file_name" "$random_backup_name"