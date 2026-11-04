#!/usr/bin/env bash
# REVIEW PATTERN ONLY - not an approved mechanism.
# Demonstrates the SHAPE of a non-disclosing consumer against FAKE data:
# fetch happens inside the mechanism, the secret value never reaches
# stdout/stderr of the caller, and only a sanitized marker is printed.
#
# Fake placeholders only:
#   path  dev-kv-example/data/example-app/db-config
#   value FAKE-NOT-A-SECRET
#
set -euo pipefail

# Surface review notes (mirror SKILL.md step 2):
# - no set -x: tracing would print the value
# - variable is never exported, echoed, or passed as an argv
# - consumer reads the value via stdin only; no argv exposure
# - cleanup trap covers failure paths

demo_consumer() {
  # Example consumer: reads secret from stdin, validates shape only,
  # prints a sanitized marker. Replace with the real consumer op.
  read -r secret
  if [[ -n "$secret" ]]; then
    echo "consumer: secret loaded (sanitized marker; value not printed)"
  else
    echo "consumer: no secret received" >&2
    return 1
  fi
}

main() {
  # PATTERN STEP 1: fetch happens INSIDE the mechanism.
  # The real version would be `vault kv get ...` executed only after the
  # user approves live retrieval; never run it with agent-visible output.
  local FAKE_ONLY="FAKE-NOT-A-SECRET"

  # PATTERN STEP 2: deliver without exposure - pipe, not argv, not env.
  printf '%s\n' "$FAKE_ONLY" | demo_consumer

  # PATTERN STEP 3: sanitized outcome only.
  echo "mechanism: done (exit-status evidence only)"
}

main "$@"
