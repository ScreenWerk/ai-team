#!/usr/bin/env bash
set -euo pipefail

# pre-merge.sh — Update version.ts with current PR number before merge
# Run from player/ directory before merging any PR.
#
# (*SW:Lumiere*)

PLAYER_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../player" && pwd)}"
VERSION_FILE="$PLAYER_DIR/app/version.ts"

# Get PR number for current branch
PR_NUMBER=$(cd "$PLAYER_DIR" && gh pr view --json number -q .number 2>/dev/null || echo "")

if [[ -z "$PR_NUMBER" ]]; then
    echo "ERROR: No PR found for current branch. Are you on a feature branch with an open PR?" >&2
    exit 1
fi

# Read current value
CURRENT=$(grep -oP 'BUILD_PR = \K[0-9]+' "$VERSION_FILE" 2>/dev/null || echo "0")

if [[ "$CURRENT" == "$PR_NUMBER" ]]; then
    echo "version.ts already has PR #$PR_NUMBER — no change needed."
    exit 0
fi

# Update version.ts
cat > "$VERSION_FILE" << VEOF
// Updated automatically by the pre-merge script before each PR merge.
export const BUILD_PR = $PR_NUMBER
VEOF

echo "Updated version.ts: BUILD_PR = $PR_NUMBER (was $CURRENT)"

# Commit the change
cd "$PLAYER_DIR"
git add app/version.ts
git commit -m "chore: update BUILD_PR to #$PR_NUMBER

(*SW:Lumiere*)"

# Push to update the PR
git push

echo "Committed and pushed BUILD_PR = $PR_NUMBER"
