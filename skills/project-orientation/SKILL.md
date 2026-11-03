---
name: project-orientation
description: "Builds an evidence-based understanding of an unfamiliar repository before changes are planned or made. Use for requests such as: get oriented in this repo, understand this codebase before we change it, map the project, where is the entry point, what are the build/lint/test commands, first look at an unknown repository, or before recommending an implementation. Reports the repository map, task-relevant modules, documented dev/build/lint/type-check/test commands, constraints, unknowns, and sensitive-file paths. Read-only: never modifies files, installs dependencies, runs project scripts, reads secret values, or contacts live services. Do NOT use when the target is opencode's own configuration (opencode.json, .opencode/, ~/.config/opencode/, agents, skills, plugins, MCP servers, permission rules); use customize-opencode for that."
---

# Project Orientation

Establish an evidence-based understanding of a repository before making changes
or recommending an implementation. Deliver an orientation report; implement
nothing.

## Use this skill when

- First contact with an unfamiliar repository, before any change is planned.
- The user asks to understand, map, or survey a codebase: "get oriented in
  this repo", "understand this codebase before we change it", "map the
  project", "where is the entry point?", "what are the build/test commands?".
- Before planning an implementation or recommending an approach.

## Do NOT use this skill when

- The target is opencode's own configuration (opencode.json, `.opencode/`,
  `~/.config/opencode/`, agents, skills, plugins, MCP servers, permission
  rules): the customize-opencode skill wins there, even if the user also
  says "get oriented first."
- The work is to actually implement the change: this skill ends at the
  report; implementation is a separate, approved task.
- A full audit or complete inventory was requested: focused inspection is the
  default; breadth is the exception.

## Ground rules (read-only)

- Loading this skill grants no permissions; normal tool permissions gate every
  step.
- Never modify files, install dependencies, execute project scripts or
  build/test/lint commands, read secret values, or contact live services
  merely to get oriented.
- A command found in a README, manifest, Makefile, or CI config is
  *documented*, not verified. Label it as such in the report and never run it
  to confirm.
- Sensitive files (`.env`, credentials, keys, tokens): note presence and path
  only; never open or quote their contents.

## Procedure

1. Task and boundary. Restate the requested task in one sentence. Identify the
   repository boundary (VCS root, manifests, workspace config). In a monorepo,
   scope to the part relevant to the task.
2. Instructions and docs. Read applicable project instruction files (AGENTS.md
   or equivalent), READMEs, and docs covering the task area; follow project
   instructions.
3. Stack. Identify languages, frameworks, dependency manifests, and package
   managers from actual files (manifests, lockfiles); never assume.
4. Entry points and relevant modules. Locate main/entry files, app bootstrap,
   CLI or build config; then narrow to the 3-10 files most relevant to the
   task. Skip exhaustive inventory.
5. Documented commands. Collect development, build, lint, type-check, and test
   commands from package scripts, Makefiles, docs, and CI configs; record them
   as "documented, not run."
6. Working-tree state (approval step). Run read-only VCS inspection (e.g.
   `git status`, a diff summary) only with explicit user approval. Treat any
   existing changes as the user's work: never revert, stash, clean, or
   overwrite them.
7. Constraints and unknowns. Note toolchain pins, CI gates, style/lint config,
   licensing, feature flags, and anything ambiguous; list potentially
   sensitive files (paths only).

## Output format

- Repository map: purpose, key directories, entry points.
- Relevant files for the task, each with a one-line reason.
- Documented commands (dev / build / lint / type-check / test), labeled
  "documented, not run."
- Task-specific constraints.
- Unknowns and unresolved questions.
- Sensitive files noticed (paths only).

## Failure handling

- No README/docs: infer from manifests, CI, and layout; label the inference as
  unverified.
- Conflicting sources: report both and flag as an open question; never pick
  one silently.
- Very large repo: scope to the task area and state what was not inspected.
- Unclear task: produce the minimal map and ask targeted questions before
  going deeper.
- No VCS present: skip the working-tree step and say so.

## Completion checks

- Every claim cites the file path that evidences it.
- No project commands were run and no files were modified by this skill.
- The report distinguishes documented from verified commands and lists open
  questions.
- If the report is insufficient, ask the user before proceeding to
  implementation.
