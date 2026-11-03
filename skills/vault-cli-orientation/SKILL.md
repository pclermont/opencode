---
name: vault-cli-orientation
description: 'Maps the installed Vault client binaries and prerequisites before any Vault command is generated. Use when the user says: which vault cli is installed, is vault-cli present, what version of vault, which vault is on PATH, vault client prerequisites, VAULT_ADDR or namespace precedence, or before vault login or vault kv usage. Identifies the actual client (HashiCorp official vault CLI, the Python vault-cli project, aliases, wrappers) from verified evidence: version banners, installed help, package provenance; verifies config sources and precedence from the installed tool help and official docs, not memory; checks credential presence without printing values; separates local findings from unverified server connectivity; proposes remote checks separately with approval. Not for diagnosing auth or connectivity failures (secret-safe-diagnostics), repo orientation (project-orientation), config edits (safe-config-change), verifying changes (change-verification), or opencode config (customize-opencode).'
---

# Vault CLI Orientation

Maps which Vault client binary (if any) is actually installed and what prerequisites
it requires before any Vault command is generated. Loading this skill grants no
permissions: every shell step below is marked [APPROVAL] and requires explicit user
approval before execution; approval gates tool calls, not task selection.

## Use this skill when
- The user asks which Vault CLI is installed, where it lives, which version, or whether
  prerequisites are met: "which vault cli is installed", "is vault-cli present",
  "what version of vault", "which vault is on PATH", "am I ready to run vault commands".
- Vault command syntax (vault login, vault read, vault kv, vault-cli list) is about to
  be generated and the client identity has not been established in this session.
- Configuration sources, environment variables, namespace, or TLS prerequisites must be
  inventoried read-only before other Vault work.

## Do NOT use this skill when
- Diagnosing a failing auth, connectivity, or suspected credential exposure:
  use secret-safe-diagnostics.
- Orienting inside a code repository: use project-orientation.
- Changing configuration, environment variables, or dotfiles: use safe-config-change.
- Verifying a change already made: use change-verification.
- Editing opencode itself: use customize-opencode.
- The client identity is already established and evidenced in this session: skip to
  the relevant task skill.

## Non-negotiable boundaries
- Never retrieve secret values or enumerate secret paths/trees. Orientation never runs
  commands that read secrets (for example vault read, vault list, vault kv get).
- Never print tokens, passwords, private keys, full configuration files, or environment
  dumps. Check variables by name for presence only; treat any file the installed tool
  names as a config or token-helper location as sensitive: report paths, names, and
  permission bits, never contents.
- Treat endpoint hostnames/URLs and secret path names as potentially sensitive: include
  them only when the question requires them; otherwise summarize, for example
  "an internal endpoint is configured".
- Never log in, renew or revoke credentials, contact the Vault server, change
  configuration, disable TLS verification, install or remove packages, or otherwise
  mutate state without separate explicit approval.
- Never state client-specific facts (config file names, environment variables, flag
  syntax, capabilities) from memory. Record them only from the installed tool's own
  help/version output or fetched official docs, and cite what was verified.

## Client identity is evidence, not a name
The name vault or vault-cli on PATH is ambiguous: it may be HashiCorp's official vault
CLI, the Python vault-cli project (pip/pipx-installed), an alias, a shell function, a
wrapper script, or a distro-managed build. Establish identity from observed output:
- type -a vault; type -a vault-cli - reveals aliases, functions, and every file path
  in PATH order.
- For each path: <path> -version - keep the actual version/banner line as printed.
- <path> -h or help - keep the usage synopsis; the subcommand shape distinguishes the
  tool families. Use observed output only, never remembered expectations.
- Provenance, whichever package managers exist here: pip show vault-cli, pipx list,
  dpkg -l, rpm -qa, snap list, brew list.
If banner or usage evidence is ambiguous or conflicting, record identity as unresolved
and report the ambiguity instead of picking a client.

