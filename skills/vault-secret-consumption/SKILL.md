---
name: vault-secret-consumption
description: "Consumes an approved Vault secret inside a consumer without exposing the raw value to agent/transcript/logs/Git. Use for: 'use this Vault secret for the deploy', 'inject the secret without showing it', 'the consumer needs the DB password'. Needs vault-safe-access context plus a reviewed non-disclosing mechanism before retrieval. No vault kv get/read into agent-visible output; -field/JSON output is not redaction; never retrieve-then-redact; no secrets in argv/scripts/reports/logs/commits; env/temp delivery not automatically safe; [APPROVAL] for retrieval and the consumer op; dynamic-engine reads (database/STS) mint credentials/leases, not side-effect-free; on exposure: never repeat the value; containment under approval; wrapper installs need separate approval; loading grants no permissions. Not for: context setup (vault-safe-access), credential diagnostics (secret-safe-diagnostics), config edits (safe-config-change), tf state hygiene (terraform-secrets-state), permission tests (permission-boundary-validation)."
---

# Vault secret consumption

Deliver an explicitly approved Vault secret to a consumer (deploy script, build
step, running process, app config loader) so the consumer receives the value
internally and the raw secret never enters agent context, the tool transcript,
logs, or Git.

## Scope

Use when:
- The user asks to use, inject, pass, or wire a Vault secret into something,
  with the explicit expectation that the value is not shown ("without showing
  it", "without printing it").
- A deploy, build, test run, or app needs a secret from an already-agreed
  Vault path.
- Someone proposes fetching a secret "just to check" it and route it into a
  file, env var, or script.

Do NOT use for:
- Establishing Vault address/namespace/auth/path context: `vault-safe-access`.
- Debugging why credentials fail or diagnosing exposure after the fact:
  `secret-safe-diagnostics`.
- Applying config fixes: `safe-config-change`.
- Terraform state/tfvars secret hygiene: `terraform-secrets-state`.
- Testing permission-rule enforcement: `permission-boundary-validation`.

This skill grants no permissions. Loading it is not authorization to run
`vault`, contact a Vault server, or modify any consumer. Normal tool
permissions still gate every step.

## Prerequisites

Before any live retrieval, all of these must hold; otherwise stop:

1. Verified Vault operating context (server address, namespace, auth method,
   exact mount/path, KV version where relevant) from `vault-safe-access` or
   equivalent. If missing, return to that skill first.
2. An explicit consumer contract: who needs which fields, for what purpose,
   in which environment, and what a sanitized success/failure looks like.
3. A reviewed non-disclosing consumption mechanism (see Procedure step 3).
   If none exists, do NOT retrieve a real secret to experiment: design and
   review a mechanism against fake data first.

## Hard rules

Never violate these, even if the user asks for speed:

- Never run `vault kv get`, `vault read`, or any read whose output lands in
  agent-visible stdout/stderr. There is no safe interactive fetch.
- `-field=<name>`, `-format=json`, templating, and piping to `redact` are NOT
  redaction: the value still enters the transcript at fetch time.
- Never retrieve first and redact after. Exposure cannot be undone; there is
  no post-hoc fix, only containment after the fact.
- Never place secret values in: command-line arguments (visible in process
  lists and history), generated scripts, skill files, reports, commits,
  config snapshots, or diagnostic logs.
- Environment-variable and temp-file delivery are delivery surfaces, not
  safety: they must be part of the reviewed mechanism, never improvised.
- Creating, editing, or installing any wrapper or injection mechanism is a
  separate approval, distinct from running an already-reviewed one.
- Steps marked [APPROVAL] below change state, contact live services, or
  handle credentials. Obtain explicit user approval before each.

## Procedure

1. Confirm prerequisites 1-2. Restate the approved path by reference only
   (mount/path/field names), never the values.
2. Enumerate exposure surfaces of the intended mechanism and review each:
   - stdout/stderr of every command, including errors;
   - shell tracing (`set -x`) and history;
   - temp files: creation, permissions, removal on failure paths;
   - child-process arguments and inherited environment;
   - logging or error reporting inside the consumer;
   - cleanup of anything the mechanism leaves behind.
3. Choose the mechanism, in this order of preference:
   a. The consumer's own native Vault integration (app-level Vault client,
      SDK, Vault Agent/injector, CI/CD secret binding). Prefer what already
      exists and is already operated by the user.
   b. An existing user-owned wrapper that performs fetch-and-deliver without
      echoing. Read it fully; verify it against the surfaces in step 2
      before running it.
   c. A new wrapper: draft it, review it, and obtain [APPROVAL] before
      writing or installing it. `references/fake-consume-demo.sh` is a
      reviewable pattern against fake data only — never an approved
      mechanism by itself.
4. [APPROVAL] live retrieval. Run only the reviewed mechanism, in a way that
   its stdout/stderr stay outside agent view (for example, the mechanism
   consumes or delivers internally and prints only a sanitized marker).
5. [APPROVAL] the authenticated consumer operation (deploy, build, test run)
   separately: it changes state, may incur cost, and touches live services.
6. Verify success from sanitized evidence only: exit codes, the consumer's
   own "connected / loaded" marker, service responses. Never confirm by
   printing the value.
7. Cleanup: revoke any issued leases, remove or zero temp files if the
   mechanism uses them, and confirm the mechanism left no artifact
   containing the value.

## Dynamic-engine caution

Reads from dynamic engines (database credentials, STS-style cloud creds,
TOTP, etc.) generate real credentials and create leases with expiry,
renewal, and revocation semantics. Such a read is never side-effect-free:
- count it as a state change requiring approval;
- record lease IDs and expiry (IDs are not secrets; values are);
- plan explicit revocation or let expiry act, and report which happened.

## If exposure happens

- Stop immediately; do not repeat, echo, or "mask-print" the value.
- State where it surfaced (transcript, log file, shell history, process
  args, committed file) and which credential type it was.
- Recommend containment: rotation at the issuer, lease revocation, history
  scrubbing limits. Get approval before any remediation action.
- Hand detailed credential diagnostics to `secret-safe-diagnostics`.

## Report (no secret values)

Finish with:
- Consumer and purpose.
- Approved path reference (mount/path/field names only).
- Mechanism used and who owns it.
- Sanitized result: what was verified, from what evidence.
- Cleanup and lease status.
- Remaining limitations, unverified surfaces, or follow-ups.

## Failure handling

- Prerequisites missing or vague → route to `vault-safe-access`; do not
  guess mounts, paths, or auth methods.
- No reviewed mechanism exists → propose one against fake data; never fetch
  a real secret to "try it".
- Consumer cannot accept injected delivery (hard-coded config path, no env
  support) → stop and present options; do not improvise plain-text writes.
- Retrieval fails → do not retry-and-print. Route to
  `secret-safe-diagnostics` for credential/connection debugging.

## Evaluation and testing

Use obviously fake placeholders only, e.g. path
`dev-kv-example/data/example-app/db-config` and value `FAKE-NOT-A-SECRET`.
Never invent realistic-looking secrets for examples. Supporting scripts in
this skill are patterns for review, not approved mechanisms.

## Completion checks

- The consumer received the needed fields and validated them without
  exposure.
- No secret value appeared in transcript, argv, scripts, files, logs, or
  commits at any point.
- Every state-changing or service-contacting step had explicit approval.
- Leases revoked or expired as reported; cleanup confirmed.
- Final report contains path references and sanitized evidence only.
