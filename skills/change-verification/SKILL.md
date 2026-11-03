---
name: change-verification
description: "Chooses and runs proportionate verification for a change already made and reports honestly what passed and what did not. Use when the user says: verify this change, run the tests, did this break anything, confirm the fix works, check before commit, is this safe to commit, ready for review, does this meet the acceptance criteria, or after edits, or after updating tests, dependencies, or configuration. Maps changed behavior and plausible regressions to focused tests and static checks, screens commands for side effects (auto-fix like lint --fix, generated files, services, secrets, costs), gets approval before risky commands, runs focused checks first, separates change-related from pre-existing or environmental failures, inspects the final diff, preserves user changes, and never weakens checks to force a pass. Not for repo orientation before changes (project-orientation), opencode config content (customize-opencode), and broken opencode installs (opencode-maintainer)."
---

# Change Verification

Verification is proportionate: choose the cheapest checks that can actually
catch a failure of the intended behavior, run them, and report exactly what
was and was not proven. This skill is guidance only: loading it grants no
permissions, and its instructions authorize nothing by themselves. The
invoking agent's tool permissions and approval flow gate every step,
including read-only checks.

## Use this skill when

- A concrete change exists (edits, a diff, or a change the user describes)
  and its effects must be confirmed.
- Triggers: "verify this change", "run the tests", "did this break
  anything", "confirm the fix works", "check before commit", "is this safe
  to commit", "is this ready for review", "does this meet the acceptance
  criteria", the agent has just edited code and must confirm results before
  claiming success, or verification after updates to tests, dependencies,
  or configuration.

## Do NOT use this skill when

- No change exists yet and the repository is unfamiliar: use
  project-orientation first (read-only discovery); verification follows
  orientation, it does not replace it.
- The target is opencode's own configuration (`opencode.json`,
  `.opencode/`, `~/.config/opencode/`, agents, skills, plugins, MCP
  servers, permission rules): customize-opencode owns that work and its
  validation steps (schema check against
  `https://opencode.ai/config.json`, quit-and-restart confirmation). Do not
  load this skill in its place.
- A third-party config change is still being applied: safe-config-change
  owns in-flight config changes and hands verification of the applied
  change back to this skill.
- The task is implementing or fixing the change: this skill starts after a
  change is made; fixing failures it finds is a separate approved task.
- The failure should only be written up as a report: bug-report-draft owns
  report drafting; this skill owns running checks.
- opencode itself will not start or config will not load:
  opencode-maintainer owns that.

## Ground rules (non-negotiable)

- Loading this skill grants no permissions; its instructions authorize
  nothing. Normal tool permissions and the invoking agent's approval flow
  gate every step, including read-only checks.
- Verification is not repair: running checks never authorizes edits to
  production code, dependency installs, or configuration changes.
