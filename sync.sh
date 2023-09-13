#!/bin/bash

set -eo pipefail

upstream="git@github.com:Apicurio/apicurio-registry.git"
midstream="git@github.com:redhat-integration/apicurio-registry.git"

#upstream="https://github.com/NikishaPatil/dummy-upstream.git"
#midstream="https://github.com/NikishaPatil/dummy-midstream.git"


# Display operation options to the user
echo "Select an operation:"
echo "1. Upstream tag -> Midstream branch"
echo "2. Upstream tag -> Midstream tag"
echo "3. Upstream branch -> Midstream branch"
echo "4. Upstream branch -> Midstream tag"

# Prompt user for source and target versions
read -p "Enter the number of the desired operation: " operation
echo " "
echo ">>>>>>>>>>>>>"
echo " "

case "$operation" in
    1)
        operation_text="Upstream tag -> Midstream branch"
        ;;
    2)
        operation_text="Upstream tag -> Midstream tag"
        ;;
    3)
        operation_text="Upstream branch -> Midstream branch"
        ;;
    4)
        operation_text="Upstream branch -> Midstream tag"
        ;;
    *)
        echo "Invalid operation selected."
        exit 1
        ;;
esac


echo "Selected operation: $operation_text"


# Prompt user for source and target versions
read -p "Enter source version: " source
read -p "Enter target version: " target
echo " "


# Create a directory for syncing and initialize Git repository
rm -rf sync
mkdir sync && cd sync
git init


# Add remote repositories
git remote add upstream "${upstream}"
git remote add midstream "${midstream}"


# Fetch tags and branches from upstream
git fetch --tags --progress upstream +refs/heads/*:refs/remotes/upstream/*


echo " "
echo ">>>>>>>>>>>>>"
echo " "
# Perform the selected operation 
case "$operation" in
    1)
        echo "Syncing ${source} to ${target} (Upstream tag to Midstream branch)..."
        git push midstream "+refs/tags/${source}:refs/heads/${target}"
        ;;
    2)
        echo "Syncing ${source} to ${target} (Upstream tag to Midstream tag)..."
        git push midstream "+refs/tags/${source}:refs/tags/${target}"
        ;;
    3)
        echo "Syncing ${source} to ${target} (Upstream branch to Midstream branch)..."
        git push midstream "+refs/remotes/upstream/${source}:refs/heads/${target}"
        ;;
    4)
        echo "Syncing ${source} to ${target} (Upstream branch to Midstream tag)..."
        git push midstream "+refs/remotes/upstream/${source}:refs/tags/${target}"
        ;;
esac