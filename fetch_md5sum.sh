#!/bin/bash

if ! klist -s; then 
  # If not, print error message and exit
  echo "Please have a valid Kerberos ticket, you need to run ' kinit $USER ' and enter your Kerberos password"
  exit -1 
fi

# Prompt the user for the version (e.g., 2.4.4.GA)
read -p "Enter the version (e.g., 2.4.4.GA): " version
echo " "

# URL for the MD5SUM file
url="https://download.eng.bos.redhat.com/devel/candidates/middleware/integration/RHI-SERVICE-REGISTRY-${version}/MD5SUM"

# Fetch the MD5SUM file content and assign it to a variable
file_content=$(curl -s "$url")

# Check if the version exists by searching for it in the content
if ! echo "$file_content" | grep -q "service-registry-$version"; then
  echo "Version $version not found"
  exit 1
fi

# Process the MD5SUM file content line by line
while read -r md5sum filename; do
  # Check if the filename matches the specified pattern
  if [[ "$filename" == service-registry-* ]]; then
    orig_link="http://download.eng.bos.redhat.com/devel/candidates/middleware/integration/RHI-SERVICE-REGISTRY-${version}/${filename}"
    echo "FILENAME: $filename"
    echo "ORIG_LINK: $orig_link"
    echo "MD5SUM: $md5sum"
    echo
  fi
done <<< "$file_content"

echo "Extraction completed."