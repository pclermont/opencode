---
name: vault-policy-review
description: "Reviews or tightens HashiCorp Vault access policies. Use when the user says: review this Vault policy, least privilege, why can this token read this path, policy diff, vault capabilities, KV v2 path, effective access, tighten ACL. Maps required operations to exact capabilities and path patterns, evaluates wildcard and admin breadth, distinguishes KV v1/v2 and dynamic credential paths, flags lease and token risk, and proposes a minimal HCL diff with expected allow/deny cases. Review only: never applies policy, creates tokens, retrieves secret values, uses root, or proves live access without approval. Loading this skill grants no permissions. Not for login or connectivity (vault-safe-access), secret consumption (vault-secret-consumption), credential diagnostics (secret-safe-diagnostics), Terraform validation, or opencode config edits."
---

# Vault policy review

Use when a user supplies Vault policy text, a policy name to inspect, a
path or mount to scope, or a required operation for an identity.

Do not use for logging into Vault, consuming secret values, fixing a
non-Vault app setting, validating Terraform files, or editing OpenCode
configuration.

## Inputs to collect

Gather these before making claims. If a required item is missing, mark
the result inconclusive rather than inventing it.

- Target Vault address and namespace: presence only; never echo tokens.
- Intended identity, workload, role, group, or token type.
- Exact operation: read, write, patch, list, delete, lease renew, role
  credential issue, or admin action.
- Exact target path and mount point.
- Secrets engine and version when it changes paths, especially KV v1 or
  KV v2.
- Policy source supplied by the user or a specific policy name.
- Whether live capability verification is authorized.
- Operational constraints: production, non-human identity, short-lived
  tokens, or compliance rules.

## Review invariants

- Vault policy is deny by default.
- `path "secret/foo"` matches only `secret/foo`, not `secret/food` or
  `secret/foo/bar`.
- `path "secret/foo/*"` matches paths under `secret/foo/`.
- Effective access is not one policy file. It is the combination of
  token policies, entity and group policies, namespace boundaries, and
  any Sentinel, Endpoint Gateway, or parameter-level controls.
- Capability lookups do not prove a request will succeed because
  parameter-level constraints are evaluated separately.
- Policy paths, policy names, mount paths, namespaces, identity names,
  and role names can reveal sensitive topology. Handle them as sensitive.
- Never use root or a root token.
- Never retrieve secret values to demonstrate policy correctness.
- Do not request broad listing or policy enumeration just to make the
  review easier. Prefer user-supplied material and exact probes.

## Procedure

1. State the review question in one sentence: identity, path, operation,
   and desired scope.

2. Declare the operating context. If login, address, namespace, or
   auth method is unclear, recommend `vault-safe-access` first.

3. Identify the path convention.

   - KV v1: data normally lives under `<mount>/<secret-path>`.
   - KV v2: reads and writes normally use `<mount>/data/<secret-path>`.
   - KV v2 metadata uses `<mount>/metadata/<secret-path>`.
   - KV v2 version lifecycle may use separate prefixes such as
     `<mount>/delete/<secret-path>`,
     `<mount>/undelete/<secret-path>`, and
     `<mount>/destroy/<secret-path>`. Confirm against the installed
     Vault version before asserting exact capability mappings.
   - Dynamic engines often require role paths that generate leases, not
     static data paths.
   - Token and lease operations usually require separate capability on
     token or lease management paths.

4. Build the requirement matrix.

   | Operation | Target path | Engine/version | Capability needed | Why |
   |---|---|---|---|---|
   | read one app secret | `dev-kv-example/data/example-app/db-config` | KV v2 | `read` on data path | application fetches config |
   | list app secrets | `dev-kv-example/metadata/example-app/*` | KV v2 | `list` on metadata path; verify metadata read only if needed | discovery without value read |

   For KV v2, listing normally uses the `metadata` path even when reads
   use the `data` path. Verify the exact behavior for the installed
   version when lifecycle deletion or metadata-only operations matter.

