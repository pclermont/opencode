---
name: dependency-impact-review
description: "Impact analysis for a proposed change to shared OpenCode definitions: agents, skills, instruction files, permission rules, supporting scripts. Use before editing or renaming when the user asks what depends on this skill or agent, would renaming or removing it break anything, or wants impact or blast-radius evidence first. Establishes the proposed change, searches cross-references (names, output labels, permission patterns, paths), separates confirmed from possible consumers, flags compatibility and permission risks, proposes the smallest coordinated change set plus a targeted regression checklist. Read-only: modifies nothing, runs nothing, touches no secrets, contacts no services, commits nothing; states what static inspection cannot prove. Not for changes already made (change-verification), machine portability (config-portability-check), opencode config edits (customize-opencode), whole-agent evaluation (agent-evaluation), or single permission-boundary tests (permission-boundary-validation)."
---

# Dependency Impact Review

Assess the blast radius of a proposed change to a shared OpenCode definition
before the change is made. Targets: agent definitions, skills (`SKILL.md` and
support files), instruction files (AGENTS.md or config `instructions`),
permission rules, and supporting scripts. The deliverable is an impact report
plus a proposed minimal change set. Apply nothing.

## Use this skill when

- A rename, move, removal, or edit of a skill, agent, instruction file,
  permission rule, or supporting script is proposed but not yet made.
- The user asks: "what depends on this skill", "will renaming or removing it
  break anything", "impact before changing this agent", "who consumes this
  output format", "blast radius of this edit".
- A planned change touches a name, output label, path, or permission pattern
  that other definitions reference.

## Do NOT use this skill when

- The change was already made and must be checked: change-verification owns
  that; it runs checks, this skill runs nothing.
- The question is reproducibility on another machine: config-portability-check.
- The task is performing the edit itself: customize-opencode.
- Behavior must be proven empirically: agent-evaluation (whole agent) or
  permission-boundary-validation (one permission rule).
- The target is the user's application code, not OpenCode definitions.

## Ground rules (read-only)

- Loading this skill grants no permissions; normal tool permissions and user
  approvals gate every step.
- Never modify files, execute agents or skills, install dependencies, read
  secret values, contact live services, commit, or push. The proposed change
  set is a proposal; executing it requires separate explicit approval.
- Every dependency claim cites the referencing file path (and section when
  available). Never invent a reference, path, or consumer.
- Static search proves textual references only. File existence, searchability,
  loadability, selection at startup, and runtime permission enforcement are
  separate claims; label them as such.

## Procedure

1. **Establish the proposed change and scope.** Restate the target artifact,
   the exact intended edit, and what counts as "this change" versus adjacent
   work. If the proposal is ambiguous, ask targeted questions before
   searching; do not guess scope.
2. **Identify dependencies.** Search every scanned definition location
   (project and global `.opencode/`, `.claude/`, `.agents/` skill and agent
   dirs, `~/.config/opencode/`, config JSON) for cross-references:
   - skill/agent names and the `name`-equals-directory invariant;
   - "use X" / "Not for X" cross-skill mentions and agent-definition mentions;
   - instruction files and config (`instructions`, `skills.paths`,
     permission rules);
   - required output labels or section names consumed by other skills;
   - support-file paths referenced relative to a skill folder;
   - permission tool keys and pattern maps an agent relies on.
   Record each hit as path + quoted fragment. Treat files present but not
   searched as an explicit gap, not as "no references".
3. **Assess compatibility.** Classify each dependency: confirmed (explicit
   textual reference) versus possible (same literal string, plausible but
   unintended coupling; undiscoverable runtime coupling). Flag known
   failure modes: a renamed skill whose frontmatter `name` no longer matches
   its directory is not discoverable; a changed output label silently breaks
   consumers that cite it; moving a support file breaks relative-path
   references; replacing or version-bumping a shared script or dependency
   changes behavior for consumers that invoke it, even when no text changes;
   tightening a permission rule (allow to ask, ask to deny) changes consumer
   behavior even with no textual reference.
