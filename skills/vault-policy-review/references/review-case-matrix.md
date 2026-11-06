# Vault policy review case matrix

Use this template to keep a policy review concrete. All names below are
fake examples.

## Case matrix template

| Case | Identity assumption | Operation | Path | Expected | Verification type | Result |
|---|---|---|---|---|---|---|
| happy path | app role | read one secret | `dev-kv-example/data/example-app/db-config` | allow | inspection or approved capability probe | not run |
| negative read | app role | read sibling secret | `dev-kv-example/data/example-app/other` | deny | inspection | not run |
| negative write | app role | update secret | `dev-kv-example/data/example-app/db-config` | deny | inspection | not run |
| discovery only | app role | list metadata | `dev-kv-example/metadata/example-app/*` | allow only if discovery required | inspection or approved capability probe | not run |
| lifecycle | operator role | soft delete latest | current version docs define exact path | explicit decision | docs plus approved live check | not run |
| token lifecycle | app role | renew own lease | lease path required by app | explicit decision | inspection | not run |

## Example: KV v2 read-only application secret

Requirement: an application reads one database config secret and does
not list siblings or write values.

Fake path: `dev-kv-example/data/example-app/db-config`.

Minimal policy:

```hcl
path "dev-kv-example/data/example-app/db-config" {
  capabilities = ["read"]
}
```

Findings:

- Allow: read the exact secret data path.
- Deny: update, patch, delete, list, or read any sibling.
- Unverified: whether the app actually has this policy, inherits it
  through a group, or is limited by namespace or parameter constraints.

## Example: operator lifecycle access

Requirement: an operator may read a KV v2 secret and permanently destroy
specific versions. Do not infer one policy from the other; keep separate
path prefixes and confirm exact capabilities for the installed Vault
version.

```hcl
path "dev-kv-example/data/example-app/db-config" {
  capabilities = ["read"]
}
```

Do not add metadata, `delete/`, `undelete/`, or `destroy/` paths unless
the final proposal confirms the operation is required and the target
Vault version's docs or CLI help confirm the exact capability mapping.

## Approval gates

Before any live check:

1. Confirm exact target path.
2. Confirm the check does not retrieve secret values.
3. Confirm the token source is approved and no token value is printed.
4. Run help only if syntax is uncertain.
5. Run capability check only after user approval.
