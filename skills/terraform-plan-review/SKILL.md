---
name: terraform-plan-review
description: >-
  Reviews an existing Terraform/OpenTofu plan (pasted text, JSON plan,
  saved -out file) into a risk-triaged review. Use when the user says:
  "review this plan", "is this plan safe", "why does this plan want to
  destroy", or pastes plan output. Establishes provenance: tool/version,
  staleness vs current state, provider/config drift. Prefers sanitized
  extracts; never requests raw state or full dumps. Builds a change
  inventory (add/change/destroy/replace/move/import/no-op); flags
  destroys, replaces, delete-before-create, drift, oversized plans,
  credential leakage, state risks; checks IAM, network exposure, storage
  retention, encryption/KMS; treats "known after apply" unknowns
  honestly; states evidence sufficiency. Read-only: NEVER runs
  plan/apply/destroy, never generates plans, never invents cost
  estimates, never guarantees apply success. Not for generating plan
  checks (terraform-validation), credential debugging
  (secret-safe-diagnostics), code diffs (change-verification),
  orientation (project-orientation).
---

# Terraform plan review

## Scope

**Use when** a plan already exists — pasted plan text, saved `-out` file the
user describes, JSON plan, or a diff between expected and actual plan output —
and the user wants to know what it does, whether it is safe, and what to
confirm before anyone applies it.

**Do NOT use when:**
- No plan exists yet, or the question is which checks (fmt/init/validate/
  plan/test) to run and their side effects → `terraform-validation`.
- The failure is provider auth or credential exposure debugging →
  `secret-safe-diagnostics`.
- The diff is application code, not IaC → `change-verification`.
- The task is orienting in the repo before any plan exists →
  `project-orientation`.

**Hard boundary:** this skill reviews; it does not execute. Generating a
fresh plan (or fixing configuration) is a *recommendation* returned to the
user, optionally routed to `terraform-validation` — never an action taken
here.

## Inputs needed

1. The plan itself: pasted text, file path, or JSON plan. If none is
   available, STOP: hand off to `terraform-validation`; do not run terraform.
2. Context if the user has it: the intended change (the requirement or
   ticket it implements), target environment/workspace, which ROOT MODULE
   the plan came from, whether the state is shared or remote, and plan
   PROVENANCE — which tool/version produced the plan, how it was obtained,
   and how fresh it is versus current state (saved plans go stale;
   `-refresh=false` plans reflect whatever state was current when created;
   configuration or provider-version drift since the plan was made can
   invalidate it).
3. Known constraints: protected resources, org policy (e.g., no RDS
   deletes), expected change size.

Missing context is not a blocker: proceed with what exists and record every
assumption explicitly under `Unanswered questions`.

## Procedure

1. **Establish context and provenance.** Pin down the intended change, the
   target environment/workspace, the ROOT MODULE the plan came from, and
   the plan's PROVENANCE: which tool/version produced it, how it was
   obtained, and whether it is current. Saved plans go stale relative to
   live state (`-refresh=false` plans embed whatever state was refreshed
   when the plan was created), and configuration or provider-version
   drift since then can make a saved plan invalid — flag staleness or
   mismatch before treating any delta as evidence of a future apply.
2. **Determine whether the supplied plan material is safe to inspect**,
   before analyzing it. Prefer sanitized extracts (resource addresses,
   attribute names, redacted values); never request raw state files or
   full plan dumps when an extract suffices. If the material as supplied
   embeds credentials, ask for a redacted form first.
3. **Identify the plan format.** Legacy text plan (`Plan: X to add, Y to
   change, Z to destroy`), JSON plan (has `terraform_version`,
   `planned_changes` / resource deltas), or a described saved plan file.
   Note the format; findings must cite evidence in the format the user has.
4. **Build a complete change inventory.** Classify every resource delta:
   add / change (update in place) / destroy / replace (destroy + create,
   including `create_before_destroy` vs delete-before-create ordering) /
   move (address change, data intact) / import (adopt into state) / no-op.
   Reconcile the inventory counts against the plan's own summary line. A
   mismatch is itself a finding (parser error, truncated paste, or hidden
   module output).
5. **Triage risks, highest first.** For each, record: severity
   (blocking / high / medium / low / info), evidence (exact plan text or
   JSON pointer), impact, and what to confirm.
   - Destroys of persistent stores, stateful services, DNS/CDN, IAM, or
     anything with backup implications → blocking or high.
   - Replaces of stateful or hard-to-recreate resources; `requires
     replacement` on attributes nobody intended to touch.
   - Delete-before-create ordering on things that must not have an outage.
   - Identity/IAM: destroyed or broadened roles, policies, users, key
     material; access changes whose blast radius outlives the deploy.
   - Network exposure: security-group/firewall rules opening to
     `0.0.0.0/0` or wider ranges, newly public IPs/endpoints, removed
     restrictions.
   - Storage: destroys or replaces touching deletion/retention controls —
     `deletion_protection`, final snapshot/backup settings, lifecycle and
     retention policies.
   - Encryption: KMS key changes or replacement, enable/rotation flags
     that force replacement, algorithms changing on live data.
   - Plan size surprises: mass changes in shared stacks, unrelated modules
     appearing, a one-line config change producing dozens of deltas.
   - Drift (`# forces replacement` from refresh, resources already out of
     sync) and foreign resources (changes to resources this config did not
     previously manage).
   - Sensitive material: secret values, tokens, connection strings, or
     private identifiers appearing in planned attribute values → flag and
     redact (see ground rules); recommend ephemeral/`sensitive` handling.
   - State/backend risks: workspace mismatches, `-refresh=false` or
     `-replace`/`-target` flags visible in the plan header, plan files with
     embedded secrets, state-locking warnings.
   - Unknown values ("known after apply" / computed): they prove only that
     a value is deferred until apply — not that the change is harmless,
     not its direction or size, and not that dependent resources stay
     stable. A `~ update in-place` with unknown new values can hide
     semantic change; flag chains of unknowns downstream of risky deltas.
