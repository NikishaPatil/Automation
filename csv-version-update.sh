#!/bin/bash

# Extract the name, version, and replaces values
name=$(yq e '.metadata.name' test.yaml)
echo "Name: $name"

version=$(yq e '.spec.version' test.yaml)
echo "Version: $version"

replaces=$(yq e '.spec.replaces' test.yaml)
echo "Replaces: $replaces"

# Increment the version number
new_version=$(echo $version | awk -F '.' '{print $1"."$2"."($3+1)}')

# Replace the version number in the name and replaces values
new_name=$(echo $name | sed "s/$version/$new_version/")
new_replaces=$(echo $replaces | sed "s/$replaces/$name/")

# Print out the new values
echo "New Name: $new_name"
echo "Version: $new_version"
echo "New Replaces: $new_replaces"

# Update the values in the YAML file
sed -i "s/$name/$new_name/; s/$version/$new_version/; s/$replaces/$new_replaces/" test.yaml

