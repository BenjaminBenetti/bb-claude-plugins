---
name: prd-to-tickets
description: Break a PRD down into requirement-focused tickets under an epic. Use when the user supplies a PRD (URL or document) and wants tickets created from it in their issue tracker.
argument-hint: "<prd-url> <epic-url> [instructions, e.g. ticket count]"
---

# PRD to Tickets — Break a PRD into Requirement Tickets

Read a PRD, extract its requirements, and create one or more tickets under a
given epic. Tickets describe **what** is required — never **how** to build it.

## Arguments

`$ARGUMENTS` — a PRD URL and an epic URL, in either order, optionally followed
by extra instructions.

- **PRD URL**: the product requirements document (Confluence page, Google Doc,
  Notion page, or any fetchable URL).
- **Epic URL**: the epic the tickets belong to (e.g. a Jira epic URL like
  `https://<site>.atlassian.net/browse/ABC-123`).
- **Instructions** (optional): free-text guidance on how to split the work —
  most commonly how many tickets to make ("as 3 tickets", "one ticket per
  screen", "a single ticket"). Honor these when planning in Step 3. May also
  include assignment ("assign to me", "assign to <name>") — handled in Step 4.5.

If the PRD URL is missing, ask the user for it. If the epic URL is missing,
**ask the user which epic the tickets should go in** — never guess an epic and
never create tickets outside of one.

## Step 1: Read the PRD

Fetch the PRD content:

- **Confluence URL**: use the Atlassian MCP tools (`getConfluencePage`) —
  extract the page ID from the URL.
- **Any other URL**: use WebFetch (or the matching MCP tool for that product).

Read the whole document. Identify the goal, the user-facing requirements,
acceptance conditions, and any explicit scope exclusions. Take note of which
parts are *requirements* (user-visible behavior, business rules, constraints)
versus *technical design* (architecture, APIs, data models, technology
choices) — the latter must NOT appear in tickets.

Also collect any **design links** the PRD contains — Claude Design shares,
Figma files, mockup/prototype URLs — and note which requirement each one
belongs to, so they can be carried into the right tickets.

## Step 2: Read the Epic

Fetch the epic (for Jira, extract the issue key from the URL and use
`getJiraIssue`):

- Confirm it exists and note its project, so tickets are created in the right
  place.
- List its existing child issues. If a requirement from the PRD is already
  covered by an existing child ticket, do not create a duplicate — mention the
  overlap to the user instead.

## Step 3: Plan the Tickets

Group the PRD's requirements into 1 or more tickets. If the arguments include
splitting instructions (a ticket count, a per-screen/per-feature split), follow
them — if the requested count genuinely doesn't fit the PRD (e.g. 10 tickets
asked of a one-line PRD), say so and propose a better split instead of padding.
Each ticket should be:

- **Independently deliverable** — a coherent slice of functionality, not an
  arbitrary fragment.
- **Requirement-only** — describes user-visible behavior, business rules, and
  acceptance criteria.

### Ticket content rules (hard requirements)

1. **No technical details.** Exclude implementation approach, architecture,
   service/class/API/database names, technology choices, and any "how it will
   be built" content from the PRD. If a requirement is only stated technically
   in the PRD, rephrase it as the user-observable outcome.
2. **No PRD link.** Do not link or embed the full PRD in the ticket — no URL,
   no attachment, no "see PRD" reference. The ticket must stand on its own.
3. **Design links ARE included.** If the PRD links to designs (Claude Design
   shares, Figma, mockups/prototypes), put each design link in the ticket(s)
   covering that requirement — a **Design** line or section with the URL(s).
   This is the one kind of link that belongs in the ticket; it does not
   violate the no-PRD-link rule.
4. Each ticket gets:
   - A short, action-oriented **summary** (what capability is being delivered).
   - A **description** with the requirement in plain language and a bulleted
     **Acceptance Criteria** section phrased as observable behavior
     ("When X, the user sees/can Y").

## Step 4: Confirm, Then Create

Present the proposed ticket list (summaries + one-line gist of each) to the
user and confirm before creating anything.

On confirmation, create each ticket in the epic:

- For Jira: `createJiraIssue` in the epic's project, with the epic as parent.
  Use the project's standard ticket type for feature work (usually **Story**;
  fall back to **Task** if the project has no Story type — check with
  `getJiraProjectIssueTypesMetadata` if unsure).
- Match any project conventions visible on the epic's existing children
  (labels, components) when they clearly apply.

## Step 4.5: Match sibling conventions — sprint, assignee, and discovery link

A freshly created ticket won't behave like the epic's other children unless it
carries the same board/sprint, assignment, and discovery-link conventions. Apply
these right after creating each ticket, before reporting.

**Discover every value from the epic's existing children — never assume one.**
Field ids, link type names, project keys, and sprint ids differ per site and
drift over time (sprints roll over, fields get renamed). A sibling ticket is the
source of truth: read one, see what it carries, reproduce it.

**When a value can't be determined, ask the user — never guess and never
silently skip it.** If the siblings genuinely don't use a convention (no sprints
at all, no discovery links anywhere), that's an answer: skip it and say so in
the report. But if the siblings clearly use it and you can't work out the value,
stop and ask.

### Sprint (so it appears on the board)

Board-based projects only show tickets that are in a sprint. If the siblings sit
in sprints, put each new ticket in the **currently active** one:

1. Identify the Sprint field id — it's a custom field whose id varies by site.
   Read a sibling with `expand: "names"` and find the field named "Sprint".
2. Find the open sprints for the project (a JQL search on `sprint in
   openSprints()`, returning that sprint field). Use the sprint whose `state` is
   `active`. A sprint can stay `active` past its end date until it's formally
   closed, and a newer one may already be open — always take the one currently
   `active`, not the one matching today's date.
3. Set it on create via `additional_fields`, keyed by the discovered field id,
   with the numeric sprint id as the value.
4. **No active sprint found** — the siblings are in sprints but none is
   currently `active`, several look active, or the sprint field can't be
   identified — **ask the user which sprint to use** (or whether to leave the
   tickets out of a sprint) before creating. Don't fall back to the newest,
   the closest-dated, or a closed sprint.

### Assignee

If the user asked for an assignee ("assign to me", or a named person), set it.
Resolve the person to their account id from the epic or its existing children
(`assignee`/`reporter`) rather than assuming their login email matches their
tracker email. Pass the account id on create. If the user didn't ask, leave the
assignee as the project default.

### Discovery / Solution link

If the epic's children link out to a discovery or Solution ticket, every new
ticket needs the same link to the item it implements.

1. **Learn the convention from a sibling.** Read an existing child's
   `issuelinks` and note the discovery project it points at, the issue type
   there, and the exact link type name used. Reuse that link type verbatim.
2. **Find the matching discovery ticket** by searching that project for the
   feature's keywords. A PRD usually maps to one primary item; individual
   requirements sometimes have their own.
3. **Get the direction right.** The delivery ticket *implements* the discovery
   ticket, so it goes on the inward side and the discovery ticket on the
   outward side — confirm against the sibling's link before creating, since the
   labels are what the sibling shows, not what the field names suggest.
4. **Multiple matches:** link each item a ticket genuinely spans; otherwise link
   only the single matching one — don't over-link.
5. **No matching ticket found** — nothing in the discovery project matches, or
   several candidates match and none is clearly right — **don't invent a link
   and don't leave it out silently.** Tell the user which ticket has no
   counterpart (listing any near-matches you found) and ask how to proceed:
   which item to link, or to create the ticket unlinked.
6. **Link type unclear** — the siblings' link type can't be reproduced, or the
   create call rejects it — ask the user rather than substituting a different
   type on your own. Only use a generic "Relates" fallback if they approve it,
   and flag it in the report.

### Verify and report

Re-read each created ticket — sprint field, assignee, issue links, and parent —
and confirm it matches the siblings: in the active sprint, assigned to the right
person, and linked to the right discovery ticket(s) in the right direction.
Report the sprint, assignee, and link(s) per ticket in Step 5.

## Step 5: Report

List the created tickets with their keys and URLs, grouped under the epic. For
each ticket, report its sprint, assignee, and linked SD ticket(s).
Note any PRD requirements that were intentionally skipped (already covered,
out of scope, or explicitly excluded by the PRD) and why.