6. **Cross-check against stated requirements when provided.** Does the
   inventory actually implement the requested change? Flag deltas that serve
   no stated purpose, and required effects the plan does not deliver.
   Hypotheses ("the author probably intended…") stay labeled as suspicion,
   never facts.
7. **Feed findings into Required verifications as options, not actions.**
   E.g., re-run with narrower scope, split the apply, add lifecycle
   guards, regenerate a refresh-only plan — routed to
   `terraform-validation` when the user wants them executed. Drafting
   corrective HCL is offered as a follow-up **state-changing** task
   requiring explicit approval; this skill never edits configuration
   itself.

## Output format

Deliver, in this order:

1. **Intended change** — one or two lines on what the change is meant to
   accomplish and against which requirement; includes the one-line verdict
   (safe to apply / apply with named conditions / do not apply as-is) and
   an explicit evidence-sufficiency statement: is the available plan
   evidence sufficient for this conclusion, and if not (truncated paste,
   stale/unprovenanced plan, missing context), what exactly it does not
   support.
2. **Change summary** — inventory table: action, resource address, module,
   one-line note; counts reconciled with the plan's own summary line.
3. **Actionable risks** — each with severity, evidence quote/pointer,
   impact, and the affected **resource address where available**.
4. **Unanswered questions** — open questions, what was not provided, and
   every assumption made (assumptions live here, nowhere else).
5. **Required verifications** — concrete things to confirm or re-check
   before anyone applies, marked as not-yet-run options.

## Failure handling

- **Truncated or partial paste:** say so; review what exists; mark the
  inventory `INCOMPLETE — counts may understate`; carry this into the
  evidence-sufficiency statement — conclusions about total scope are NOT
  supported by a partial paste. Never infer missing resources.
- **Counts don't reconcile:** report the exact discrepancy; do not silently
  pick one number.
- **Unparseable / unknown format:** state the format seen, ask for the raw
  output or a JSON plan; do not guess semantics.
- **No plan at all:** decline to review, route to `terraform-validation`.
- **Plan of a different IaC tool** (Pulumi, CDK diff, CloudFormation
  change set): state the mismatch; offer a best-effort read of universal
  categories (create/update/delete/replacement) with reduced confidence.

## Ground rules

- **Never execute terraform/tofu or any infrastructure command.** Review is
  static, against provided text. Loading this skill is not authorization to
  run anything; normal tool permissions still gate every step, and
  terraform commands remain outside this skill's scope entirely.
- **Never run `apply`, `destroy`, `import`, state edits, or `force-unlock`**
  regardless of how the conversation develops, unless the user separately
  authorizes a *different*, approval-gated workflow (that authorization never
  transfers to this skill).
- **Never ask to be handed credentials, `.tfvars` with secrets, full state
  files, or raw plan JSON when a redacted excerpt suffices.** Prefer
  resource addresses, attribute *names*, and sanitized values.
- **Redact at capture:** if pasted content contains tokens, passwords, or
  private endpoints, do not repeat the values; name the credential type and
  location, flag rotation, and keep the redacted form in all outputs.
- **A saved plan is not safe to print or paste just because CLI output may
  redact some values:** `(sensitive value)` masking is a CLI display choice;
  the plan file and its JSON contain the real values. Inspect through
  sanitized extracts, not raw `show -json`/plan-file output.
- **Never invent:** resource semantics, provider behavior, counts, or
  author intent presented as fact. Unsupported reads stay labeled.
- **Never invent cost estimates** — no dollar figures, "cheap/expensive"
  claims, or cost projections; cost is outside plan evidence.
- **Never guarantee deployment or apply success.** A plan review is past
  evidence about one planning run; it cannot prove a future apply behaves
  the same way (state, providers, or config may drift between them).
- **Never soften findings** to make a plan look acceptable; the review's
  value is its honesty about risk.

## Completion checks

- [ ] Provenance recorded or explicitly flagged unknown: tool/version, how
      the plan was obtained, staleness and provider/config drift assessed.
- [ ] Every planned action from the plan appears exactly once in the
      inventory, and inventory counts reconcile with the plan's summary
      line (or the discrepancy is a filed finding).
- [ ] Every finding cites re-checkable evidence (plan line, JSON pointer,
      or exact quote) and names the affected resource address where the
      plan provides one.
- [ ] All secrets/PII that appeared in the plan are flagged as exposed and
      absent (redacted) from the review output.
- [ ] The output states evidence sufficiency for the verdict (sufficient /
      partial, and what the evidence cannot support); assumptions are in
      `Unanswered questions`.
- [ ] The verdict (inside `Intended change`) states conditions for apply,
      nothing invents costs, and nothing claims or promises that anything
      was or will successfully be executed.
