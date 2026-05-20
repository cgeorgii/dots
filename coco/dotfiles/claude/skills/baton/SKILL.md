---
name: baton
description: Orchestrates multi-phase implementation tasks by breaking large features into compiler-clean batches and delegating each batch to focused sub-agents. Use when implementing a language feature, refactor, or any change that touches many files.
user-invocable: true
---

# Baton: Multi-Phase Implementation Orchestrator

You never read, write or edit code/documentation yourself unless explicitly asked to. All code changes happen inside sub-agents you spawn via the Agent tool.

## Core Principles

- Each batch must leave the codebase in a compiler-clean state (no errors, warnings are acceptable).
- Batches should be cohesive: group changes by dependency order so later batches can build on earlier ones without rework.
- Never ask a sub-agent to implement steps beyond its assigned batch — state the constraint explicitly in the prompt.
- When the plan has gaps or ambiguities, spawn an investigation agent first to fill them in before writing a single line of code.
- Do not commit anything. Leave that to the user.
- Do not create a worktree. All work happens in the current working directory.

## Phase 0 — Understand the task

Read the plan (if one is given) or extract requirements from the user's request. Identify:
- The full set of files likely affected
- The order of changes (what must exist before what)
- Any type names, function signatures, or module interfaces that need to be pinned before implementation begins
- Ambiguities or gaps that need investigation

If there are gaps, go to Phase 1. Otherwise skip to Phase 2.

## Phase 1 — Investigation (when needed)

Spawn an investigation agent with this shape:

```
You are a codebase investigator. Your job is to answer specific questions needed to plan an implementation — do NOT make any code changes.

Questions to answer:
<list the specific unknowns>

Codebase context:
<relevant file paths, module names, existing types>

Return your findings as a structured list. For each question: the answer, the file:line evidence, and your confidence.
```

Incorporate the findings into your plan before proceeding.

## Phase 2 — Batch planning

Produce a numbered batch list. For each batch:
- A short name (e.g. "Batch 1: AST nodes for new effect syntax")
- The files to create or modify (absolute paths)
- The type names and function signatures to add or change
- The acceptance criterion (what `tricorder` output confirms it compiled)
- Status: `[ ] pending`

Create a task for each batch using `TaskCreate` so you can track progress across the session.

## Phase 3 — Execute batches in order

For each batch:

**3a. Spawn an implementation agent.**

Give it a prompt that includes:
- The exact files to touch (absolute paths)
- The precise types and signatures to implement
- Relevant context: existing types it must align with, conventions from CLAUDE.md, imports it will need
- An explicit constraint: "Do not implement anything beyond this batch. Stop after completing the items listed above."
- The instruction to run `hpack` after adding new modules (the project uses hpack; never edit `.cabal` directly)
- If working on a haskell codebase, direct the agent to use /tricorder

Example agent prompt structure:
```
You are implementing Batch N of a multi-batch task: <batch name>.

## What to implement
<itemised list with file paths and specific signatures>

## Context
<paste relevant existing types, function signatures from adjacent code>

## Constraints
- Only implement the items listed above. Do not implement anything from later batches.
- This is a Haskell project. Follow the conventions in CLAUDE.md.
- Use hpack to regenerate the .cabal file if you add new modules (run `hpack` in the repo root).
- Do not commit.

## Done when
<describe what a clean tricorder output looks like for this batch>

## Report
When finished, write a brief structured report:
- What was implemented (per item in the plan)
- Any deviations from the plan (missing items, changed signatures, unexpected decisions)
- Anything the orchestrator should know before proceeding to the next batch
```

**3b. Verify compilation.**

After the implementation agent finishes, run tricorder to check for errors:

```bash
tricorder status --wait
```

If there are errors, read the error output carefully. Either:
- Spawn a small fix agent with the exact errors and the files involved, or
- If the errors are structural (wrong design), revise the plan and re-delegate.

**3c. Review the batch report.**

Read the sub-agent's report. Flag anything suspicious:
- Deviations from the plan (changed signatures, skipped items)
- Decisions that may affect later batches

If the report mentions deviations or the build has warnings that suggest something is off, run `git diff HEAD` to inspect the diff directly. Spawn a targeted correction agent if needed before moving on.

**3d. Mark the batch done.**

Mark the batch task as completed using `TaskUpdate`. Print a brief summary: what was done, any deviations from the plan, and what comes next.

## Phase 4 — Semantic review

Before spawning the review agent, confirm that the build is clean and all tests pass:

```bash
tricorder status --wait
```

Do not proceed to the review if there are errors or failing tests — fix them first (returning to Phase 3 as needed).

Once the build is clean, collect any relevant references before spawning the review agent — these include papers being implemented, vendored source code being ported, specs, or RFCs. Do not search for or read references yourself; if they are not already known from the task description or conversation context, spawn a short investigation agent to locate them first. Pass the references to the review agent so it can cross-check the implementation against the original source.

Spawn a review agent with this shape:

```
You are a code reviewer. Your job is to assess whether the implementation is semantically correct and complete. Do NOT worry about compilation or build status — focus entirely on correctness and completeness.

## What was implemented
<summarise the feature/change and list the files modified>

## References
<list any papers, vendored code, specs, or RFCs that the implementation is based on, with file paths or URLs>

## Review checklist
- Does the implementation match the original requirements?
- If references are provided: read them and verify the implementation faithfully follows the source material — flag any deviations, omissions, or misinterpretations.
- Are there missing cases, untested edge cases, or incomplete logic?
- Are the tests (if any) meaningful — do they actually exercise the behaviour they claim to?
- Is anything left as a stub or TODO that should be complete?

Return your findings as a structured list of: observations, severity (info / concern / blocker), and suggested fix if applicable.
```

If the review surfaces blockers or concerns, spawn a targeted correction agent before proceeding. Minor observations can be noted for the user without blocking progress.

## Phase 5 — Final verification

After all batches are complete:
1. Run `tricorder status --wait` one final time and confirm zero errors.
2. Run `git diff HEAD` and do a final review pass.
3. Report to the user: what was implemented, which files changed, and any deviations from the original plan.
4. Remind the user to review the diff and commit when satisfied.

## Rules for sub-agent prompts

- Always include absolute file paths — never relative.
- Always paste the relevant existing types/signatures so the agent has context without needing to search.
- Always state the "do not implement beyond this batch" constraint explicitly.
- Keep each batch small enough that a single agent can hold it in context. If a batch would touch more than ~8 files or ~500 lines, split it.

## What to do when tricorder is unavailable

If `tricorder status` fails because the daemon is not running, fall back to:
```bash
cabal build 2>&1 | tail -40
```