4. **Propose proportionate validation.** Produce the smallest change set that
   keeps every confirmed consumer consistent (rename directory + frontmatter
   + all mentions together, never partially), and a targeted static regression
   checklist (grep for the old name/label/path; name-directory match; YAML
   frontmatter parses). Runtime confirmation (restart, skill appears in the
   skill tool list, live permission behavior) is listed as user-side follow-up
   or routed to agent-evaluation / permission-boundary-validation, never
   performed here.

## Output format

Emit exactly these eight sections as Markdown, in this order:

```
## Proposed change and scope
<target artifact, exact intended edit, what is in and out of scope>

## Evidence-backed dependency map
<table: referencing file path | referenced element | quoted fragment>

## Confirmed affected consumers
<explicit textual references: path, what it references, what breaks>

## Possible affected consumers and uncertainty
<plausible couplings, why uncertain, what evidence would confirm or rule out>

## Compatibility and permission risks
<name-directory invariant, output-label drift, relative-path references,
shared-script or dependency replacement and its callers, permission
transitions (allow to ask, ask to deny) and their consumers>

## Smallest coordinated change set
<every edit that must move together; what deliberately stays untouched>

## Targeted regression checklist
<static checks only: grep for the old name/label/path across all scanned
locations; frontmatter name equals directory name; YAML parses. Runtime
confirmations (restart, skill appears in the skill tool list, live
permission behavior) are listed as user-side follow-up, not run here>

## Limits of the assessment
<what static inspection cannot prove; which locations were and were not
inspected; claims that remain absence-of-evidence>
```

## Worked examples

- **Renaming a referenced skill.** A skill's directory and frontmatter
  `name` change, and other skills route with "use X" or "Not for X (X)".
  Confirmed consumers: every such mention plus the skill's own
  frontmatter. Risk: a renamed skill whose `name` no longer equals its
  directory is not discoverable at all. Change set: directory rename,
  frontmatter `name`, and all mentions in one coordinated set.
  Regression: grep for every remaining use of the old name; verify name
  equals directory.
- **Changing a required output label.** A producer skill renames a required
  output section that another skill cites by name. Confirmed consumers:
  the citing skills. Risk: silent breakage — every file still loads and
  parses; only cross-references go stale. Change set: producer and all
  citing consumers must change together. Regression: grep for the old
  label in every scanned location.
- **Tightening a permission a consumer needs.** An agent's permission rules
  move a tool pattern from ask to deny, and a skill's procedure instructs
  agents to run that action. Coupling is possible, not textual: nothing
  links the two files. Risk: the skill's steps become unexecutable in that
  agent. Flag it, state that only a live test proves enforcement, and
  route runtime proof to permission-boundary-validation; never test it
  here.
- **Editorial change with no demonstrated downstream impact.** A typo or
  wording fix in a skill body. Still run the search. If no definition
  references the touched terms, report an empty dependency map and "no
  demonstrated downstream impact" — never invent risk; label the result
  as absence of evidence in the searched locations only.

## Failure handling

- No references found: report "no references found in the inspected set",
  list the inspected locations, and label it absence of evidence, not
  evidence of absence.
- Ambiguous proposal: ask targeted scope questions before searching; do
  not guess what "this change" means.
- Large or multi-location library: scope to the task-relevant area and
  state exactly what was not inspected.
- Files with existing uncommitted edits: treat as the user's work; report
  state as found; never revert, stash, or clean.
- Version-dependent behavior (discovery rules, frontmatter fields): quote
  the installed version from a read-only listing when checked, and say so
  when it cannot be verified; never invent fields or rules.

## Completion checks

- All eight output sections are present, in order.
- Every dependency-map row cites the referencing file path; confirmed and
  possible consumers are separated; uncertainty is explicit.
- The change set is minimal and complete: every confirmed consumer appears
  in it, and nothing outside the proposal is included.
- No state-changing step was executed: no edits, no runs, no installs, no
  commits, no pushes; runtime confirmations are listed only as user-side
  follow-up.
- The report states what static inspection cannot prove, and no runtime,
  selection, or enforcement claim is made without labeling it unverified.
