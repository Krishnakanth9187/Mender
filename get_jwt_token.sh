#!/bin/bash

# Base64-encoded username:password for basic authentication
# The value "Basic bWFuYXMuZmx5dGJhc2VAZmx5dGJhc2UuY29tOnZDbkxma0BmcWhwajVZQQ==" 
# is equivalent to "manas.wagh@flytbase.com:vCnLfk@fqhpj5YA" encoded in Base64.
AUTH_HEADER="Basic c3J2QGZseXRiYXNlLmNvbTpYRHVhWjNYNEg2eW16cSE"

# Base URL for the Mender API
BASE_URL="https://hosted.mender.io/api/management/v1/useradm"
API_ENDPOINT="/auth/login"

# First API call to get the JWT token using Basic Authentication
echo "Making API call to get JWT token..."
JWT_TEMP=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: $AUTH_HEADER" "$BASE_URL$API_ENDPOINT")

# Log the full response from the server to see what is being returned
echo "Response from the /auth/login endpoint:"
echo "$JWT_TEMP"

# Since the JWT token is the entire response, assign it directly
JWT_TOKEN="$JWT_TEMP"

# Check if JWT token was successfully retrieved
if [ -z "$JWT_TOKEN" ] || [ "$JWT_TOKEN" == "null" ]; then
    echo "Failed to get JWT token. Response: $JWT_TEMP"
    exit 1
fi

echo "JWT token successfully obtained: $JWT_TOKEN"

# Use the JWT token to get the tenant information
TENANT_API_URL="https://hosted.mender.io/api/management/v1/tenantadm/user/tenant"

# Make the second API request using the JWT token in the Authorization header
TENANT_INFO=$(curl -s -X GET -H "Authorization: Bearer $JWT_TOKEN" -H "Content-Type: application/json" "$TENANT_API_URL")

# Print the tenant information
echo "Tenant Information:"
echo "$TENANT_INFO"

# Extract tenant token from the tenant information using jq
TENANT_TOKEN=$(echo "$TENANT_INFO" | jq -r '.tenant_token')

# Check if tenant token was successfully extracted
if [ -z "$TENANT_TOKEN" ] || [ "$TENANT_TOKEN" == "null" ]; then
    echo "Failed to get tenant token."
    exit 1
fi

# Print the extracted tenant token
echo "Tenant token: $TENANT_TOKEN"

# Set the device type to "fbair"
DEVICE_TYPE="fbair"

sudo mender-setup \
            --device-type $DEVICE_TYPE \
            --hosted-mender \
            --tenant-token $TENANT_TOKEN \
            --demo-polling