5. Review the supplied policy material for breadth.

   - Check whether exact paths are narrower than required.
   - Check whether wildcard `*` or `**` or root-level patterns grant more
     access than the stated operation.
   - Check writes, deletes, patches, creates, and list permissions
     independently.
   - Check administrative capabilities such as `sudo` and paths under
     `sys/`.
   - Check cross-environment, cross-mount, cross-namespace, and shared
     mount exposure.
   - Check whether policy permits role use, lease lookup/renew/revoke,
     or token self-management only when needed.

6. Classify findings by risk.

   - `Blocking`: policy likely prevents required operation or grants
     obvious credential sprawl.
   - `Important`: broad wildcard, missing lifecycle separation, or
     ambiguous effective-access dependency.
   - `Optional`: naming, duplication, or maintainability issue.
   - `Unverified`: requires live capability check, namespace context,
     group mapping, role configuration, or Sentinel/ACP material.

7. Propose the smallest policy change, but do not apply it.

   Prefer this shape:

   ```hcl
   path "dev-kv-example/data/example-app/db-config" {
     capabilities = ["read"]
   }

   path "dev-kv-example/metadata/example-app/*" {
     capabilities = ["list"]  # add read only if metadata reads are required
   }
   ```

   Use exact paths when the workload needs one secret. Use metadata list
   only if discovery is required. Separate create, update, patch, delete,
   undelete, and destroy only when the lifecycle operations are actually
   part of the job.

8. Describe expected behavior.

   List concrete allowed and denied operations, for example:

   - Allowed: read `dev-kv-example/data/example-app/db-config`.
   - Denied: write `dev-kv-example/data/example-app/db-config`.
   - Denied: read `dev-kv-example/data/example-app/other`.
   - Denied: list `dev-kv-example/metadata/` unless list is required.

9. Separate inspection from verification.

   - Inspection-only means the reviewer reads policy text and explains
     what the text says.
   - Live verification means an approval-gated query such as
     `vault capabilities -help` first, then only an exact
     `vault capabilities <path> -format=json` probe if the CLI supports
     it, the user approves live Vault contact, and no secret value is
     retrieved.

   Treat live capability output as non-secret only when it returns
   capability booleans for the current token. Do not print tokens,
   raw requests, or values from `kv get`.

10. Report what was not verified.

   Say so explicitly when effective access could change because of:

   - missing group or entity assignments
   - unknown namespace boundaries
   - unreviewed additional policies
   - token-created inherited capabilities
   - Sentinel, Endpoint Gateway, or parameter constraints
   - response wrapping, path existence, or engine-specific behavior

## Required output shape

Produce:

1. Scope and assumptions.
2. Requirement matrix.
3. Current policy interpretation.
4. Risk-ranked findings.
5. Proposed HCL diff or replacement policy, clearly not applied.
6. Expected allowed and denied operations.
7. Validation plan:
   - static policy checks performed
   - live checks requiring approval
   - checks not run
8. Open questions and unverified assumptions.

## Failure handling

- If policy text is missing, ask for the exact policy or approve a
  narrow policy fetch by name. Do not enumerate all policies without
  approval.
- If engine version is unknown, do not assume KV v2 paths. Ask or state
  the assumption.
- If capability check fails, record the error without exposing token,
  request, or response values.
- If the proposed policy depends on an unreviewed identity mapping,
  keep the conclusion as `Important` or `Unverified`.
- If the user asks to test access by reading a secret, refuse the
  secret read and suggest a capability-only check instead.

## Boundaries

This skill reviews and recommends. It does not apply policies, edit
Vault configuration, change auth methods, bind policies to identities,
create tokens, read secrets, start dev servers, initialize Vault, or
run Terraform against Vault. Any step that contacts a live Vault server
requires explicit user approval at the time of the step. Label live Vault commands as `[APPROVAL]`.

Use `references/review-case-matrix.md` for reusable fake scenarios and validation cases.
