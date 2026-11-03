---
name: vault-cli-secret-maintenance
description: >-
  Plans and carries out explicitly approved Vault secret creation or updates
  using a verified Vault client, without the agent seeing secret values. Use
  when: set/update secret in vault, write password to vault kv, change/rotate
  stored value. Establishes environment, path, field, operation, owner;
  verifies merge-vs-replace against installed help (kv v2 put replaces data,
  patch merges; kv v1 has no patch/versioning); weighs versioning, recovery,
  service impact; uses secure input or stdin pipe, never argv, temp files,
  history, transcripts, or Git; verifies via kv metadata, never reads values.
  Never asks for pasted values, never fetches secrets to check writes, no
  bulk/delete/auth/policy edits; stored-value update is not credential
  rotation. Not for client identity (vault-cli-orientation), launched-program
  injection (vault-cli-secret-exec), leak/auth debugging
  (secret-safe-diagnostics), client config edits (safe-config-change),
  Terraform-owned secrets (terraform-secrets-state).
---

# Vault secret maintenance

## Use this skill

Use ONLY when the user explicitly asks to create or update a Vault KV secret,
the environment, mount/path, field, owner, and intended final behavior are
identifiable without reading secret values, the installed client identity and
KV version are verified or will be routed to `vault-cli-orientation`, and the
task can finish without values entering conversation, transcripts, shell
history, temporary files, commits, or Git objects.

## Do NOT use this skill

Route instead when the request is: client identity/version/KV support
(`vault-cli-orientation`), launching a program with Vault secrets in its
environment (`vault-cli-secret-exec`), auth/credential/exposure debugging
(`secret-safe-diagnostics`), Vault client configuration or dotfiles
(`safe-config-change`), Terraform-owned secrets/tfvars/state
(`terraform-secrets-state`), bulk changes, deletes, version destroy/undelete,
auth methods, access-policy changes, or work outside one named KV field.

This skill is guidance only. Loading it does not grant Vault access, approve a
write, or prove any capability exists. Commands marked `[APPROVAL-GATED]`
touch live external secret state, incur cost, or require tool execution; get
explicit user approval first.

## Non-negotiable boundaries

- Never ask the user to paste a secret value into the conversation.
- Never place raw values in arguments, commands, history, transcripts,
  temporary files, here-docs, `echo`/`printf` literals, interpolated variables,
  commits, or Git objects.
- If secret material appears, do not repeat it: name the credential type and
  likely location, recommend rotation, and route to `secret-safe-diagnostics`.
- Never fetch an existing secret to check existence, verify a write, or
  prepare read-modify-write. Use non-value evidence only when available.
- If safe input cannot be provided, hand value entry to the user instead of
  simulating it by asking for, storing, or fabricating a value.
- Do not overwrite sibling fields or assume recovery is available. Verify
  update semantics and version/recovery policy before approved writes.
- Do not call a stored-value update complete credential rotation.

## Syntax provenance

The KV facts below are documentation-backed at authoring time, not runtime-
verified in this draft. Installed help and official docs win at execution
time. Re-verify `vault kv put -h`, `vault kv patch -h`, and `vault kv
metadata -h` before operational commands.

For official HashiCorp `vault` CLI with KV v2: `vault kv put PATH KEY=VALUE...`
writes a new version and replaces the complete data object, so omitted keys
are lost. `vault kv patch PATH KEY=VALUE...` performs a server-side merge.
`kv put` and `kv patch` may accept JSON on stdin with `-`; file arguments and
literal `KEY=VALUE` arguments are prohibited here.

For KV v1: there is no server-side patch, no versioning, and no recovery.
Overwrite is destructive. Merging one field requires read-modify-write, which
fetches existing values and conflicts with this skill; stop and hand off.

## Procedure

1. Establish the operation. Confirm environment, mount/path, field, new or
   existing state, intended final behavior, owner, and approval owner. If
   client identity or KV version is unverified, stop and route to
   `vault-cli-orientation`.

