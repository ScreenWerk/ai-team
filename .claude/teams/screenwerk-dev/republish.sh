#!/usr/bin/env bash
set -euo pipefail

# republish.sh — Trigger a republish for a screen group in Entu
#
# Usage: republish.sh [screen_group_eid]
#
# Defaults to Bilietai RIMI screen group if no argument given.
# Reads current ispublished._id before setting to avoid stacking properties.
#
# (*SW:Lumiere*)

source ~/.env

SCREEN_GROUP="${1:-5541ec724ecca5c17a5992dc}"
ENTU_URL="https://entu.app/api"
ACCOUNT="piletilevi"

# Get JWT token
JWT=$(curl -s "$ENTU_URL/auth?account=$ACCOUNT" \
  -H "Authorization: Bearer $ENTU_API_TOKEN" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")

# Read current ispublished property _id
PROP_ID=$(curl -s "$ENTU_URL/$ACCOUNT/entity/$SCREEN_GROUP?props=ispublished" \
  -H "Authorization: Bearer $JWT" \
  | python3 -c "
import json, sys
entity = json.load(sys.stdin)['entity']
props = entity.get('ispublished', [])
if props:
    print(props[0]['_id'])
else:
    print('')
")

if [ -z "$PROP_ID" ]; then
  echo "ERROR: No ispublished property found on screen group $SCREEN_GROUP" >&2
  exit 1
fi

# Set ispublished to true using the correct _id
curl -s -X POST "$ENTU_URL/$ACCOUNT/entity/$SCREEN_GROUP" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d "[{\"_id\": \"$PROP_ID\", \"type\": \"ispublished\", \"boolean\": true}]" \
  | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin), indent=2))"

echo "Republish triggered for screen group $SCREEN_GROUP (property $PROP_ID set to true)"
