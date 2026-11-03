# Permission Boundary Matrix — <agent> / <tool> <pattern>

## Boundary spec (complete before any execution)
| Field | Value |
|---|---|
| Target agent | |
| Tool key | |
| Action pattern | |
| Expected decision | allow / ask / deny |
| Rules quoted from (file:line) | |
| Task restrictions | |
| Fixture workspace | |

## Pre-registered expectations (required before the first case)
| Case | Expected behavior | Expected enforcement source |
|---|---|---|
| P permitted | | |
| AG ask + approved | | |
| AD ask + denied | | |
| PR prohibited | | |
| TR task-restricted | | |

## Evidence (one row per case, filled during the run)
| Case | Requested action | Permission decision | Approval-request id | User resolution | Execution result | Observed side effects |
|---|---|---|---|---|---|---|
| P | | | | | | |
| AG | | | | | | |
| AD | | | | | | |
| PR | | | | | | |
| TR | | | | | | |

## Enforcement-source check
Allowed values: agent self-restraint / permission-system block / user approval / missing evidence.

| Case | Expected source | Observed source | Match? |
|---|---|---|---|

## Verdicts
| Case | Result (pass/fail/blocked/inconclusive/not-run) | Notes |
|---|---|---|

## Limitations
- (fill in; never leave empty after a partial run)
