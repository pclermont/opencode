---
name: config-portability-check
description: "Audits an OpenCode agents/skills/support-files collection for reproducibility on another machine without leaking secrets, losing required files, or silently changing behavior. Use for: publish my config to a remote repo, move config to another desktop, portability check, copied agents or skills behave differently elsewhere, after adding machine-specific dependencies. Flags hardcoded paths, hostnames, endpoints, executables, OS assumptions, required CLIs; checks tracked-vs-excluded files and session/credential separation; separates declared from verified requirements; treats existence, discovery, loadability, behavior as separate claims. Never reads, prints, copies, or tests real secret values; flags unsafe patterns by name and location only. Read-only; loading grants no permissions. Not for: opencode config edits (customize-opencode), third-party edits (safe-config-change), verifying changes (change-verification), repo orientation (project-orientation), credential debugging (secret-safe-diagnostics)."
---

# config-portability-check

Audits OpenCode agents, skills, and supporting files for safe reproduction on
another machine. Read-only: loading this skill grants no permissions; normal
tool permissions still gate every step.

## Use this skill when
- Publishing OpenCode configuration to a remote repository.
- Moving config to another desktop/machine or setting up a new machine
  ("reproduce my setup").
- The user asks for a "config portability check".
- A copied agent or skill behaves differently on another machine.
- Machine-specific dependencies or integrations were recently added.

## Do NOT use this skill when
- Editing opencode's own config content: use customize-opencode.
- Fixing third-party tool settings: use safe-config-change.
- Verifying a change already made: use change-verification.
- Orienting in an application repo: use project-orientation.
- Debugging live credential/auth failures: use secret-safe-diagnostics.
- Diagnosing a broken install or skill-loading failure: use
  opencode-maintainer.

## Ground rules
- Proposal-only: never modify files, install software, authenticate to
  services, retrieve Vault secrets, run Terraform, create commits, or push.
- Commands beyond plain static reads (git queries, env probes, anything
  touching live services or state) are marked [APPROVAL] and require
  explicit user approval before running.
- Never read, print, copy, or test real secret values. Identify secret-ish
  variables, paths, and patterns by metadata only (names, presence,
  counts). Endpoints, namespaces, and infrastructure identifiers are
  potentially sensitive too.
- File existence, discovery, loadability, and intended behavior are
  separate claims; one never proves another.
- Destination-machine checks are "not performed" unless actually executed
  there. Never report them as passing.
- Preserve legitimate machine-specific settings; propose minimal corrections
  only.

## Procedure

1. Establish scope.
   - Identify config roots (e.g. ~/.config/opencode, project .opencode/)
     and tool version via `opencode --version`.
   - List every scanned skill location for name collisions (global and
     project: .opencode/skills, .claude/skills, .agents/skills).
   - Record the destination environment if given; else list it as unknown.

2. Inventory the tree (static reads).
   - Agents, skills, SKILL.md files, supporting files, plugins, MCP servers.
   - Symlinks: find <root> -path '*/.git' -prune -o -type l -printf '%p -> %l\n'
   - Broken links: find <root> -path '*/.git' -prune -o -xtype l -print
   - Exec bits: find <root> -path '*/.git' -prune -o -type f -perm -u+x -print

3. Scan for machine coupling.
   - Machine-specific strings, file names only, no content dumps:
     grep -rlE '/home/|/Users/|C:\\Users|localhost|127\.0\.0\.1' <root> --exclude-dir=.git
   - Endpoint references as per-file counts, never values:
     grep -rEc 'https?://' <root> --exclude-dir=.git
   - Referenced executables: for each referenced command, probe presence
     with `command -v <cmd>`; record installed / not-installed / unknown.
     Never install anything.
   - Required env vars by name only: presence probes (${VAR+x}); names and
     set/unset only, never values.
   - Git tracking, only if the config root is a repo. [APPROVAL]
     git ls-files; git status --porcelain=v1 --ignored=matching;
     git ls-files --others --exclude-standard; git check-ignore -v <path>.
     Tracked-vs-ignored decides what actually reaches a remote repo. Never
     propose committing ignored files that would carry credentials.

4. Separate categories.
   - Declared requirements (frontmatter, instructions, named tools) vs
     verified installed dependencies (presence probes).
   - Portable definitions vs non-portable state: session history/storage
     (location varies; identify from the documented data dir, never assume
     a path), credentials, caches, runtime data, installed dependencies.

5. Discovery and access checks (static only).
   - Per skill: folder name == frontmatter name; name matches
     ^[a-z0-9]+(-[a-z0-9]+)*$; description present; name unique across all
     scanned locations.
   - Loadability and behavior cannot be proven statically; say so and
     require the fresh-session smoke test.

6. Assemble the report exactly in the Output format below.

## Output format

### Scope and environments
Source roots, tool version, destination environment or "not specified".

### Portable components
Items that transfer cleanly, each with its evidence.

### Confirmed blockers with file locations
Only items proven by executed output; file path plus the evidence.

### Unverified dependencies and assumptions
Declared-but-unproven items and guessed destination behavior, clearly
labeled as such.

### Required destination-specific setup
Ordered steps: installs, auth, path fixes, then smoke tests (restart
OpenCode, confirm skills appear in the skill tool's list in a new session,
exercise one agent).

### Proposed minimal corrections
Smallest diffs, noting what must NOT change (legitimate machine-specific
settings). Proposals only; never applied.

### Validation checklist and limitations
Which checks actually ran and their results; which were not run and why;
the evidence level claimed per item (existence / discovery / loadability /
behavior).

## Failure handling
- Command fails or tool unavailable: record the real error, substitute a
  verified alternative, never fabricate output.
- Config root is not a git repo: skip tracking analysis, report unverified.
- Ambiguous coupling (a path that may be intentional): flag as assumption,
  not blocker.
- Any step that changes state, incurs cost, contacts live services, or
  discloses data: stop and request approval; if denied, mark it not-run.

## Completion checks
- Every confirmed blocker cites a file location and command evidence.
- Declared vs verified dependencies separated everywhere.
- No secret values in the report or command output.
- Destination-specific items listed as setup steps, not blockers.
- The report states exactly what was not checked and why.
