---
name: safe-config-change
description: "Makes configuration changes to third-party tools (apps, servers, OS settings, dotfiles other than opencode) through a minimal, reviewable, reversible workflow. Use when the user says: change this setting, update the config, fix my config, modify settings safely, adjust app, server, or OS settings, tweak dotfiles, or any config edit that must be reviewed and reversible. Establishes symptom, installed version, target scope, and config-file precedence; inspects only needed settings while protecting secret values; records a baseline; proposes the smallest exact change with risks, validation, and rollback; gets approval before backups, writes, restarts, or external requests; preserves unrelated settings; validates syntax and effective behavior; reports results and rollback need. NOT for opencode configuration files (opencode.json, .opencode/, ~/.config/opencode/, agents, skills, plugins, MCP, permissions): customize-opencode owns those. Not for verifying a change already made: use change-verification."
---

# Safe Config Change

Change configuration the way you would want it done to a system you rely
on: know what is actually in effect, change the smallest thing that could
fix the symptom, get the change approved before it lands, and prove
afterwards what happened. Keep every step reversible.

## Use this skill when

- The user wants a configuration change to third-party software: an app,
  a server, an OS or shell setting, or dotfiles that are not opencode's
  own.
- Triggers: "change this setting", "update the config", "fix my config",
  "modify settings safely", "enable/disable this feature in <tool>",
  "adjust nginx/ssh/shell settings", "tweak my dotfiles", or any config
  edit that should be reviewed before it lands and reversible after.
- A config change was requested but its blast radius is unclear: the
  baseline-and-precedence steps below are how to find out safely.

## Do NOT use this skill when

- The target is opencode's own configuration (`opencode.json`,
  `.opencode/`, `~/.config/opencode/`, agents, skills, plugins, MCP
  servers, permission rules): customize-opencode owns that work, even if
  the user says "change this setting". Do not load this skill in its
  place.
- The change was already made and only needs confirming: use
  change-verification. This skill owns the change workflow; its
  validation step covers only changes made within it.
- No change is wanted, only understanding a repository: use
  project-orientation.
- opencode itself will not start or its config will not load:
  opencode-maintainer owns that.

## Ground rules (non-negotiable)

- Loading this skill grants no permissions; normal tool permissions gate
  every step, including reads of config files.
- Never disable security controls or broaden permissions just to bypass
  an error. If a permission or policy blocks the desired change, report
  it and discuss the tradeoff; do not route around it.
- Never upgrade software, install dependencies, change network exposure
  (ports, bind addresses, firewall rules), delete files, or contact paid
  services without explicit approval for that specific action.
- Treat backups as potentially sensitive: they contain the same secrets
  as the originals. Store them outside shared or exported locations
  unless approved, and record where they went.
- Never print secret values. Record key names and whether a value is
  set; mask the value itself.
- Do not roll back automatically when a rollback would overwrite user
  changes made after the baseline; propose the rollback instead.

## Procedure

1. Frame the change. State the symptom, the desired outcome, the
   installed version of the tool being configured (check it with a
   read-only version command), and the target scope: which tool, and
   user-level, project-level, or system-level config.
2. Find the sources and verify precedence. Enumerate candidate config
   sources from the tool's documented locations. Establish which source
   actually wins by evidence (docs, man page, help output, the tool's
   own debug/verbose mode), never by assumption. State the winning
   source before proposing anything.
3. Inspect only what the change needs. Read only the settings relevant
   to the symptom and the change. Protect secret values per the ground
   rules: key names and presence, never values.
4. Baseline and smallest correction. Record the current effective
   values of everything the change would touch; this baseline is the
   rollback point and the way to detect newer user edits. Identify the
   smallest change that could plausibly address the symptom; drop
   incidental "while we are here" edits.
5. Present the proposal. Before touching anything, show: affected files
   (exact absolute paths), the exact change per file (before/after
   lines), risks, the validation plan (which checks, and which of them
   change state), and the rollback plan (backup location and restore
   procedure).
6. Get approval. Obtain explicit user approval before any backup, file
   write, service restart, or external request. Approval covers the
   proposal as shown; if anything must differ during application, stop
   and re-propose.
7. Preserve everything unrelated. Touch only the approved keys or
   lines; keep comments, ordering, formatting, includes, and user
   customizations. Prefer targeted edits over rewriting whole files.
   Take the backup of the exact original file(s) first, at the approved
   location.
8. Apply only approved changes. Make the edit exactly as proposed. No
   additional, convenience, or speculative changes.
9. Validate. Check syntax with the tool's own validation or dry-run
   facility when it has one (for example a config-test flag, or a
   parser matching the file format); when none exists, say so and use
   the next-best approved check. Confirm effective behavior with the
   checks approved in step 5; restart services only if that plan
   covered it.
10. Report and decide on rollback. State what changed, which checks
    passed or failed, and whether rollback is needed. Roll back only
    when approved, comparing against the step-4 baseline first: if the
    user edited the file since, do not restore over their work -
    propose a merge instead.

## Output format

Proposal (step 5, conversation only - no files touched yet):
- Affected files: exact absolute paths.
- Exact changes: before/after per file.
- Risks and side effects: restarts, exposure, cost, secrets touched.
- Validation plan: exact checks, marked read-only or state-changing.
- Rollback plan: backup location and restore procedure.

Final report (step 10):
- What changed, checked against the baseline.
- Validation commands actually run, each pass / fail / not run.
- Whether the symptom is resolved, and by what evidence.
- Rollback status: not needed / performed / recommended, with reason.

## Failure handling

- Precedence unclear or sources conflict: ask one targeted question or
  run a read-only probe (debug/verbose mode) before writing; never
  guess the winning file.
- No syntax-check facility in the tool: say so; validate with a parser
  matching the format when possible, otherwise flag the change as
  format-unvalidated.
- Restart or re-login required for the change to take effect: state it,
  get approval, defer behavioral validation until after it happens.
- Symptom persists after the applied change: stop and report; revert
  only with approval; do not stack further speculative edits.
- Config file unreadable or owned by another user: report the blocker;
  do not escalate privileges or change ownership/mode without approval.

## Completion checks

- Every write, backup, restart, and external request had recorded
  approval; nothing outside the approved proposal was changed.
- A diff against the baseline shows only the approved lines changed;
  unrelated settings, comments, and customizations are intact.
- No secret values were printed, and backups sit where they were
  approved to sit.
- Any rollback was approved and did not overwrite newer user edits.
- The report separates validated behavior from assumed behavior.
