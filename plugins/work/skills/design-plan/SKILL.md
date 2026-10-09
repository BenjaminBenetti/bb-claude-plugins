---
name: design-plan
description: Plan a piece of work interactively with the user, building the plan as an artifact that is updated as the conversation goes. Use when the user has a plan, spec, prompt or ticket and wants a design plan before building.
argument-hint: "[plan, spec, prompt, file path, link or ticket]"
---

# Design Plan

Plan a piece of work together with the user, and build the plan as one artifact that grows as you go.

## Working with the user

This is an interactive planning process. The user designs the solution and directs the work; your job is to research, challenge and record. Do not plan out the solution yourself.

- Start by asking for the plan, spec or prompt the work starts from.
- Before getting down to work, get familiar with the problem space: read the material, then the code and systems it touches. Give the user a short summary of how things work today and what you could not verify, without proposing a solution.
- Wait for the user's direction. Work on the section they pick, and don't move on or fill in sections ahead until they say so.
- Research what the user proposes and check it against the code and systems it touches. Report what you found, including what you could not verify.
- Push back. Poke holes in the user's plan: gaps, risks, wrong assumptions, edge cases and conflicts with how things work today. Be direct; don't just agree.
- Offer alternatives when you see a better or simpler way, each with its trade-off, and leave the choice to the user.
- Put only what the user has agreed on the page. Mark everything else as not decided or not yet checked.
- Build the artifact incrementally. Publish it early, then update it to the same link as each answer or change comes in, so the page always matches the conversation.

## Plan format

Load the `well:architectural-plan` skill before writing the artifact, and follow it for the plan's layout, sections and diagrams. Where it describes its own process, follow this skill for how to work with the user.