2. Verify installed help and backend behavior. Read version or help as needed:
   client version, `kv -h`, `kv put -h`, `kv patch -h`, and `kv metadata -h`
   if supported. Record accepted input forms. If installed help disagrees with
   this skill, follow installed help or stop.

3. Determine merge-versus-replace risk. New paths have no sibling fields, but
   ownership and policy still matter. Existing paths require intent: preserve
   sibling fields or replace the complete data object. Use verified KV v2
   `patch` for merge; use `put` only for full replacement explicitly approved.
   For KV v1 merge, stop and hand off.

4. Assess recovery and service impact. Identify consumers and whether they
   load the field at startup, per request, through cache, restart, or deploy.
   Check KV v2 mount metadata only if a non-value command is verified,
   harmless, and approved. State recovery honestly: soft deletes may be
   recoverable where supported; destroyed versions are not. Never promise
   rollback without evidence.

5. Probe existence without values. Use verified non-value probes where
   available, such as KV v2 `vault kv metadata get PATH`. Never use
   `vault kv get`, `vault read`, or any value-returning command to prove
   existence or verify a write. If no non-value probe exists, mark evidence
   insufficient and say so.

6. Choose a safe input mechanism. The value must reach the Vault client
   through a channel the agent never sees. Before proposing it, verify the
   mechanism against the actual execution tool: a non-interactive agent shell
   cannot answer an interactive prompt, and simulating one is prohibited.
   Preferred: the user runs the final write command locally with protected
   input. Acceptable only if installed help confirms and the user approves the
   exact command: one stdin pipe from a secure prompt, or an interactive
   secret helper, with no echo, tracing, history persistence, or temporary
   files. Reject argv `KEY=value`, `@secret.json`, here-docs with literal
   values, `echo secret | ...`, `printenv`, `env`, shell tracing, saved
   scripts, or any method that reveals the value to the agent.

7. Present the approved target and operation. `[APPROVAL-GATED]` Show the
   client/version, KV version, environment/mount, path, field, placeholder
   (`<NEW-VALUE>`), operation (`put`, `patch`, or user-run command), replace-
   or-merge behavior, service impact, recovery evidence, and input method. Do
   not include secret values. Obtain explicit approval for this exact
   operation before execution or handoff.

8. Execute or hand off. `[APPROVAL-GATED]` If the human-execution path was
   approved, provide the exact safe command and stop. If an approved non-
   disclosing mechanism is available, run only the exact approved command.
   Do not add wrappers, demos, dry runs that read secrets, extra Vault
   operations, or unrelated validation.

9. Verify without disclosure. For KV v2, use `vault kv metadata get PATH`
   when available and approved to inspect version count, key names, and
   timestamps. For KV v1, there is no non-disclosing value read; rely on
   owner-provided operational evidence or a separately approved check. If
   verification is impossible, report the result as inconclusive.

10. Report the result. Return the approved target and operation, the input
    method used without values, verification evidence, service-impact
    considerations, and remaining manual steps. If secret material appeared,
    stop, do not repeat it, recommend rotation, and route to
    `secret-safe-diagnostics`.

## Rotation versus stored-value update

A Vault KV write is only the storage step. Full rotation also requires
issuer-side credential creation, consumer pickup through restart, deploy,
reload, or cache invalidation, and invalidation of the old credential. Do not
call a stored-value update complete rotation unless those steps are evidenced.

## Validation notes for the executing agent

- Any hands-on test of this workflow uses fake secrets on disposable fixtures
  (for example a dedicated demo path in a dev KV mount); each write is
  approved separately. Reading the installed client's `--help` and version
  banner is the only non-gated vault invocation.
- Success means: exactly the approved write ran exactly once at exactly the
  approved path and field, no secret value appeared in agent output,
  transcript, shell history, files, or Git, and verification evidence is
  non-disclosing or honestly reported as unavailable.
