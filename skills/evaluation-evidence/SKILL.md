---
name: evaluation-evidence
description: >-
  Shared evidence-capture and integrity plumbing for any OpenCode evaluation
  run (agent-evaluation, skill-tester, skill-reviewer, or ad-hoc checks). Use
  when: recording evidence during an evaluation or test run, building an
  evidence log or case matrix, choosing a result label
  (pass / fail / blocked / inconclusive / not-run), handling truncated or
  missing transcript tails, unresolved or invisible approval/ask resolutions,
  or claims with no re-checkable evidence reference; sanitizes secrets at
  capture, not post-hoc. Enforces five rules: transcript completeness,
  approval-resolution gaps, evidence references, sanitization-at-capture,
  honest classification. Does NOT do evaluation scoring
  (agent-evaluation/skill-tester own scores), test-case or scenario design,
  or permission-boundary enforcement attribution (permission-boundary-validation).
  Loading this skill grants no permissions.
---

# Evaluation Evidence

The shared evidence discipline for running any OpenCode evaluation of an
agent or skill: capture, reference, sanitize, and classify honestly what
actually happened. It does not design cases, score dimensions, or render
the final verdict - the owning skill or agent does; this skill only keeps
the evidence honest.

Loading this skill grants no permissions: normal permissions and approvals
still gate every step.

## Use when

- You are running or reporting any agent-evaluation, skill test, skill
  review, or evaluation-style check and must record what actually happened.
- A run produced a truncated transcript or missing tail, an unresolved or
  invisible approval/ask, or a claim with no pointer a reader can re-check.
- You need one shared result vocabulary and evidence-log format across
  evaluation workflows.

## Not for

- Scoring and report judgment (task accuracy, scope control, output
  usefulness, 1-5 ratings): owned by `agent-evaluation`; method
  classification (inspection / simulation / execution) and scenario
  verdicts: owned by `skill-tester`; static review findings: owned by
  `skill-reviewer`. This skill supplies their evidence inputs, never their
  conclusions.
- Case authoring, boundary-case selection, revision comparison: owned by
  the evaluation workflow, not here.
- Permission-specific enforcement attribution (self-restraint vs.
  permission-system block vs. user approval): owned by
  `permission-boundary-validation`; its case matrix is a permission-flavored
  instance of this skill's log - reuse its fields, never maintain two logs
  for one run.
- Secrets triage while diagnosing (outside an evaluation): use
  `secret-safe-diagnostics`.

## Result vocabulary (shared; use exactly these five)

`pass` / `fail` / `blocked` / `inconclusive` / `not-run`

- `pass`: the case ran, evidence is complete and referenced, and a
  pre-registered expectation was met.
- `fail`: ran with complete evidence; the expectation was not met.
- `blocked`: could not run (approval denied, fixture or config missing) -
  state the reason.
- `inconclusive`: ran or partially ran, but evidence is incomplete,
  ambiguous, or unreferencable.
- `not-run`: never started (prerequisites or approval absent).
- Never convert an unrunnable case, a missing evidence tail, an invisible
  approval resolution, or a simulation into a pass.

## Procedure

1. Bind the evidence plan before running anything (read-only): name the
   artifact that will capture each case (transcript path, tool-output file,
   evidence log) and note what is sensitive in this target's output.
2. Fill one evidence-log row per case as it happens
   (`references/evidence-log-template.md`). Evidence reconstructed from
   memory after the run is not evidence.
3. Reference every claim to a specific re-checkable artifact: transcript
   line, file:line, exact command, or tool-output path. No reference, no
   claim.
4. Treat missing evidence as a finding, never as silence:
   - Transcript truncated or tail missing: the case cannot be `pass`; mark
     it `inconclusive` and state which evidence survives.
   - Approval requested but its resolution (approve/deny, by whom) cannot
     be seen: `inconclusive`; never assume a resolution.
   - A required log field is blank: say which field is blank; a blank is
     not "none".
5. Sanitize at capture: before an evidence artifact is written or pasted,
   replace secret values with a placeholder that keeps the secret's type
   and location (e.g. `<REDACTED: API key, env EXAMPLE_TOKEN>`) - names
   and presence, never values. Post-hoc redaction cannot undo transcript
   capture.
6. Classify each case at capture time with the vocabulary above; do not
   reclassify later to tidy the report. Reruns of surprising results (a
   policy of the owning workflow) get their own rows, labeled as reruns.

## Integrity checklist (before publishing any evaluation report)

- [ ] Every case row has a result label and at least one re-checkable reference.
- [ ] Every transcript / tool-output tail checked; truncation noted.
- [ ] Every approval request has a resolution and its source, or an explicit gap note.
- [ ] No secret values in the report, the log, or any linked artifact.
- [ ] Every blocked / inconclusive / not-run row carries a reason.
- [ ] Report counts match evidence-log counts; no dropped fails or extras.

## Failure handling

- Evidence artifact lost or unreadable: affected cases are `inconclusive`;
  name what was lost; never reconstruct from memory.
- Log and transcript disagree: the transcript wins - fix the log, not the
  story.
- Sanitization would destroy usefulness: keep names, presence, and
  permissions; drop values; record the trade-off under Limitations.

## Boundaries

This skill produces or audits an evidence log. It never produces scores,
scenario designs, enforcement-source verdicts, or recommendations about
the target: those are the owning skill's or agent's job, using this log as
input.
