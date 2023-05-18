#!/bin/bash

# Extract the name, version, and replaces values
name=$(yq e '.metadata.name' test.yaml)
echo "Name: $name"

version=$(yq e '.spec.version' test.yaml)
echo "Version: $version"

replaces=$(yq e '.spec.replaces' test.yaml)
echo "Replaces: $replaces"

# Prompt user to change CSV version number
read -p "Do you want to change the CSV version number? (y/n) " csv_choice
if [ "$csv_choice" == "y" ]; then
    # Prompt user to select version bump
    echo "Select the version bump:"
    echo "1. Major"
    echo "2. Minor"
    echo "3. Patch"
    read -p "Enter your choice (1-3): " choice

    case $choice in
        1)
            # Increment the major version number
            new_version=$(echo $version | awk -F '.' '{print ($1+1)"."$2"."$3}')
            ;;
        2)
            # Increment the minor version number
            new_version=$(echo $version | awk -F '.' '{print $1"."($2+1)"."$3}')
            ;;
        3)
            # Increment the patch version number
            new_version=$(echo $version | awk -F '.' '{print $1"."$2"."($3+1)}')
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    # Replace the version number in the name and replaces values
    new_name=$(echo $name | sed "s/$version/$new_version/")
    new_replaces=$(echo $replaces | sed "s/$replaces/$name/")

    # Print out the new values
    echo "New Name: $new_name"
    echo "Version: $new_version"
    echo "New Replaces: $new_replaces"

    # Update the values in the YAML file
    sed -i "s/$name/$new_name/; s/$version/$new_version/; s/$replaces/$new_replaces/" test.yaml
else
    echo "CSV version number is up to date."
fi
