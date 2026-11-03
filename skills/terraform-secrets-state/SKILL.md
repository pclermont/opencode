---
name: terraform-secrets-state
description: 'Reviews Terraform/OpenTofu secret handling and state protection without retrieving or exposing secret values. Use when the user says: "audit terraform secret handling", "is my state file safe", "are tfvars secrets committed", "where do terraform credentials come from", "protect terraform state". Maps credential sources (env, tfvars, provider blocks, data sources, CI, IAM roles) using metadata, never values; checks sensitive marking (display-only); state and saved plan files persist real values, CLI masking is cosmetic, encryption at rest depends on backend config; reviews backend access/encryption/locking/recovery/env separation; audits artifact hygiene (backups, plan/CI artifacts, tfvars, TF_LOG logs, gitignore vs git history); separates confirmed exposure from risky config; recommends only, applies nothing. Loading this skill grants no permissions. Not for: terraform-validation (commands), terraform-plan-review (plan content), secret-safe-diagnostics (credential debugging), safe-config-change (fixes).'
---

# Terraform secrets and state review

Review how a Terraform/OpenTofu project obtains, marks, stores, and can
leak secrets, and how well the state that persists them is protected.
The review is read-only: inspect metadata, report findings, recommend
minimal mitigations. Never retrieve secret values, change backends,
change access controls, or apply fixes here. Loading this skill grants
no permissions - normal tool permissions still gate every step, and
steps marked [APPROVAL] additionally require explicit user approval
before they run. Loading a skill is never authorization to execute it.

## Scope

Use when:
- The user asks how secrets reach Terraform/OpenTofu or where they end
  up: "audit terraform secret handling", "is my state file safe", "are
  tfvars secrets committed", "where do terraform credentials come
  from", "protect terraform state", "is my state bucket safe".
- Reviewing credential sources, `sensitive` marking, backend
  protections, or secret-bearing artifacts (state files, saved plan
  files, `.tfvars`, CI artifacts, debug logs) as an assessment rather
  than a retrieval exercise.
- A confirmed exposure (tracked state file, committed tfvars, publicly
  readable bucket) must be separated from configuration that is merely
  risky.

Do NOT use when:
- The question is which Terraform commands to run and what side effects
  they have: terraform-validation owns that.
- A plan already exists and its content must be reviewed:
  terraform-plan-review.
- Live credential or backend-connectivity debugging requires value
  access: secret-safe-diagnostics.
- A recommended fix should actually be applied: safe-config-change,
  under its own separate approval (see Hand-offs).
- The target is the non-Terraform layer of a mixed change:
  change-verification.
- The target is opencode's own configuration: customize-opencode.

## Ground rules

- Do not read raw state files, dump plan JSON (`terraform show -json`),
  retrieve credentials, or enable verbose logging (`TF_LOG=DEBUG/TRACE`)
  as part of this review.
- Sanitize at capture, not after the fact: prefer names, presence,
  paths, permission bits, and versions over values. Post-hoc redaction
  cannot undo transcript capture. Never repeat a secret value, and do
  not pass one inside follow-up commands or arguments either - arguments
  leak through shell history, process listings, and CI logs.
- A remote backend does not automatically provide any particular
  control. Access control, encryption at rest, locking, versioning, and
  environment separation each have to be verified separately.
- A `.gitignore` entry never removes an already-committed secret. Git
  history persists until history is rewritten; rotation is the
  remediation, not gitignore.
- If it is unclear whether a value is a real credential or a
  placeholder, treat it as real.
- Demonstrate detection or masking only with obviously fake values in
  disposable fixtures.

## Procedure

1. Identify where credentials enter the configuration, recording
   metadata only. Enumerate: environment variables (names only, e.g.
   provider `*_TOKEN` / `*_SECRET` conventions), CLI `-var` and
   `-var-file`, `.tfvars` files (path, permission bits, tracked or not),
   provider config-block attributes such as `access_key`, `secret_key`,
   `credentials`, data sources that read secrets, external or
   secret-manager lookups, CI secret stores (binding names, never
   values), instance profiles and role assumption. Record names,
   presence, file paths, permissions (`stat` mode bits), and source
   precedence. Do not open these files to inspect contents inside this
   skill: route any excerpt inspection to secret-safe-diagnostics,
   which has its own approval-gated, sanitized tiers.

2. Check `sensitive` marking. Report which variables and outputs do and
   do not carry `sensitive = true`, identified by name. State plainly
   that marking is display-only: it suppresses CLI echo and plan
   rendering, not persistence.

3. State the persistence facts without demonstrating them by
   retrieval: sensitive values still land verbatim in
   `terraform.tfstate` and in saved plan files created with `-out`;
   CLI masking (`(sensitive value)`) is cosmetic; core
   Terraform/OpenTofu does not encrypt state client-side - at-rest
   encryption depends on backend configuration. Where a claim is
   version-dependent, check the installed `terraform version` /
   `tofu version` against official docs.

4. Verify version-gated features before recommending them. Phrase as:
   ephemeral resources and write-only arguments are available in
   Terraform 1.10+; verify the installed version and the provider
   schema. OpenTofu support is version-dependent - verify the
   installed version. If the version cannot be established, keep the
   recommendation conditional and say so. Never assume availability.

