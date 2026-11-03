---
name: implementation-handoff
description: 'Drafts a self-contained implementation brief from an agreed spec, investigation, or plan. Use when the user says: "hand this off to another agent", "write an implementation brief", "summarize the plan for a developer", "prepare a handoff", "spec-to-implementation brief". Covers objective, requirements and acceptance criteria, verified files and interfaces, constraints, evidence-backed findings, assumptions and decisions, in/out of scope, suggested verification, and changes to preserve. Separates approved decisions from recommendations; keeps requirement identifiers; hypotheses never become requirements; no invented paths, APIs, or stakeholder approval. Read-only: conversation output only; no file writes, agent calls, or implementation; saving to a named path needs explicit approval. Not for authoring the spec or plan (requirements-analyst/planning), repo orientation (project-orientation), running verification (change-verification), bug reports (bug-report-draft), opencode config edits (customize-opencode).'
---

# Implementation handoff

Turn an agreed specification, investigation, or plan into a concise,
self-contained implementation brief that another agent or developer can act
on without access to this conversation. The deliverable is the brief text,
delivered in the conversation. Loading this skill grants no tool
permissions; normal permissions and approvals still gate every action.

## Scope

Use when a specification, investigation, or plan already exists and the user
asks to package it for someone else: "hand this off to another agent",
"write an implementation brief", "summarize the plan for a developer",
"prepare a handoff", "spec-to-implementation brief".

Do NOT use for: producing the specification or plan itself
(requirements-analyst or a planning task owns that), orienting in an
unfamiliar repository (project-orientation), running or designing the
execution of checks (change-verification owns running them), writing a bug
report (bug-report-draft), or editing opencode configuration
(customize-opencode). This skill transfers an existing agreement; it does
not create, implement, or verify one.

## Rules that always apply

- Approved versus recommended. Every decision is labeled "Approved:" (the
  user or stakeholders agreed to it, with that agreement present in the
  input) or "Recommended:" (a suggestion from you). Never imply stakeholder
  approval that is not evidenced in the source.
- Preserve requirement identifiers. When the source numbers or names
  requirements (REQ-3, AC-2, ticket keys), carry those identifiers through
  unchanged; do not renumber, merge, or drop them.
- Hypotheses stay hypotheses. An unconfirmed finding never becomes a
  requirement, acceptance criterion, or constraint; keep it under Findings
  or Assumptions with its label intact.
- No fabrication. Cite only file paths, interfaces, APIs, commands, and
  implementation details that were verified in this session or explicitly
  present in the supplied material. Anything else is labeled "unverified"
  or omitted.
- Conversation by default. Do not write files, create documents, invoke or
  spawn other agents, or begin implementation. The single permitted state
  change is saving the brief to a user-named path, and only after explicit
  user approval for that exact path.
- Self-containment. A reader with no access to this conversation must be
  able to act on the brief: include needed context, exclude discussion
  churn.

## Procedure

1. Identify the source and its agreement state. Determine what is being
   handed off (written spec, investigation report, plan, or this
   conversation) and which parts the user has actually confirmed versus
   left open.
2. Capture objective and requirements. State the intended outcome in one
   short paragraph. List confirmed requirements and acceptance criteria
   with their original identifiers. Anything not confirmed goes to
   Assumptions, labeled as such. If the source is thin, still produce a
   skeleton brief plus a questions list; do not invent and do not stall.
3. Collect verified references only. List files and interfaces with a
   one-line reason each, only when verified in this session or explicitly
   named in the source. Unverified references belong under Assumptions,
   labeled.
4. Record constraints and compatibility. Supported versions, toolchain
   pins, project instructions (AGENTS.md or equivalent), CI gates,
   licensing, security or performance limits - each with its source.
5. Separate findings, assumptions, and open decisions. Each finding cites
   its evidence (file path, quoted source, command output). Unresolved
   decisions are listed as questions; never resolve them silently.
6. Draw scope boundaries. State in-scope and out-of-scope work strictly
   from the agreed material; flag boundaries the source left ambiguous.
7. Suggest verification. Point to the checks the implementer should run
   (focused tests, static checks, manual steps), sourced from documented
   project tooling and labeled "documented, not run". This skill does not
   run them; change-verification owns execution.
8. Note existing user changes. When known from prior read-only inspection,
   list working-tree changes the implementer must preserve; the implementer
   must never revert, stash, or overwrite them. If unknown, say "unknown".
9. Deliver. Output the brief in the conversation. Saving to a file is an
   approval step: only on explicit user request naming the path, write the
   brief there verbatim and nothing else.

## Output template

Emit exactly these nine sections as Markdown:

```
## Objective
<what to build and the intended outcome, 1 short paragraph>

## Confirmed requirements and acceptance criteria
<numbered, each keeping its original identifier (REQ-x, AC-x, ticket);
mark anything unconfirmed as [ASSUMPTION]>

## Relevant files and interfaces
<verified paths/APIs with a one-line reason each, or "none verified">

## Constraints and compatibility
<versions, toolchain, project instructions, CI gates; each with source>

## Evidence-backed findings
<findings, each citing its evidence; hypotheses keep their labels>

## Assumptions and unresolved decisions
<unconfirmed items labeled as assumptions; open decisions as questions>

## Scope
<In scope: ... / Out of scope: ...; ambiguous boundaries flagged>

## Suggested verification
<checks for the implementer to run, labeled "documented, not run" unless
actually verified in this session>

## Existing user changes to preserve
<known working-tree changes, or "unknown / none known">
```

## Failure handling

- No agreed spec, investigation, or plan exists: do not manufacture a
  brief; say what is missing and point to requirements-analyst (spec and
  requirements) or project-orientation (repository facts).
- Conflicting requirements: report both with their sources and flag the
  conflict as an unresolved decision; never pick one silently.
- Missing acceptance criteria or identifiers: write "not provided"; never
  invent them.
- User asks to save the brief without naming a path: ask for the exact
  path before any write.

## Completion checks

- All nine sections are present and self-contained.
- Every requirement traces to the source material with its identifier
  preserved; no hypothesis appears as a requirement or constraint.
- Every decision is labeled Approved or Recommended; no implied
  stakeholder approval.
- Every cited path, API, and command was verified this session or quoted
  from the source.
- No file was written, no agent invoked, and no implementation begun
  without explicit user approval; any save matches the user-named path.
