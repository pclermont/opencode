# Evidence Log - <target> / <run id, date>

Fields align with
`permission-boundary-validation/references/case-matrix-template.md`: that
matrix's columns (requested action, permission decision, approval-request
id, user resolution, execution result, observed side effects) are a
permission-specific subset of the row below. For a permission-boundary
run, fill the permission columns in that matrix and cross-reference this
log - never keep two contradicting logs for one run.

## Run conditions (complete before the first case)

| Field | Value |
|---|---|
| Target (agent or skill; version / mtime / VCS state) | |
| Conditions snapshot (mode, model, tools, permissions, skills) | |
| Capturing artifact per case (transcript path or tool-output path) | |
| Sensitive-output scan done before capture? | yes / no |
| Pre-registered expectations recorded where? (owned by the evaluation workflow) | |

## Evidence (one row per case, filled during the run)

| Case | Requested action | Approval requested? | Approval resolution + source | Execution result | Observed side effects | Sanitization applied | Evidence reference (transcript line / file:line / tool-output path) | Tail complete? | Result (pass / fail / blocked / inconclusive / not-run) | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |  |  |  |

Field rules:
- "Approval resolution": approve / deny / never-resolved / not-visible -
  plus who or what established it. `not-visible` forces `inconclusive`.
- "Sanitization applied": none needed, or the placeholder kinds used
  (`<REDACTED: type, location>`); never the secret value itself.
- "Tail complete?": yes, or no + what is missing; `no` forbids `pass`.
- Blank means "unknown - say so"; it never means "none".

## Integrity audit (complete before publishing)

| Check | ok | Note |
|---|---|---|
| Every row has a result and >=1 re-checkable reference | | |
| No silently blank required fields | | |
| Every approval request resolved, or an explicit gap note | | |
| Every capturing artifact's tail checked | | |
| No secret values anywhere, including linked artifacts | | |
| Report counts == log row counts (no dropped or invented rows) | | |

## Limitations

- (never empty after a partial run; list everything this log cannot
  support, and what would additionally be needed to call anything verified)
