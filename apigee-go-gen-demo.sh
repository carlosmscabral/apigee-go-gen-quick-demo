#!/bin/bash

# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script demonstrates the features of the apigee-go-gen tool.

set -e

# Colors
BLUE='[0;34m'
GREEN='[0;32m'
RED='[0;31m'
NC='[0m' # No Color

# Check for required environment variables
REQUIRED_VARS=(
    "PROJECT_ID"
    "APIGEE_HOST"
    "APIGEE_ENV"
)
ALL_VARS_SET=true
for var_name in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var_name}" ]; then
    echo -e "${RED}ERROR: No ${var_name} variable set. Please set it.${NC}"
    ALL_VARS_SET=false
  fi
done

if [ "$ALL_VARS_SET" = false ]; then
  echo -e "${RED}ERROR: One or more required environment variables are missing. Exiting.${NC}"
  exit 1
fi


echo "✅ Installing apigee-go-gen tool ..."
curl -s https://apigee.github.io/apigee-go-gen/install | bash -s v1.1.0-beta.1 ~/.apigee-go-gen/bin
export PATH=$PATH:$HOME/.apigee-go-gen/bin

echo -e "${GREEN}✅ All required environment variables are set. Starting the demo.${NC}"

# --- API Proxy to YAML ---
echo -e "
${BLUE}--- 📖 API Proxy to YAML ---${NC}"
echo "This section demonstrates how to convert an API Proxy to YAML."
# apigee-go-gen proxy to-yaml -s <path-to-proxy-bundle> -o <path-to-output-yaml>
apigee-go-gen transform apiproxy-to-yaml \
  --input ./examples/apiproxies/helloworld/helloworld.zip \
  --output ./out/yaml-first/helloworld1/apiproxy.yaml

echo ""


# --- YAML to API Proxy ---
echo -e "${BLUE}--- 📖 YAML to API Proxy ---${NC}"
echo "This section demonstrates how to convert a YAML file to an API Proxy."
# apigee-go-gen proxy from-yaml -f <path-to-yaml-file> -o <path-to-output-directory>
apigee-go-gen transform yaml-to-apiproxy \
  --input ./examples/yaml-first/petstore/apiproxy.yaml \
  --output ./out/apiproxies/petstore.zip


echo ""

# --- Render OpenAPI ---
echo -e "${BLUE}--- 🎨 Render OpenAPI ---${NC}"
echo "This section demonstrates how to render an OpenAPI specification."
# apigee-go-gen openapi render -f <path-to-openapi-file> -o <path-to-output-file>
apigee-go-gen render apiproxy \
    --template ./examples/templates/oas3/apiproxy.yaml \
    --set-oas spec=./examples/specs/oas3/petstore.yaml \
    --include ./examples/templates/oas3/*.tmpl \
    --output ./out/apiproxies/petstore.zip

echo ""

# --- Render MCP ---
echo -e "${BLUE}--- ⚙️ Render MCP ---${NC}"
echo "This section demonstrates how to render a Managed Component Platform (MCP) configuration."

apigee-go-gen render apiproxy \
  --template ./examples/templates/mcp/apiproxy.yaml \
  --set-oas spec=./examples/specs/oas3/petstore.yaml \
  --include ./examples/templates/mcp/*.tmpl \
  --output ./out/proxies/mcp-petstore-v1

apigeecli apis create bundle -e dev -n mcp-petstore-v1 -f ./out/proxies/mcp-petstore-v1/apiproxy --ovr -o cabral-apigee -t $(gcloud auth print-access-token) 
echo ""

# --- Mock ---
echo -e "${BLUE}--- 🎭 Mock ---${NC}"
echo "This section demonstrates how to create a mock API from an OpenAPI specification."
# apigee-go-gen mock oas -f <path-to-openapi-file> -o <path-to-output-directory>
echo "Example: apigee-go-gen mock oas -f my-api.yaml -o /path/to/my-mock-proxy"
echo ""

echo -e "${GREEN}🎉 Demo script finished.${NC}"