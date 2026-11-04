---
name: vault-safe-access
description: "Establishes a safe operating context before any HashiCorp Vault interaction. Use for: vault status, vault login, read/write Vault secrets, kv get/put, Vault path/mount/namespace, VAULT_ADDR, is Vault reachable, before any vault call. Establishes target operation, CLI version, address/namespace by presence-only checks, auth method and credential source without token values, exact mount/path, KV engine version when it affects paths. Separates local inspection (vault -version, -help, presence probes) from approval-gated server contact. No root tokens, no ~/.vault-token reads, no secrets in prompts/args, no credential-exposing logins, no TLS bypass. Reports only non-secret fields; paths, namespaces, policy names treated as sensitive. Changes nothing; no init/unseal/dev server; missing auth never broadens access. Not for: credential diagnostics (secret-safe-diagnostics), config edits (safe-config-change), verifying changes (change-verification), permission-rule tests (permission-boundary-validation)."
---

# Safe Vault Access Context

Establishes the operating context for a HashiCorp Vault interaction before any
request is sent: intended operation, target environment, CLI version and
matching docs, address/namespace, authentication path, exact mount/path, and
engine details. Loading this skill grants no permissions and authorizes no
Vault operation; normal tool permissions still gate every step. Steps marked
`[APPROVAL]` need explicit user approval beyond normal tool permissions.

## Scope

Use when:

- The user mentions `vault status`, `vault login`, reading or writing a Vault
  secret, `kv get`/`kv put`, a Vault path, mount, or namespace, `VAULT_ADDR`,
  or asks whether Vault is reachable.
- Planning any `vault` CLI or Vault HTTP API call.
- Establishing which environment, auth path, mount, and scope an operation
  needs before it runs.

Do NOT use when:

- Diagnosing credential/auth failures where evidence may contain secret values
  → `secret-safe-diagnostics` owns that; this skill only prepares the Vault
  operating context.
- Applying configuration changes to a Vault server or other tool →
  `safe-config-change`.
- Verifying a change already made → `change-verification`.
- Testing agent permission rules or approval boundaries →
  `permission-boundary-validation`.
- Orienting in an unfamiliar repository → `project-orientation`.
- Reviewing Terraform state/tfvars secret hygiene → `terraform-secrets-state`
  / `terraform-validation`.
- Editing opencode's own configuration → `customize-opencode`.

## Ground rules (non-negotiable)

1. Never place a token, password, role secret, or other credential in a
   prompt, command argument, transcript, or report. Command-line arguments are
   visible in process listings and logs — treat them as exposure.
2. Never read or print `~/.vault-token`. Never dump the environment. Check
   variables by presence only, e.g.
   `[ -n "${VAULT_ADDR+x}" ] && echo "VAULT_ADDR: set" || echo "VAULT_ADDR: unset"`;
   report `set`/`unset`, never values.
3. Never request a root token, and never run `vault operator init`,
   `vault operator unseal`, `vault operator generate-root`, or `vault dev` as
   part of establishing context. Initializing, unsealing, resetting, or
   starting a server is a separate decision requiring the user's own explicit
   initiative.
4. Never disable TLS verification (`VAULT_SKIP_VERIFY`, `-tls-skip-verify`) to
   work around a connection error. Report the error instead.
5. Any command that contacts the Vault server requires explicit approval
   `[APPROVAL]`. This includes unauthenticated requests such as
   `vault status`.
6. Establishing context changes nothing: no policy, auth method, mount,
   token, secret, or server-configuration change.
7. Missing or insufficient authorization is a blocker to report, never a
   reason to broaden access, try another role, or probe another path.

## Procedure

### 1. Intended operation and target environment

Ask the user for anything missing: the operation (status, auth, read, write,
list), the target environment (dev/staging/prod), and the rough path or mount.
Record these as user-supplied; never infer an environment from defaults.

### 2. Vault CLI and matching docs (local only)

- `command -v vault` and `vault -version` are client-side: no server contact,
  no token needed.
- Confirm exact flags with `vault <command> -help` for the installed version;
  never assume flags. Match documentation to the installed version.
- If the CLI is missing, record a blocker. Installing it is a state change:
  get explicit approval first; never install silently.

### 3. Address and namespace (local, presence only)

