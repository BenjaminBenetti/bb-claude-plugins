---
name: prd-to-tickets
description: Break a PRD down into requirement-focused tickets linked back to its SD ticket. Use when the user supplies a PRD (URL or document) and wants tickets created from it in their issue tracker.
argument-hint: "<prd-url> [sd-url] [instructions, e.g. ticket count]"
---

# PRD to Tickets — Break a PRD into Requirement Tickets

Read a PRD, extract its requirements, and create the tickets that deliver it,
linked back to the SD (discovery / Solution Design) ticket the PRD belongs to.
Tickets describe **what** is required — never **how** to build it.

## Arguments

`$ARGUMENTS` — a PRD URL, optionally an SD ticket URL, optionally followed by
extra instructions.

- **PRD URL** (required): the product requirements document (Confluence page,
  Google Doc, Notion page, or any fetchable URL).
- **SD URL** (optional): the discovery / Solution Design ticket this PRD came
  from (e.g. `https://<site>.atlassian.net/browse/SD-123`). If omitted, locate
  it (Step 2).
- **Instructions** (optional): free-text guidance on how to split the work —
  most commonly how many tickets to make ("as 3 tickets", "one ticket per
  screen", "a single ticket"). Honor these when planning in Step 3. May also
  include assignment ("assign to me", "assign to <name>") — handled in Step 5.

If the PRD URL is missing, ask the user for it.

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

## Step 2: Find the SD ticket

Everything created in this skill hangs off the SD ticket, so identify it first.

- **SD URL given**: read it (for Jira, extract the issue key and use
  `getJiraIssue`). Confirm it's the right item — its summary/description should
  match the PRD's subject.
- **SD URL not given**: locate it. Search the discovery project for the PRD's
  title and feature keywords, and check whether the PRD itself is linked from,
  or links to, a tracker item. Use whatever signal is available — a delivery
  ticket for related work that already links to an SD tells you which project
  the SD items live in and what link type is used.

**If you can't find it, or several candidates match and none is clearly right,
tell the user.** List the near-matches you found and ask which SD to use (or
whether to proceed without one). Never invent an SD link and never silently
skip it.

From the SD (and from delivery tickets already linked to SDs in that project),
note:

- The **delivery project** new tickets should be created in. If it isn't
  determinable, ask the user which project to create in — don't guess.
- The **link type** used between delivery items and SD items, verbatim, and
  which side is inward vs. outward. The delivery item *implements* the SD item;
  confirm the direction against an existing linked pair rather than inferring
  it from field names.

Also check what the SD already has linked. If a requirement from the PRD is
already covered by an existing linked ticket or epic, do not create a
duplicate — mention the overlap to the user instead.

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

The number of tickets determines the structure created in Step 4 — plan the
split first, then apply the matching shape.

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

## Step 4: Structure — how the SD, epic, and tickets connect

The shape depends entirely on how many tickets the PRD needs.

**One ticket satisfies the SD → `SD → Ticket`**

Create the single ticket in the delivery project and link it directly to the
SD. **Do not create an epic**, and do not parent the ticket to an existing one.
A lone ticket hangs off the SD on its own.

**More than one ticket is required → `SD → Epic → Tickets`**

1. Create an **epic** in the delivery project. Its summary names the capability
   the PRD delivers; its description is a short scope summary in plain
   language. The same content rules apply — no technical details, no PRD link.
2. Link the **epic** to the SD, using the link type and direction learned in
   Step 2.
3. Create each ticket with that epic as its **parent**.
4. **Do not link the individual tickets to the SD** — the epic carries that
   link. The SD reaches the tickets through the epic.

## Step 5: Confirm, Then Create

Present the plan to the user before creating anything: the SD ticket you'll
link to, whether this is a single ticket or an epic with N tickets, and the
proposed ticket summaries with a one-line gist of each. Confirm, then create.

- For Jira: `createJiraIssue` in the delivery project. Use the project's
  standard ticket type for feature work (usually **Story**; fall back to
  **Task** if the project has no Story type — check with
  `getJiraProjectIssueTypesMetadata` if unsure), and **Epic** for the epic.
- Create the epic first when there is one, so tickets can be created with it as
  parent in a single pass.
- Match visible project conventions (labels, components) from comparable
  existing tickets when they clearly apply.

### Match sibling conventions — sprint and assignee

A freshly created ticket won't behave like the project's other tickets unless it
carries the same board/sprint and assignment conventions. Apply these right
after creating each ticket, before reporting.

**Discover every value from comparable existing tickets — never assume one.**
Field ids, project keys, and sprint ids differ per site and drift over time
(sprints roll over, fields get renamed). An existing ticket in the delivery
project is the source of truth: read one, see what it carries, reproduce it.

**When a value can't be determined, ask the user — never guess and never
silently skip it.** If the project genuinely doesn't use a convention (no
sprints at all), that's an answer: skip it and say so in the report. But if
other tickets clearly use it and you can't work out the value, stop and ask.

#### Sprint (so it appears on the board)

Board-based projects only show tickets that are in a sprint. If comparable
tickets sit in sprints, put each new **ticket** in the **currently active** one.
Epics are not put in sprints.

1. Identify the Sprint field id — it's a custom field whose id varies by site.
   Read an existing ticket with `expand: "names"` and find the field named
   "Sprint".
2. Find the open sprints for the project (a JQL search on `sprint in
   openSprints()`, returning that sprint field). Use the sprint whose `state` is
   `active`. A sprint can stay `active` past its end date until it's formally
   closed, and a newer one may already be open — always take the one currently
   `active`, not the one matching today's date.
3. Set it on create via `additional_fields`, keyed by the discovered field id,
   with the numeric sprint id as the value.
4. **No active sprint found** — the project uses sprints but none is currently
   `active`, several look active, or the sprint field can't be identified —
   **ask the user which sprint to use** (or whether to leave the tickets out of
   a sprint) before creating. Don't fall back to the newest, the closest-dated,
   or a closed sprint.

#### Assignee

If the user asked for an assignee ("assign to me", or a named person), set it on
the tickets. Resolve the person to their account id from the SD or from existing
tickets (`assignee`/`reporter`) rather than assuming their login email matches
their tracker email. Pass the account id on create. If the user didn't ask,
leave the assignee as the project default.

### Verify

Re-read everything created — the epic (if any), each ticket's parent, sprint
field, assignee, and the SD link — and confirm the structure is right:

- Single ticket: linked to the SD, **no** parent epic.
- Multiple tickets: the epic linked to the SD in the correct direction, every
  ticket parented to that epic, and no ticket linked directly to the SD.

If the create call rejects the SD link type, ask the user rather than
substituting a different type on your own. Only use a generic "Relates"
fallback if they approve it, and flag it in the report.

## Step 6: Report

Report the structure that was created:

- **Single ticket**: the ticket key, URL, sprint, assignee, and the SD it links
  to.
- **Epic + tickets**: the epic key, URL, and the SD it links to; then each
  ticket with its key, URL, sprint, and assignee, listed under the epic.

Note any PRD requirements that were intentionally skipped (already covered,
out of scope, or explicitly excluded by the PRD) and why.
