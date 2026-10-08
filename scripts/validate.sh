#!/usr/bin/env bash
# Validates the deployed application stack against requirements 8.3, 8.4, 8.5.
# Usage: ./scripts/validate.sh [hostname]
#   hostname: optional override; defaults to the 'application_hostname' Terraform output

set -euo pipefail

# ── Resolve hostname ──────────────────────────────────────────────────────────
if [[ $# -ge 1 ]]; then
  HOSTNAME="$1"
else
  echo "Fetching application_hostname from Terraform outputs..."
  HOSTNAME=$(terraform -chdir="$(dirname "$0")/../terraform" output -raw application_hostname 2>/dev/null)
fi

if [[ -z "$HOSTNAME" ]]; then
  echo "ERROR: Could not determine application hostname." >&2
  echo "       Run from inside the repo, or pass the hostname as an argument." >&2
  exit 1
fi

BASE_URL="http://${HOSTNAME}"
PASS=0
FAIL=0

# ── Helper ────────────────────────────────────────────────────────────────────
check() {
  local label="$1"
  local url="$2"
  local expected_body="$3"
  local expected_status="${4:-200}"

  echo -n "  ${label} ... "

  local response
  response=$(curl --silent --max-time 10 --write-out "\n%{http_code}" "${url}")
  local http_status
  http_status=$(echo "$response" | tail -n1)
  local body
  body=$(echo "$response" | head -n-1)

  if [[ "$http_status" != "$expected_status" ]]; then
    echo "FAIL (HTTP ${http_status}, expected ${expected_status})"
    echo "       Body: ${body}"
    FAIL=$((FAIL + 1))
    return
  fi

  if [[ "$body" != *"$expected_body"* ]]; then
    echo "FAIL (unexpected body)"
    echo "       Expected to contain: ${expected_body}"
    echo "       Got:                 ${body}"
    FAIL=$((FAIL + 1))
    return
  fi

  echo "OK"
  PASS=$((PASS + 1))
}

# ── Tests ─────────────────────────────────────────────────────────────────────
echo ""
echo "Validating ${BASE_URL}"
echo "────────────────────────────────────────"

# Requirement 7.2 — GET / returns expected greeting
check "GET /" "${BASE_URL}/" "Hello from Azure Kubernetes"

# Requirement 7.3 / 7.4 / 7.5 — GET /health returns valid JSON health payload
check "GET /health (application)" "${BASE_URL}/health" '"application": "healthy"'
check "GET /health (database)"   "${BASE_URL}/health" '"database":'

# ── Summary ───────────────────────────────────────────────────────────────────
echo "────────────────────────────────────────"
echo "Results: ${PASS} passed, ${FAIL} failed"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