Probe `VAULT_ADDR`, `VAULT_NAMESPACE`, `VAULT_TOKEN`, `VAULT_CACERT` for
presence only, as in rule 2. Do not print values; addresses and namespaces can
themselves be sensitive. Do not run any Vault-contacting command yet.

### 4. Authentication method and credential source (plan only)

- Use the auth method the user names (token already issued, AppRole,
  Kubernetes, userpass, LDAP, cloud OIDC/IAM). Never guess roles, mount names,
  or credential sources.
- The agent never performs a login whose output would surface a token or
  secret, and never accepts a secret pasted into chat. If interactive login is
  needed, ask the user to run it in their own trusted terminal (e.g.
  `vault login` with a method of their choosing), or to use an approved
  credential flow.
- Verifying an existing session (`vault token lookup`) contacts the server:
  `[APPROVAL]`. Prefer it over login flows; it reports capabilities without
  revealing the token.
- If the user pastes a credential into the conversation: do not repeat it,
  name the credential type and location, recommend rotation, and route to
  `secret-safe-diagnostics` for exposure handling.

### 5. Exact mount, path, and operation scope

Pin the full target before anything runs, e.g. a fake example mount/path:
`kv-example/data/example-app/db-config` at `https://vault.example.invalid:8200`.
Confirm the scope is no wider than needed (a single path, not a mount listing,
unless listing is the operation).

### 6. KV engine version (v1 vs v2)

KV v2 paths include an extra `data/` segment
(`kv-example/data/app/config` vs v1's `kv-example/app/config`); raw API paths
and `vault read`/`vault write` differ accordingly. Determine the version from
user-provided documentation, or ask before running the server-contacting
`vault secrets list -detailed` `[APPROVAL]`.

### 7. Classify every planned command

- Local, no approval: `command -v vault`, `vault -version`,
  `vault <cmd> -help`, presence probes.
- Server contact, always `[APPROVAL]`: `vault status`, `vault token lookup`,
  `vault secrets list`, `vault kv get/put/list`, `vault read/write`,
  `sys/health`, and any other API request — even unauthenticated ones.
- State-changing, out of scope for establishing context: `kv put/delete`,
  policy writes, auth enable/disable, mount changes — each needs its own
  separate explicit approval and user ownership; context established here is a
  precondition, never authorization for them.

### 8. Least privilege for the approved step

Request only the permissions the approved operation needs: one path over a
mount listing, read over write, list over read-all. If the required capability
is unknown, say so rather than assuming a broader token or role.

## Output format

Report without secret values, in these sections:

1. **Approved target and operation** — environment, address presence, mount
   and path scope, engine version, operation.
2. **Available authentication context** — auth method, credential source,
   session presence/capabilities if verified; never token values.
3. **Prerequisites** — what must exist before the next step (CLI, valid
   session, permissions, CA trust).
4. **Blockers** — missing CLI, unset address, expired session, TLS/network
   error, missing permission.
5. **Next permitted step** — the single next command and its classification
   (local vs `[APPROVAL]`).

Treat paths, namespaces, policy names, and identity metadata as potentially
sensitive: include them only as needed. Never return raw command output
wholesale — status, auth, error, and metadata responses may embed versions,
sealed state, policy names, or internal paths; quote or summarize only the
fields the answer needs.

## Failure handling

- Connection error: classify (DNS, refused, TLS, proxy); never bypass TLS;
  suggest the user verify network/address, and record a blocker.
- `403 permission denied`: authentication succeeded but policy forbids the
  path — report the missing capability; do not try other roles or paths.
- Expired or missing token: ask the user to re-authenticate in their own
  terminal; the agent never handles the token.
- Evidence that may contain secrets: sanitize at capture and follow
  `secret-safe-diagnostics`.
- Any ambiguity about environment, mount, or auth method: ask; a wrong target
  (dev vs prod) is a blocker, not a guess.

## Completion checks

- Every planned command is classified: local vs server-contact `[APPROVAL]`.
- No secret value ever appeared in prompts, arguments, transcripts, or the
  report; presence-only probes used for environment variables.
- No state changed: no login performed by the agent, no write, no server
  command beyond approved, read-only requests.
- The report contains all five output sections, and the next permitted step
  is exactly one command.
