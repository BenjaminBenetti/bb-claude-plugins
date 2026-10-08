---
name: design-plan
description: Plan a piece of work as one HTML artifact covering where it fits, the decisions to make, what to build, and how to roll it out. Use when the user has a plan, spec, prompt or ticket and wants a design plan before building.
argument-hint: "[plan, spec, prompt, file path, link or ticket]"
---

# Design Plan

Produce one HTML artifact that plans a piece of work: where it fits, the choices to make, what to build, and how to roll it out. Every plan has the same shape, so readers learn the layout once.

## Output shape

### Top of the page

- A small label line: the area, "design plan" and the date.
- A title naming what is being planned.
- Two or three sentences on what this is and why it matters.
- An **Assumed, not yet checked** box listing every fact the plan relies on that nobody has verified, and why.

### Decisions sidebar

Beside the tabs, a sidebar lists the plan's decisions, grouped by topic. Each shows a short question, two or three options with a one-line trade-off each, and the agreed answer. A decision not yet made says "Not decided" and names the recommended option.

### Tabs, in this order

1. **Overview** (always first): an architecture diagram of the existing system with the new and changed parts in place, then one request or data path drawn today and after. When a decision picks between two designs, show them side by side with the chosen one marked.
2. **One tab per key area** that has to be designed, built or decided, such as data, message flow, deployment or migration. Each opens with a sentence carrying its main point, then at least one diagram.
3. **Risks** (optional): a list of the risks the plan leaves open. Leave the tab out when there are none.
4. **Solution Components** (second to last): a table of component, status (exists, needs changes, missing, check), where it lives (the service, repository or module) and notes.
5. **Deployment plan** (always last): how the work moves through the SDLC to production.
   - a timeline of the environments in order (for example dev, QA, staging, production) and what must pass before moving to the next;
   - QA testing: the test steps and the expected result of each;
   - verification after each deployment, and how to roll back if it fails;
   - open questions that block release.

### Diagrams

- Use several kinds across the plan: an architecture or flow diagram, a today-and-after view, a step-by-step sequence and the deployment timeline.
- Group boxes by owner, such as a repository, a team or "Outside".
- Give every box one status, and give each diagram a legend for the statuses it uses: **exists**, **assumed, check** (unverified, drawn dashed), **exists, needs changes**, **new**, **not used** (left out by the agreed choices).
