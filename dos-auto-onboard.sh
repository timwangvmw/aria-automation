#!/bin/bash

# Check if enough arguments are provided
if [ $# -ne 3 ]; then
  echo "Usage: $0 <identity_service_url> <username> <password>"
  exit 1
fi

# Get values provided by the user from command-line arguments
identity_service_url="$1"
username="$2"
password="$3"

# Rest of the script remains unchanged, using the provided variables

# Get the API token
api_token=$(curl -k -X POST \
  "$identity_service_url/csp/gateway/am/api/login?access_token" \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "'"$username"'",
    "password": "'"$password"'"
  }' | jq -r .refresh_token)

# Obtain an access token
access_token=$(curl -k -X POST \
  "$identity_service_url/iaas/api/login" \
  -H 'Content-Type: application/json' \
  -s \
  -d '{
    "refreshToken": "'"$api_token"'"
  }' | jq -r .token)

# Send a GET request and process the JSON list
response=$(curl -k -X 'GET' \
  "$identity_service_url/relocation/onboarding/resource" \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $access_token")

resource_ids=$(echo "$response" | jq -r '.documentLinks[]')

# Print resource IDs
#echo "Resource IDs:"
#echo "$resource_ids"

# Use a loop to get detailed information for each resource
for resource_id in $resource_ids; do
  echo "Fetching resource with ID: $resource_id"

  # Send a GET request to obtain resource details
  resource_info=$(curl -k -X 'GET' \
    "$identity_service_url$resource_id" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer $access_token")

  # Print resource details
  #echo "Resource details:"
  #echo "$resource_info"

  # Use jq to parse JSON and extract the resourceName field's value
  resource_name=$(echo "$resource_info" | jq -r '.resourceName')
  deployment_link=$(echo "$resource_info" | jq -r '.deploymentLink')
  # Print resource name
  echo "Resource Name: $resource_name"
  echo "Deployment Link: $deployment_link"

  # Build the PATCH request URL
  patch_url="$identity_service_url$deployment_link"

  # Send a PATCH request to modify the resource
  patch_response=$(curl -k -X 'PATCH' \
    "$patch_url" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer $access_token" \
    -H 'Content-Type: application/json' \
    -d '{
      "name": "'"$resource_name"'",
      "owner": "TIMWANG"
    }')

  # Print PATCH request response
  echo "PATCH Response:"
  echo "$patch_response"

done