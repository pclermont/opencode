---
name: secret-safe-diagnostics
description: 'Collects diagnostic evidence while minimizing access to, disclosure of, and persistence of secrets. Use when diagnosing configuration, auth, connectivity, or test failures, logs, or environment questions where evidence may contain credentials, tokens, cookies, auth headers, API keys, private URLs, connection strings, or env vars: "auth is failing", "is my API key set", "why can''t it connect", "inspect this config/URL/log". Prefers config structure, key names, presence checks, permissions, and sanitized errors over raw values; screens planned commands for exposure first; no env or credential-file dumps; sanitizes at the source since post-hoc redaction cannot undo transcript capture. On exposure: stop propagation, name credential type/location, never repeat the value, recommend rotation. Not for config edits (safe-config-change), verifying changes (change-verification), repo orientation (project-orientation), bug reports (bug-report-draft), or opencode config (customize-opencode).'
---

# Secret-safe diagnostics

Investigate failures while minimizing how much secret material is accessed,
disclosed into model context or the session transcript, or persisted to disk.
This skill grants no permissions: normal tool permissions gate every step, and
steps marked [APPROVAL] additionally require explicit user approval before
running. Loading this skill is not authorization to execute it.

## Scope

Use when a diagnostic question touches configuration, authentication, provider
connectivity, test output, logs, or environment setup, and the plausible
evidence could contain credentials, tokens, cookies, Authorization/Cookie
headers, API or provider keys, private or signed URLs, connection strings, or
environment-variable values. Also use before running any diagnostic command
whose output might embed secrets.

Do NOT use when:
- Making a config change: safe-config-change owns third-party change workflows;
  customize-opencode owns opencode's own config. Hand off before any write.
- Verifying a change already made: change-verification owns running checks.
- Orienting in an unfamiliar repo without a secret angle: project-orientation.
- Evidence is already collected and only needs write-up: bug-report-draft
  (sanitizes supplied evidence) or implementation-handoff (briefs). This skill
  owns evidence *collection*, not write-up.
- opencode itself is broken or skills will not load: opencode-maintainer.

## Core principles

1. Sanitize at the source. Narrow the command so a secret never enters the
   result. Post-hoc redaction of printed output cannot undo transcript capture
   of the raw tool result.
2. No bulk dumps: never unscoped `env`/`printenv`, `set`, or full reads of
   credential, keystore, cookie, or session files.
3. Treat as potentially sensitive: log files, URLs (embedded credentials,
   signed/SAS URLs), request and response headers, command-line arguments
   (visible in shell history, `ps`, CI logs), stack traces and error payloads,
   connection strings, environment variables.
4. Prefer presence, names, and structure over values. "Set, in file X,
   mode 600, named FOO_API_KEY" usually beats the key itself.
5. Never claim redaction is guaranteed or complete; it is best-effort
   mitigation with residual risk.
6. Demonstrate and test with obviously fake values only.

## Procedure

1. State the diagnostic question in one sentence. List the minimum evidence
   that could change the answer; drop "while we're at it" items.
2. Pick the least sensitive evidence tier that can answer:
   - Tier 1 (preferred): config structure and key names; variable presence
     checks; file paths, permissions, ownership; config-source precedence;
     sanitized error class and status code.
   - Tier 2: sanitized excerpts, narrowed to specific lines or fields, with
     values masked before output.
   - Tier 3 (last resort) [APPROVAL]: scoped raw-value access, only when
     Tiers 1-2 cannot answer; even then prefer out-of-band confirmation.
3. Pre-screen every planned command: would its stdout/stderr, file contents,
   URL, headers, arguments, or inherited environment put a secret into the
   result? Narrow it if so. [APPROVAL] is required before: reading files
   likely to contain secrets (name the paths), touching credential stores,
   and any external or authenticated operation. Approval for one material
   does not extend to others.
4. Classify each step as local inspection or external operation. API calls,
   provider status checks, or requests carrying auth also disclose data to
   third parties and create access-log entries: always [APPROVAL], always
   marked in the plan.
5. Execute narrowly. Safe probes verified on this install (bash + GNU sed)
   with fake inputs only; re-verify before relying on them:
   - Presence without value:
     `[ -n "${VAR+x}" ] && echo set || echo unset`
   - Variable names only, never values:
     `printenv | sed -n 's/=.*//p' | grep -iE 'key|token|secret|password'`
   - Strip credentials embedded in URLs:
     pipe through `sed -E 's#(://)[^@/]*@#\1[credentials-redacted]@#'`
   - Mask auth/cookie headers:
     `sed -E 's/((Authorization|Cookie): ).*/\1[redacted]/I'`
   These cover known shapes only; treat unknown formats as sensitive.
6. If a safe in-band check is impossible, prefer out-of-band: the user runs
   the command themselves and pastes a sanitized excerpt. Never pull a raw
   value into the session to close a gap.
7. Minimize persistence: keep findings in the conversation. Writing evidence
   to a file is a separate [APPROVAL] and must contain sanitized forms only.
   The transcript itself may still contain raw tool output regardless of what
   the final report shows.

## If a secret appears unexpectedly

- Stop further propagation; do not repeat the value anywhere, including in
  follow-up commands or arguments (arguments leak via history, `ps`, CI).
- Identify credential type and location (file path, field or line, token
  prefix if it names the type) without revealing the value.
- Recommend: revoke or rotate, review the service's access logs, and check
  for persistence elsewhere (shell history, log files, CI output, transcript).
- Never revoke, rotate, or delete evidence or logs yourself without explicit
  approval [APPROVAL]; recommend instead.

## Failure handling

- Safe evidence unavailable: report the limitation and what was established
  without the value (presence, permissions, structure); propose out-of-band.
- Access or approval refused: mark the check not-run; state what stays
  unproven.
- Unsure whether a value is a real credential or a placeholder: treat as real.
- A required authenticated call is refused: state that the result cannot be
  established safely and list what is known without it.

## Output format

Report exactly these sections:
- Diagnostic question
- Sanitized evidence
- Checks performed
- Unresolved issues
- Exposure requiring user action ("None observed" if none)

## Completion criteria

The question is answered at the least sensitive tier that suffices; no raw
secret is repeated or persisted; any exposure is reported with recommended
actions but not acted on without approval; every external or raw-value step
is either approved-and-run or recorded as not-run.
