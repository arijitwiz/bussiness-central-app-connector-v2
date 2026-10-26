#!/usr/bin/env bash
# Deploy WizCommerce BC extension v1.2.0.0 to the Sandbox environment.
#
# Usage:
#   BC_CLIENT_SECRET="<secret>" ./scripts/deploy_to_sandbox.sh
#
# Env vars (required):
#   BC_CLIENT_SECRET  — Azure app registration secret for client_id below
#
# Hard-coded sandbox coordinates (from Postman environment):
#   tenant_id  : aaf26c70-a831-4c8b-a0ad-35e35f29f7af
#   client_id  : 8d1dd517-7ef8-4436-9989-3fd511269aca
#   environment: Sandbox
#
# The script:
#   1. Gets an access token via client_credentials
#   2. Uploads the .app via the BC Admin API /extensions endpoint
#   3. Polls until the extension state is Installed
#
set -euo pipefail

TENANT_ID="aaf26c70-a831-4c8b-a0ad-35e35f29f7af"
CLIENT_ID="8d1dd517-7ef8-4436-9989-3fd511269aca"
ENVIRONMENT="Sandbox"
APP_FILE="$(dirname "$0")/../WizCommerce_BusinessCentralConnector_1.2.0.0.app"

if [[ -z "${BC_CLIENT_SECRET:-}" ]]; then
  echo "Error: BC_CLIENT_SECRET is not set." >&2
  exit 1
fi

if [[ ! -f "$APP_FILE" ]]; then
  echo "Error: .app file not found at $APP_FILE" >&2
  echo "Run: cp /private/tmp/claude-501/.../scratchpad/v110_fresh.app $APP_FILE" >&2
  exit 1
fi

echo "==> Obtaining access token..."
TOKEN_RESP=$(curl -sS -X POST \
  "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${BC_CLIENT_SECRET}" \
  -d "scope=https://api.businesscentral.dynamics.com/.default")

ACCESS_TOKEN=$(echo "$TOKEN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)
if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "Error: Failed to obtain access token." >&2
  echo "$TOKEN_RESP" >&2
  exit 1
fi
echo "    OK — token obtained."

ADMIN_BASE="https://api.businesscentral.dynamics.com/admin/v2.21"

echo "==> Uploading extension to ${ENVIRONMENT}..."
UPLOAD_RESP=$(curl -sS -X POST \
  "${ADMIN_BASE}/applications/businesscentral/environments/${ENVIRONMENT}/apps/upload" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@${APP_FILE}")

echo "    Upload response: $UPLOAD_RESP"

# Extract operation id from response
OP_ID=$(echo "$UPLOAD_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)
if [[ -z "$OP_ID" ]]; then
  echo "Upload may have failed — check response above." >&2
  exit 1
fi

echo "==> Polling deployment status (operation id: $OP_ID)..."
for i in $(seq 1 20); do
  sleep 10
  STATUS_RESP=$(curl -sS \
    "${ADMIN_BASE}/applications/businesscentral/environments/${ENVIRONMENT}/apps/${OP_ID}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}")
  STATE=$(echo "$STATUS_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null)
  echo "    attempt $i: state=$STATE"
  if [[ "$STATE" == "Installed" || "$STATE" == "Succeeded" ]]; then
    echo "==> Extension installed successfully."
    exit 0
  elif [[ "$STATE" == "Failed" || "$STATE" == "Error" ]]; then
    echo "==> Installation failed:" >&2
    echo "$STATUS_RESP" >&2
    exit 1
  fi
done

echo "==> Timed out waiting for installation. Check BC Admin Center manually." >&2
exit 1
