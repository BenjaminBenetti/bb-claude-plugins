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
  screen", "a single ticket"). Honor these when planning in Step 3.

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

## Step 5: Report

List the created tickets with their keys and URLs, grouped under the epic.
Note any PRD requirements that were intentionally skipped (already covered,
out of scope, or explicitly excluded by the PRD) and why.
