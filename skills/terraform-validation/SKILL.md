---
name: terraform-validation
description: "Selects proportionate Terraform checks and reports what each verifies. Use when: validate this terraform, terraform fmt/plan/test, check this .tf/tfvars before merge, is this terraform valid, tofu/terragrunt validate. Establishes target module, versions, provider/backend constraints without exposing credentials; separates fmt -check/-diff (non-mutating) from fmt, validate (internal consistency, no provider API calls) from plan (API calls, data sources, credentials, -out writes sensitive plan files) from terraform test (run blocks may apply, cost, need cleanup; mocks prove config logic only). Explains init side effects (downloads, .terraform/, lockfile, backend); no -upgrade or lockfile churn; apply/destroy/import/state edits/force-unlock/infra tests need separate explicit approval; state, plan JSON, tfvars get secret-safe hygiene. Not for non-Terraform layers (change-verification), credential debugging (secret-safe-diagnostics), repo orientation (project-orientation), opencode config (customize-opencode)."
---

# Terraform Validation

Choose the cheapest Terraform checks that can actually catch the failure the
user cares about, and report exactly what each executed check does and does
not prove. Terraform-specific semantics live here; the generic verification
discipline (screen commands for side effects, approve before
state-changing/costly/disclosing commands, inspect evidence rather than exit
codes, attribute failures, report unrun checks honestly) lives in
change-verification, which remains the parent workflow for any non-Terraform
layers (unit tests, lint of wrapper code, CI wiring). Loading this skill
grants no permissions: the invoking agent's tool permissions and approval
flow gate every step, including read-only ones.

## Use this skill when

- Terraform/OpenTofu configuration (`.tf`, `.tfvars`, modules, `.tftest.hcl`)
  was created or changed and must be checked, or the user asks for a
  pre-merge/pre-apply confidence check.
- Triggers: "validate this terraform", "run terraform fmt/plan/test",
  "is this terraform valid", "check this module before merge", "did my .tf
  edit break anything", "tofu validate", "terragrunt plan".

## Do NOT use this skill when

- The change is not Terraform: change-verification owns generic verification
  and the non-Terraform layers of a mixed change; this skill only replaces
  the Terraform-shaped checks inside that workflow.
- The repository is unfamiliar and unoriented: project-orientation first
  (read-only discovery), then verification.
- Provider auth, backend connectivity, or credential questions dominate the
  task: secret-safe-diagnostics owns that collection work.
- A configuration of the tool itself is being *changed*: safe-config-change
  owns third-party config edits; verify afterwards with this skill.
- The task is implementing or fixing the configuration: this skill checks;
  repair is a separate approved task.
- The target is opencode's own configuration: customize-opencode owns that.

## Ground rules (non-negotiable)

- Loading grants no permissions; commands marked [APPROVAL] additionally
  require explicit user approval before execution. Approval for one command
  never extends to another.
- Validate proves internal configuration consistency only. It does not
  prove deployment will succeed, credentials work, or the provider API
  accepts the plan. Never present it as deployment proof.
- Plan is not free or offline: it may call provider APIs, evaluate data
  sources, require credentials, and consume rate limits or money. `plan
  -out=PLANFILE` writes a file containing sensitive values: never cat it or
  pipe `terraform show -json` into the transcript without
  secret-safe-diagnostics hygiene.
- Never run `apply`, `destroy`/`apply -destroy`, `import`, `state mv/rm/
  push/replace-provider`, backend migration, `force-unlock`, or any
  infrastructure-backed test (apply-mode `terraform test` runs) without
  separate explicit approval. A passed validation is not implicit
  authorization.
- Routine validation never upgrades: no `init -upgrade`, no manual lockfile
  edits, no provider/module version churn. If a constraint forces an
  upgrade, stop and report; that is a separate approved decision.
- Formatting edits require approval: default to `terraform fmt -check` and
  `-diff` (non-mutating) instead of `fmt`.
- State and plan outputs, and `*.tfvars`, may embed secrets: treat with
  secret-safe-diagnostics principles (presence/structure over values;
  sanitized excerpts only; no bulk state or plan dumps into the transcript).
  Reading a tfvars file to inspect it is [APPROVAL].
- A zero exit code proves nothing until the output is inspected (see
  change-verification: evidence, not exit codes).

## Command semantics (know what each check proves)

- `terraform fmt -check`, `terraform fmt -diff`: formatting only; `-check`
  exits non-zero when files are uncanonical and writes nothing. Plain `fmt`
  rewrites files: [APPROVAL] whenever edits are not already approved.
- `terraform validate`: schema, syntax, references, and module-argument
  consistency against the *installed* provider schemas. Requires initialized
  modules/providers (init, or at least `terraform get` for module
  dependencies); makes no provider API calls and needs no credentials.
  Catches neither invalid runtime values nor provider-side rejections.
- `terraform init`: downloads providers and modules, writes `.terraform/`,
  and creates or updates `.terraform.lock.hcl`; initializes the configured
  backend, which means contacting it and possibly acquiring a lock or
  writing environment metadata. [APPROVAL]: network downloads plus local
  and backend writes. `init -backend=false` skips backend access, which
  limits writes and is enough for validate/fmt-style checks, but plan and
  test are unavailable with an uninitialized backend. Always flag lockfile
  creation/change.
- `terraform plan`: full configuration-plus-state preview; reads state from
  the backend, refreshes real resources (API calls, time, possible cost),
  evaluates data sources, and needs provider credentials. Non-mutating by
  default for state, but `-out` writes a plan file [state-changing] and
  refresh can be heavy: consider `-refresh=false` only when the user
  accepts staleness. Plan mode does not create infrastructure; apply does.