5. Review backend protections one control at a time - a remote backend
   grants none of them by being remote:
   - Access control: least privilege on the state store (IAM policy,
     bucket ACL, group permissions), read as well as write.
   - Encryption at rest (backend or bucket setting) and in transit
     (enforced TLS on the endpoint).
   - State locking: lock file, DynamoDB-style lock, or backend-native
     locking.
   - Recovery: state versioning, backups, history retention.
   - Environment separation: workspaces share one state and one
     credential set; separate state files and separate credentials per
     environment limit blast radius. Record which model the project
     uses.
   Verifying live store settings requires provider/API calls:
   [APPROVAL] before any such call. If not run, leave the control as an
   unverified risk, not a finding.

6. Audit artifact hygiene with metadata-level checks only (paths,
   permissions, tracked status - never contents):
   - State files and their backups or copies on disk.
   - Saved plan files: they contain real values even for `sensitive`
     outputs.
   - `.tfvars` files: existence, permissions, tracked status.
   - CI artifacts: uploaded plan artifacts, caches, log output.
   - Debug logs: `TF_LOG=DEBUG/TRACE` request bodies can carry
     credentials; flag existing log files by path only, and never
     enable verbose logging to investigate.
   - VCS exclusions: check that `.gitignore` covers `*.tfstate` and
     `*tfvars*`, then detect current or former tracked paths with
     content-free checks only: `git ls-files` and `git log --name-only`
     filtered to state, tfvars, and plan paths (names only, never blob
     contents). If past exposure is confirmed, recommend rotation and
     state that gitignore does not remove committed secrets - history
     persists until rewritten, and rewriting it is itself a separately
     approved decision.

7. Name risky exposure paths without opening their contents: publicly
   readable state buckets, plan artifacts uploaded in CI, committed
   tfvars, world-readable state or log files on disk, debug logs in
   shared directories. Name the path or artifact; do not read it.

8. Classify every finding honestly:
   - Confirmed exposure: direct, re-checkable evidence - a file tracked
     in git (named via `git ls-files`), a policy permitting public
     read, a credential-bearing artifact, a world-readable log. Cite
     the evidence.
   - Potentially unsafe configuration: no locking, unmarked
     `sensitive`, tfvars on disk but untracked, missing encryption
     setting. State as a risk, never as a confirmed leak.

## Boundaries (what needs approval, what is out of scope)

- Out of scope entirely: reading state contents, dumping plan JSON,
  retrieving or printing any credential value, enabling verbose
  logging, rotating keys, changing backends, changing access controls,
  rewriting git history, applying any fix.
- Requires separate explicit approval, each individually: live
  backend/store API calls, creating or running fixtures (even with
  fake values), any step another skill owns.
- Approving this review never authorizes remediation. Every mitigation
  is a proposal the user must separately approve, then execute through
  a separately approved workflow.
- Do not invent CLI flags, provider features, or version support; do
  not estimate blast radius without evidence.

## Output format

Report exactly these sections:
- Evidence inspected: sanitized - paths, names, versions, permission
  bits, tracked status, policy names; never values.
- Confirmed issues: each citing direct evidence (git path list, policy
  statement, artifact name).
- Unverified risks: stated as risks, not findings, each naming what
  approval-gated evidence would confirm it.
- Minimal mitigations: smallest-change framing - baseline the current
  effective setting, propose the single smallest change, attach risks,
  a validation plan, and a rollback plan; label each [APPROVAL].
- Fake-secret validation plan: verify detection or masking end-to-end
  using obviously fake values in disposable fixtures only (throwaway
  directories or scratch workspaces with credentials that cannot be
  real; never production credentials, never values copied from live
  state).

## Hand-offs

- Command choice and side-effect triage (`fmt`/`init`/`validate`/
  `plan`/`test`, credentials, cost, `-out` files): terraform-validation.
- Reviewing a supplied plan's content: terraform-plan-review.
- Live credential or connectivity debugging, and containment of an
  accidental value capture: secret-safe-diagnostics.
- Applying any configuration fix: safe-config-change (third-party
  config), under its own approval; opencode's own config belongs to
  customize-opencode.
- Non-Terraform layers of a mixed change: change-verification.
- Orienting in an unfamiliar repo before the review:
  project-orientation.

## Failure handling

- Installed tool or provider version cannot be established: leave
  version-gated recommendations conditional; never claim a feature
  exists.
- Backend policy or store settings are not observable read-only:
  record as unverified risk; do not make backend API calls without
  approval.
- Git history unavailable (shallow clone, non-git directory): state
  that past exposure cannot be bounded; suggest the user run
  `git log --name-only` locally.
- A file is unreadable due to permissions: report path, name, and
  permission bits - do not escalate; the permission itself is a
  finding.
- A value enters the transcript accidentally: stop propagating it,
  name the credential type and location, never repeat the value, and
  recommend rotation plus a persistence review (shell history, CI
  logs, saved artifacts).
- The user asks to "just dump the state to check": decline inside this
  skill; route to secret-safe-diagnostics, which may permit a narrow,
  approval-gated sanitized excerpt instead.

## Completion checks

- Every statement about a value is at metadata tier (name, presence,
  path, permission, version); no state contents, plan JSON, credential,
  or debug-log body entered the transcript.
- Every finding is labeled confirmed (with re-checkable evidence) or
  potentially-unsafe (stated as risk).
- Backend controls were assessed individually, and no statement
  implies a remote backend provides all of them.
- No claim that `.gitignore` removes committed secrets, and every
  confirmed past exposure carries a rotation recommendation.
- Every version-gated recommendation is conditional or backed by a
  recorded installed version.
- Nothing was rotated, rewritten, applied, or changed: each proposal
  carries risk, validation, and rollback, and is marked as requiring
  separate approval.
