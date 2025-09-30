# Shell Scripting Guide for Gemini

This document provides a set of guidelines and best practices for writing shell scripts in this project. The goal is to ensure consistency, readability, and maintainability of our scripts.

## 1. Header

All shell scripts should start with the `#!/bin/bash` shebang to ensure they are executed with the Bash interpreter.

A copyright and license header should be included at the top of each script.

```bash
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
```

## 2. Variable Checks

At the beginning of each script, check for the existence of all required environment variables. This helps to prevent errors and makes the script's dependencies clear.

### Simple Check

For a small number of variables, a simple check is sufficient.

```bash
if [ -z "$PROJECT_ID" ]; then
  echo "No PROJECT_ID variable set"
  exit 1
fi
```

### Comprehensive Check

For a larger number of variables, a more comprehensive check is recommended.

```bash
REQUIRED_VARS=(
    "PROJECT"
    "REGION"
    "APIGEE_ENV"
    "APIGEE_HOST"
    "SA_EMAIL"
)
ALL_VARS_SET=true
for var_name in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var_name}" ]; then
    echo "ERROR: No ${var_name} variable set. Please set it."
    ALL_VARS_SET=false
  fi
done

if [ "$ALL_VARS_SET" = false ]; then
  echo "ERROR: One or more required environment variables are missing. Exiting."
  exit 1
fi
```

## 3. Error Handling

Use `set -e` at the beginning of your script to make it exit immediately if a command exits with a non-zero status. This helps to prevent unexpected behavior and makes it easier to debug errors.

For more granular error handling, check the exit code of a command and print an error message.

```bash
if ! gcloud run deploy "${target_service_name}" --source . --platform="managed" --region="${REGION}" --no-allow-unauthenticated --port=5001 --quiet; then
    echo "ERROR: gcloud run deploy failed for service '${target_service_name}' (${friendly_service_name})."
    popd > /dev/null || exit 1
    exit 1
fi
```

## 4. Tool Execution

When using external tools, check if they are installed before using them. This is especially important for tools that are not part of the standard development environment.

```bash
if ! command -v apigeecli &> /dev/null
then
    echo "apigeecli could not be found. Installing it..."
    curl -s https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | bash
    export PATH=$PATH:$HOME/.apigeecli/bin
fi
```

When parsing JSON output, use `jq` to extract the required information.

```bash
APIKEY=$(apigeecli apps get --name "adk-auto-insurance-app" --org "$PROJECT_ID" --token "$TOKEN" --disable-check | jq ."[0]".credentials[0].consumerKey -r)
```

## 5. Functions

Use functions to group related commands and improve code readability and reusability.

```bash
add_role_to_service_account() {
  local role=$1
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="$role"
}
```

Use local variables within functions to avoid polluting the global scope.

## 6. Naming Conventions

- **Variables:** Use `UPPER_CASE_SNAKE_CASE` for variable names.
- **Functions:** Use `lower_case_snake_case` for function names.

## 7. Portability

When using commands that may have different behavior on different operating systems, add a check to ensure portability.

```bash
sedi_args=("-i")
if [[ "$(uname)" == "Darwin" ]]
then
  sedi_args=("-i" "") # For macOS, sed -i requires an extension argument. "" means no backup.
fi

sed "${sedi_args[@]}" "s/TARGETURL/$CUSTOMERS_API_CR_URL/g" ./apigee_resources/bundles/customers-api/apiproxy/targets/default.xml
```

## 8. Logging

Use `echo` to log informative messages to the console. This helps to understand the script's progress and debug issues. Use emojis and colors in plenty, as much as possible for having a nice output experience.

```bash
echo "Deploying the Proxy"
# ...
echo "All the Apigee artifacts are successfully deployed!"
```
