---
name: confluence-page-drafting
description: >-
  Drafts Confluence-ready page content or page revisions from user-provided
  facts, decisions, meeting notes, specs, findings, code references, incident
  timelines, runbook material, or existing Confluence evidence, without
  changing any remote Confluence content. Use for requests such as: "draft a
  Confluence page for this", "turn this into a Confluence page", "write an
  RFC/runbook/incident/design note for Confluence", "prepare a page update
  draft", or "make this Confluence-ready". Establishes site/space/audience,
  deployment and macro/format assumptions, required metadata, source
  citations, and unresolved decisions; produces a page title, summary, body
  structure, metadata, optional change summary, and review questions; marks
  unverified claims, broken links, missing owners, missing dates, permission
  risks, attachment needs, and template requirements as blockers or open
  questions; never invents IDs, links, versioning, macros, attachments,
  labels, or stakeholder approval. Draft only: never creates, updates,
  publishes, comments on, labels, moves, archives, or deletes Confluence
  content. Not for searching existing Confluence content
  (confluence-search-synthesis), publishing or writing Confluence pages
  (confluence-safe-update), repository documentation
  (docs-writer/project-orientation), opencode configuration
  (customize-opencode), or live integration readiness (integration-preflight).
---

# Confluence page drafting

Create clear, reviewable Confluence-ready drafts from supplied material.
Loading this skill grants no permissions and authorizes no Confluence
contact. Drafting is local only unless the user separately authorizes live
read access.

## Scope

Use when the user wants:

- a new Confluence page draft;
- a revised version of an existing Confluence page;
- meeting notes turned into a decision record;
- incident, RFC, design note, runbook, FAQ, onboarding, or process page
  drafts;
- a suggested replacement body for later review;
- a change summary for a proposed Confluence edit.

Use a different capability when:

- the user wants to find existing Confluence pages: use
  `confluence-search-synthesis`;
- the user wants to publish or write to Confluence: use
  `confluence-safe-update`;
- integration readiness, site, tenant, permissions, or write capability is
  unclear: use `integration-preflight`;
- the content is project documentation in a repository: use `project-orientation`
  for repo mapping or `docs-writer` for repo docs;
- the target is opencode configuration: use `customize-opencode`.

Hard boundary: this skill produces drafts. It never performs Confluence
writes.

## Drafting rules

1. **No invented facts.** Do not invent decisions, owners, dates,
   stakeholders, approvals, incident chronology, system behavior, links,
   IDs, labels, versions, templates, macros, or permissions. Mark missing
   items as unknown.
2. **No invented Confluence mechanics.** Do not invent page IDs, space keys,
   version numbers, ancestor pages, parent pages, labels, macro syntax,
   template IDs, attachment IDs, or supported storage format features. State
   assumptions and request confirmation when required.
3. **Deployment-aware.** Establish target deployment when possible: Atlassian
   Cloud, Data Center, or Server. If deployment is unknown, avoid macros and
   format-specific features that depend on it. Use plain Markdown or
   explicitly labeled Confluence storage format only when requested or
   verified.
4. **Audience-aware.** Determine intended audience, purpose, and tone.
   Default to neutral, factual, reviewable documentation.
5. **Separate approved material from proposals.** Do not imply approval that
   did not occur. Mark proposed changes, draft decisions, and unconfirmed
   statements.
6. **Cite supplied evidence.** If the draft rests on user-provided documents,
   code, logs, Confluence pages, specs, or tickets, cite them as sources. If
   no source exists, say the claim is unsupported or mark it as an assumption.
7. **Protect sensitive information.** Do not include credentials, tokens,
   private endpoints, cookies, secrets, connection strings, personally
   identifiable information, or raw logs unless the user explicitly requests
   and sanitizes the content. Prefer placeholders, summaries, or references to
   controlled locations.
8. **Do not include attachments automatically.** If attachments are needed,
   list them as required inputs and leave placeholders. Do not upload, link,
   download, or reference attachment IDs without explicit source data.
9. **Do not follow or embed unverified links.** Include only links supplied
   or verified. Mark broken or unverified links as open questions.
10. **Preserve existing user content when revising.** If revising an existing
    page draft or inspected page content, retain unrelated existing material
    unless the user asked to change it. Provide a focused diff-style change
    summary for substantial edits.

## Required context

Before drafting, establish or mark unknown:

- page purpose and audience;
- target space and deployment, if relevant;
- page type: decision record, incident, runbook, design note, FAQ, process
  guide, meeting notes, or other;
- source material and approved facts;
- required metadata: owner, date, status, labels, related links, affected
  systems, affected customers, or compliance notes;
- desired output format: Markdown, Confluence storage format, outline, or
  review draft;
- whether live Confluence search is authorized, if needed.

If critical context is missing, ask focused questions or produce a draft with
explicit `UNKNOWN` and `OPEN QUESTION` markers. Do not block when a useful
review draft can be created safely.

## Procedure

1. Classify the requested draft type.
2. Identify available sources:
   - user message,
   - local files,
   - inspected Confluence pages if already provided or separately authorized,
   - specs, logs, code references, tickets, meeting notes, or prior drafts.
3. Extract facts and decisions.
   - Separate confirmed facts from assumptions.
   - Mark contradictions.
   - Record missing owner/date/approval/status when relevant.
4. Choose format.
   - Default to Markdown unless Confluence storage format is requested or
     verified.
   - If storage format is requested but deployment or supported macros are
     unknown, mark macros as unverified or avoid them.
5. Draft the page.
   Include:
   - title suggestion;
   - one-paragraph summary;
   - purpose;
   - audience;
   - status or lifecycle note when relevant;
   - key facts, decisions, procedures, or findings;
   - procedures/incident/runbook sections when relevant;
   - ownership and review metadata;
   - related links only when supplied or verified;
   - open questions and unknowns.
6. For revisions:
   - state the exact section being changed;
   - provide before/after or diff-style change summary;
   - preserve unrelated content;
   - flag stale or contradictory content rather than silently rewriting it.
7. Quality check before presenting.
   - Remove unsupported claims.
   - Mark unverified macros, links, IDs, attachments, owners, dates, and
     approvals.
   - Confirm no credentials, secrets, private endpoints, PII, or raw sensitive
     logs are included.
   - Confirm the draft does not imply that a page was saved, published,
     updated, commented on, labeled, or approved.

## Output

Produce:

- title suggestion;
- summary;
- suggested labels/status if supported and supplied;
- body draft;
- metadata block when relevant:
  - space,
  - owner,
  - date,
  - status,
  - affected systems,
  - reviewers,
  - related links;
- change summary for revisions;
- open questions and blockers;
- suggested next step, such as "review this draft", "fetch existing page
  content", or "use confluence-safe-update only after exact target and payload
  are approved".

Do not describe the draft as saved or published.
