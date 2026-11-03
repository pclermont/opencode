---
name: bug-report-draft
description: 'Drafts a clear, file-worthy bug report from user-supplied symptoms, reproduction steps, logs, and diagnostics, without submitting it anywhere. Use when the user says "draft a bug report", "write up this bug", "turn these symptoms into an issue", "file-worthy report", or hands over errors, stack traces, logs, or failing behavior and asks for a written report. Structures findings into Title, Summary, Environment, Reproduction steps, Expected result, Actual result, Sanitized evidence, Impact, and Open questions; separates observed facts from suspected causes; redacts secrets and personal data; never invents missing details. Draft only: never creates issues, uploads logs, contacts services, or executes reproduction steps, and never assigns unsupported severity or claims a proven root cause, unless separately authorized. Not for checking whether a change broke anything (use change-verification) or orienting in an unfamiliar repo (use project-orientation).'
---

# Bug report draft

Turn user-supplied symptoms, reproduction steps, and diagnostic evidence into a
clear, file-worthy bug report. The deliverable is draft text shown to the user.
Loading this skill grants no tool permissions; normal permissions and approvals
still gate every action.

## Scope

Use when the user supplies symptoms, error output, logs, stack traces, or
reproduction steps and asks for a written or file-worthy bug report.

Do NOT use for: verifying whether a recent change broke anything
(change-verification), orienting in an unfamiliar repository
(project-orientation), configuring opencode (customize-opencode), or actually
filing, submitting, or transmitting a report. Filing requires separate,
explicit user approval.

## Rules that always apply

- No fabrication. Use only information the user supplied. Missing details stay
  missing: write "not provided" or a concrete open question instead of guessing
  versions, steps, timings, frequency, or environment.
- Facts versus hypotheses. Observed behavior belongs in the report body. Any
  cause, however plausible, is labeled "Suspected:" and never presented as
  proven or as the root cause.
- Severity and impact are reported only as stated or clearly supported by the
  evidence; never invent a severity or priority rating.
- Draft only. Do not create issues or tickets, post comments, upload logs,
  contact services or trackers, or execute reproduction steps or diagnostic
  commands. Those change external state and require separate explicit user
  approval; producing the draft never authorizes them.
- Redact before quoting any evidence. Never copy credentials or personal data
  into the report even though they appear in the input.

## Procedure

1. Inventory the inputs. List supplied symptoms, steps, evidence, environment
   details, and what is absent. If essential facts are missing (for example the
   observed behavior), still produce a skeleton draft with placeholders plus an
   explicit questions list; do not invent and do not stall.
2. Establish expected versus observed behavior in the user's own terms.
3. Record environment and version information when available (OS, app and
   version, browser or runtime, relevant configuration). Omit what is not
   supplied rather than assuming defaults.
4. Extract minimal reproduction steps: the shortest ordered sequence that still
   shows the defect. Merge, reorder, or drop only actions already present in
   the input; never add new steps.
5. Record frequency, impact, and workarounds only when the user stated them;
   otherwise note "not stated".
6. Sanitize evidence: keep the lines that matter (exact error text, stack
   traces, exit codes), apply the redaction list below, and replace each
   removed value with a typed placeholder such as [REDACTED-TOKEN]. If
   redaction would gut the evidence, summarize instead and note the loss under
   Open questions.
7. Separate hypotheses: move the user's theories into a "Suspected:" note;
   label them unconfirmed.
8. List open questions: the specific missing information needed to reproduce
   or assess the issue (exact versions, frequency, full error text,
   configuration, recent changes).

## Output template

Emit exactly these nine sections as Markdown:

```
## Title
<one line: component plus symptom plus condition>

## Summary
<2-4 sentences: what is broken, where, and the observed effect>

## Environment
<OS, app/version, browser or runtime, relevant config; "not provided" where unknown>

## Reproduction steps
1. <numbered, minimal, only user-supplied actions>
<frequency if stated, otherwise "not stated">

## Expected result
<what should happen, per the user or documented behavior>

## Actual result
<what happens instead: exact errors, exit codes, UI or output behavior>

## Sanitized evidence
<relevant log lines, stack traces, messages with redactions applied; note any summarization>

## Impact
<user-stated impact and workarounds only, or "not stated"; suspected causes go here labeled "Suspected:", never as proven>

## Open questions
<missing information needed to reproduce or assess the issue>
```

## Redaction list

Replace with typed placeholders ([REDACTED-PASSWORD], [REDACTED-EMAIL], ...):

- Credentials: passwords, API keys, tokens, cookies, private keys,
  Authorization or Cookie header values, connection strings.
- Personal data: emails, names, phone numbers, addresses, user IDs.
- Internal hostnames, server identifiers, and file paths containing usernames,
  where not needed to reproduce.

Preserve the surrounding context that keeps the evidence meaningful for
reproduction. When in doubt, redact and say so.

## Before delivering

Verify, and fix before presenting:

- Every stated fact traces back to user-supplied input.
- All nine sections are present.
- No credentials or personal data remain in the draft.
- Hypotheses are labeled "Suspected:"; no proven-root-cause or unsupported
  severity claims.
- Open questions enumerate what is still missing.

Deliver the draft to the user as text. Do not submit, file, or transmit it
anywhere without separate explicit approval.