## Configuration sources and precedence: verify, never recall
Different Vault clients read different sources in different precedence. The
authoritative set is the installed tool's own help/man output plus official docs for
that exact client and version. Candidate categories (which apply, their names, and
their precedence must be confirmed from verified docs before being reported as facts):
- environment variables (the official CLI documents VAULT_ADDR, VAULT_NAMESPACE,
  VAULT_TOKEN and others; the Python project documents its own set),
- per-user and system config files named by the installed help output,
- shell aliases, functions, and wrappers found by type -a.
For each confirmed source: presence check only - variable set or unset, file exists,
permission bits. Never values or file contents of secret-bearing files.

## Procedure
1. Establish intent: which client does the user mean - official vault CLI, Python
   vault-cli, or unknown. If unknown, map all installed variants.
2. [APPROVAL] Locate executables: type -a vault; type -a vault-cli; command -v.
   Record every alias, function, and path in PATH order.
3. [APPROVAL] Capture identity evidence per path: -version and -h/-help; keep only the
   banner/usage header lines, sanitized.
4. [APPROVAL] Capture provenance: pip/pipx/dpkg/rpm/snap/brew queries matching vault.
5. Verify configuration categories and precedence from the installed help plus
   official docs for the identified client and version (fetch docs, do not recall).
6. [APPROVAL] Presence checks for confirmed names only: variable set/unset, file
   exists with permission bits. No values, no contents, no env dumps.
7. Assess prerequisites honestly:
   - Settled locally: binary present/absent, version, config sources present, env
     vars set, TLS settings (CA path, verification flags) configured.
   - NOT verifiable locally: server reachability, token validity, permission/policy
     results. State these as unverified; do not probe the server to resolve them
     without explicit approval.
8. If remote checks are needed, propose them separately with the exact command, what
   it authenticates as, what it reads, and what the output could disclose (for
   example vault read returns real secret values - never propose it here). Obtain
   explicit approval; handle any resulting evidence per secret-safe-diagnostics.
9. Client mismatch: if the installed client is not the intended one (for example the
   user means vault kv but only the Python vault-cli is installed, or vice versa),
   STOP. Report the mismatch and its consequences (different syntax, config sources,
   capabilities). Do not generate operational commands for an unintended client and
   do not install the other one without separate approval.

## Output format
Report exactly these sections:
- Client identity: every vault / vault-cli executable found, its family (official
  CLI, Python vault-cli, alias/wrapper), and the evidence that established identity.
- Versions: observed version banners per executable with the command that produced
  each.
- Configuration sources: verified sources in precedence order, how each was verified,
  and presence/absence per source.
- Prerequisites: satisfied locally, missing locally, and not settleable without
  server contact.
- Sanitized findings: endpoint, namespace, configured auth method, TLS settings -
  included only when relevant, summarized when not.
- Unverified assumptions: anything not confirmed against evidence, connectivity,
  token, and permission unknowns, and unresolved identity ambiguities.
- Next approved step: the smallest next action, marked as requiring approval if it
  touches state, credentials, or live services.

## Failure handling
- No vault executable found: report absence with the exact commands run and the PATH
  searched; install nothing; propose installation as a separate approved step.
- Ambiguous or conflicting identity evidence: label identity unresolved; never guess.
- Config file unreadable or permission denied: report path and permission bits only;
  never attempt privilege escalation.
- Docs fetch fails: mark configuration precedence as unverified and say so.
- Output unexpectedly contains a secret-looking value: never repeat it; name the
  credential type and location, recommend rotation, and follow secret-safe-diagnostics
  exposure handling.

## Handoff
- Auth/connectivity failure or credential exposure: secret-safe-diagnostics.
- Editing any configuration found here: safe-config-change.
- A repository that merely uses Vault: project-orientation.
- Verifying a Vault-related change already made: change-verification.
- opencode configuration or skills: customize-opencode.