- Never claim lint, tests, or builds passed without having executed the
  relevant checks in this session. A zero exit code is not proof that
  meaningful checks ran: inspect the output ("no tests ran", "0 tests
  collected", skip-by-default suites are evidence gaps).
- Never equate a passing test suite with proof of complete correctness:
  passing checks prove only what those checks cover.
- Never weaken assertions, skip failing tests, alter snapshots, rewrite
  checks, or edit unrelated code to obtain a passing result. If a check
  fails, report the failure.
- Never reset, stash, clean, switch revisions, or overwrite pre-existing
  user changes without explicit approval.
- If a check cannot be run safely or its approval was refused, report the
  blocker; never substitute an unapproved test against a live system.

## Procedure

1. Intended behavior, acceptance criteria, scope. State in 1-3 lines what
   should now be true because of the change, and what is out of scope.
   Record acceptance criteria if provided (user, ticket, spec); otherwise
   write "not provided". This defines what the checks must cover.
2. Instructions and diff. Read applicable project instructions (AGENTS.md
   or equivalent). Inspect the actual change (file list, diff) to confirm
   scope, and report if it does not match the described change.
3. Pre-existing user changes. List working-tree changes unrelated to the
   task under verification (VCS status). Treat them as the user's work:
   never revert, stash, or overwrite them without approval, and never
   attribute their effects to the change under verification.
4. Discover the tooling. Find verification tools and commands from actual
   files: package scripts, Makefile, CI configs, test directories, linter
   and type-checker config. Never assume commands.
5. Map the change to checks. For each changed behavior and each plausible
   regression, identify the focused test(s) covering it plus relevant
   static checks (type-check, lint, build), integration tests, and manual
   checks the user approved. Select only the checks the change justifies;
   do not run every category automatically. Flag behaviors with no test
   coverage instead of pretending it exists.
6. Screen commands, propose, approve. Present the proportionate plan.
   Classify each command's side effects: read-only versus state-changing,
   costly, or data-disclosing. Watch for silent rewriters (`lint --fix`,
   `--write`, formatter modes), generated or cached files, dependency
   installs, databases or live services, required secrets, email,
   deploys, paid APIs. Prefer the non-mutating form of a check (e.g.
   `--check` instead of `--fix`). Obtain explicit user approval before
   running any state-changing, costly, or disclosing command, and prefer
   isolated or reversible forms where available.
7. Run focused first. Run the checks mapped in step 5 first. Expand
   (broader suite, integration, E2E, manual verification) only when
   justified: shared or risky code paths, weak focus coverage, or a
   failure to reproduce. Track every command as planned, executed,
   passed, failed, blocked, or not-run.
8. Verify evidence, not exit codes. Confirm from output that meaningful
   work happened (test counts, test names). Treat "no tests ran", "0
   tests collected", and skip-by-default suites as evidence gaps, not
   passes.
9. Bug fixes: regression evidence. When verifying a bug fix, determine
   whether a regression test reproducing the original failure exists.
   "It failed before the fix" requires actually running it against the
   pre-fix code in an approved, safe way; without that evidence report
   "not confirmed", never "was failing".
10. Classify failures. Attribute each failure to (a) the change, (b) a
    suspected pre-existing failure, or (c) an environmental blocker
    (missing deps, toolchain mismatch, no network, absent secrets), and
    investigate enough to distinguish the three. A pre-existing
    attribution requires evidence, e.g. running the same check on an
    unmodified baseline (stashed diff or fresh checkout) -
    approval-gated, because stashing touches the working tree. Never
    rerun until green and report only the pass.
11. Final state inspection (when approvals allow). Inspect the final
    working-tree state and diff for accidental or unrelated changes:
    stray debug output, formatting churn, weakened assertions, touched
    secret files, or files a step-6 auto-fix mode silently rewrote.
    Address only unintended changes, and only with approval - reporting
    is not fixing.
12. Stop proportionately. Stop when remaining risk is acceptable for the
    request, or when further checks need approvals or access not
    granted. State which risk remains unverified.

## Output format

Findings stay in the conversation; saving a report to a file is a
separately approved action. Keep the report concise for small changes.
Report sections:

- Intended behavior and scope: the claim the checks test, and the
  acceptance criteria (or "not provided").
- Checks selected and why: each mapped to the changed behavior or
  plausible regression.
- Exact commands actually executed: verbatim, each labeled passed /
  failed / blocked / not-run.
- Actual results and evidence: what the output showed, including test
  counts and partial signals.
- Checks not run and why: skipped, blocked, too costly, not approved.
- Final diff observations: only if step 11 was approved and performed;
  otherwise state that it was not.
- Remaining risks and verification gaps: what no executed check covers.

## Failure handling

- No test infrastructure: say so; use static checks, builds, and targeted
  manual verification; propose adding tests as a separate approved task.
- Flaky check: rerun at most once, then report the flakiness with both
  results instead of cherry-picking the pass.
- No VCS: state that final-state inspection (step 11) and baseline
  comparison (step 10) were impossible.
- Ambiguous scope: ask one targeted question before running anything
  state-changing.
- Blocked or unapproved check: report the blocker with its
  blocked/not-run label; do not substitute a riskier check.

## Completion checks

- Every "passed" claim corresponds to a command actually executed and
  quoted in the report, with output inspected - an exit code alone is
  never cited as proof.
- Every planned command is labeled executed, passed, failed, blocked, or
  not-run; none silently disappeared from the plan.
- Nothing that writes, costs, or discloses ran without recorded
  approval; no check was weakened and no unrelated file, snapshot, or
  user change was touched to make it pass.
- Failures are attributed (change / pre-existing / environmental) or
  explicitly marked unattributed; "pre-existing" and "failed before the
  fix" claims carry baseline evidence, or are marked unverified.
- The report lists unrun checks and remaining risk without claiming more
  than was proven.