- `terraform test`: runs `.tftest.hcl` files. Inspect every test file
  *before* running: `run` blocks carry a `command` of `plan` or `apply`;
  apply-mode runs create real infrastructure with a real provider (costs,
  credentials, cleanup), plan-mode runs only preview. Provider-defined
  `verify` blocks and teardown/defer features add checks and cleanup but
  are version-dependent newer features — confirm the installed version
  supports them before relying on them.
  `mock_provider`, and `mock_data`/`mock_resource` where supported
  (newer feature), substitute provider behavior: mocked tests prove
  configuration logic only, never real-provider compatibility.
- `terraform show`, `terraform state list/pull`: read state and embed
  secrets; [APPROVAL] and secret-safe-diagnostics hygiene; prefer `state
  list` over `pull`.

## Procedure

1. Establish the target. Root module path, the task and what "validated"
   must mean for it, Terraform/OpenTofu/Terragrunt/TFLint binaries and
   versions if present (`terraform version`), `required_providers` and
   `required_version` constraints, and applicable project instructions
   (AGENTS.md, Makefile, CI configs). If the repo is unfamiliar, run
   project-orientation first.
2. Identify environment and backend from configuration: which backend is
   configured (local, remote), which workspace/environment, which tfvars
   exist. Note sensitive-looking variables by name only; do not print
   values. Identify which providers are involved because later steps
   depend on whether they need credentials.
3. Inspect existing tests and automation before choosing anything:
   `.tftest.hcl` files, CI pipelines, Makefiles, terragrunt/tofu wrappers.
   Match the project's own entrypoint (a terragrunt repo is validated with
   terragrunt, not raw terraform) and its test layer: mocked unit-style
   tests versus infrastructure-backed integration tests.
4. Separate the four layers and select proportionately:
   (a) formatting (`fmt -check`/`-diff`),
   (b) configuration validation (`validate`),
   (c) planning (`plan`, with its API/credential/cost caveats),
   (d) infrastructure-backed tests (`terraform test` apply-mode runs).
   Select only layers the task justifies; run (a) and (b) by default, (c)
   and (d) only when the question actually requires them.
5. Check initialization state before planning: if `.terraform/` is absent
   or provider/module constraints changed, explain init implications first
   — downloads, `.terraform/` writes, `.terraform.lock.hcl`
   creation/change, backend contact and possible state-metadata writes —
   then request approval. Never include `-upgrade`; prefer `-backend=false`
   when only validate/fmt-level confidence is needed and the backend
   cannot be touched.
6. Propose the plan and get approval. Classify each command: read-only,
   local-write, network-download, provider-API/contact, state-touching,
   costly, secret-disclosing — following change-verification's screening
   step. Mark [APPROVAL] items. Keep plan-file paths out of the transcript
   content even when the path itself is fine.
7. Execute approved checks, cheapest first, and inspect output rather
   than exit codes. Track each command as planned / executed / passed /
   failed / blocked / not-run. `validate -json` or `show -json` are valid
   only if the installed binary lists them in `-help`; never invent flags.
8. Interpret results in scope: fmt says style; validate says internal
   consistency against pinned schemas; plan says what the provider would
   do given current state and credentials *at this moment*; tests prove
   only their assertions, and mocked tests only within their mocks. State
   plainly which of these the user asked for and which did not run.
9. Attribute failures per change-verification: change-related,
   pre-existing (baseline evidence required), or environmental (missing
   init, missing credentials, no network, toolchain mismatch). Never fix,
   re-init with upgrades, or restate lockfiles to force a pass.
10. Report (format below) and state what remains unverified — typically
    real-provider behavior, untested environments, and apply-time-only
    errors.

## Output format

Report exactly these sections:

- Target and versions: root module, tool and version (tofu/terragrunt
  where applicable), provider constraints, backend/environment identified.
- Proposed checks and risks: each layer, what it proves, its side-effect
  classification, and its approval status.
- Approved commands actually executed: verbatim, each labeled passed /
  failed / blocked / not-run.
- Results: what the inspected output showed, in scope (what kind of
  correctness each result covers), with sensitive values kept out.
- Checks not run and why: not needed, not approved, blocked, or too
  risky/costly.
- Remaining uncertainty: apply-time-only failures, provider-side
  validation, unrefreshed or unselected environments, mocked-behavior
  assumptions, lockfile/backend drift.

## Failure handling

- Not initialized and init refused or impossible: report validate/plan as
  not-run with the reason; do not download anything without approval.
- Missing credentials or backend access: label the failure environmental,
  report presence/absence (secret-safe-diagnostics style) rather than
  values, and mark plan/test results as unavailable, not passing.
- Test files missing or version-incompatible (`terraform test` unsupported
  on this version): say so; do not substitute an ad-hoc `apply` as a test.
- Lockfile or provider-schema drift appears during init: stop, report the
  diff intent, and get a separate decision; do not commit or discard the
  lockfile unasked.
- Ambiguous target module or environment: ask one targeted question before
  anything that writes, downloads, or contacts the backend.
- A check that would touch infrastructure (apply-mode test, destroy plan
  at scale) is declined: keep it in the report as not-run; never swap in
  a riskier alternative.

## Completion checks

- Every "passed" claim maps to an executed command whose output was
  inspected; every planned command carries a status label.
- No apply/destroy/import/state edit/force-unlock/infra-backed test ran
  without recorded separate approval; no `-upgrade` or lockfile churn
  happened unasked; formatting edits (if any) were approved.
- No credential, variable value, tfvars content, state payload, or plan
  JSON value entered the transcript; reading such material was approved
  and sanitized or did not occur.
- The report separates fmt / validate / plan / test results and states
  what each proved and did not prove; mocked-test caveats are stated
  explicitly.
- Remaining uncertainty is written out, not implied: at minimum
  apply-time-only failures and untested environments are named.
