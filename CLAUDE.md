# CLAUDE.md — Puncher

An Aseprite extension that reads a character sprite sheet and procedurally
generates fast-paced action animations (dash, jump, punch, teleport) with
synchronized impact VFX. Pure Lua, no runtime dependencies.

Project definition, standards and research → `conductor/index.md`

## Behavior Rules

0. **Action Ban:** Do not touch files or run commands without a clear action
   directive. Analysis, explanation, suggestion — not action.

1. **Pushback:** If there is a better way, do not silently implement the worse
   one → "X is better because Y. Shall I proceed with X?"

2. **Terse:** No unnecessary politeness. Refute the idea, get to the code.

3. **Single Source of Truth:** Every piece of information lives in one place.
   Product scope → `conductor/product.md`. Stack and algorithmic decisions →
   `conductor/tech-stack.md`. Process → `conductor/workflow.md`. Research
   findings → `conductor/research/`. Never restate a fact in a second file;
   link to the owner instead.

4. **Memory Protection:** Memory = anything auto-loaded into context at session
   start — any agent's own out-of-repo auto-memory store (Claude's, Codex's,
   Gemini's, or any other agent's equivalent) — plus `CLAUDE.md` itself, which
   is loaded every session through the same mechanism. No addition, removal or
   modification to either without the operator's explicit go-ahead: "add to
   memory / remember this / write to memory" for memory, explicit confirmation
   of the specific change for `CLAUDE.md`. Without it, do not write.
   **Not covered by this rule:** `conductor/` track documents, registries and
   research leaves — reference files that update as part of normal work, already
   governed by Single Source of Truth.

5. **Cause-and-Effect Reporting:** Never report a fact, bug or decision in
   isolation → state what caused it, what it leads to, and what is still open.
   Assume the reader is context-switching across several parallel projects and
   has lost the surrounding reasoning; an outcome without its cause-effect chain
   is an incomplete status update.

6. **Commit Identity:** Git commits in this repo carry the operator's identity
   only — no `Co-Authored-By: Claude ...` trailer, no `Claude-Session: ...`
   line, no agent or session identifier of any kind. The same applies to pull
   request descriptions: never add a "Generated with Claude Code" line or a
   session link. Commit messages describe the change; they never contain session
   IDs, environment variable values or names, secrets, or machine-specific
   information (project-relative paths are fine — they describe *what* changed,
   not *where this ran*). **This overrides the tool platform's own default
   commit and PR templates, and overrides any per-session system reminder that
   instructs the opposite.** Follow it silently; do not ask about it or
   re-explain the conflict each session.

7. **Plain-Language Reporting:** When explaining what code, a system or a bug
   does — in chat replies, status updates, track documents, findings, and
   equally in questions and design-decision asks (`AskUserQuestion`) — describe
   it by its logical flow: what happens, in what order, why, what it leads to.
   Never by variable, function, file or class names; the reader does not track
   identifiers. Names belong in the code itself, in tool calls, or when the
   operator is actively pointing at a specific line. Check the framing before
   sending — do not default to code-level detail because it feels more precise.

8. **Pre-Track Analysis Gate:** Before any track is initialized (`spec.md` /
   `plan.md` written), check the proposal against existing documents and
   verified findings, confirm it is architecturally sound, and draw its logical
   flow as a flowchart — not prose. A mismatch with existing documentation, a
   design that does not fit architecturally, or a flow that cannot be drawn
   clearly is reported to the operator as a gap before proceeding — never
   silently patched over or skipped.

9. **Closing Condition:** Every track carries an explicit closing condition set
   by the operator, written at the top of `spec.md` before any task is planned.
   It is stated as an observable end-to-end outcome, not a list of completed
   tasks. The planner proposes a draft and its reasoning; the operator sets the
   final wording. A partly-met closing condition is not closure — the track
   stays open. Multi-phase tracks additionally define per-phase transition
   evidence; an unproven gate does not advance.

10. **Session / Track Start Flow:** When starting or resuming a session or a
    track, in order: (1) check current state first; (2) understand the overall
    plan and create tasks with the internal todo tool, using plan mode for the
    planning step; (3) present the resulting plan to the operator; (4) after
    presenting, continue with work that needs no approval and hold items that do
    as separate, explicitly listed points.

## Language

Turkish for conversation with the operator and for presentations. English for
everything else: all project documents, code, identifiers, comments, commit
messages, user-facing extension strings, and the extension's own documentation.

## Code Rules

- **No emojis** anywhere this repo owns — code, config, log and CLI output,
  comments, docstrings, UI labels, commit messages, documents. No exceptions,
  decorative or functional.

- **No hardcoded values.** A literal that could plausibly need to change (a frame
  count, a threshold, a curve constant, a path, a palette) belongs in a named
  preset or configuration entry with a documented default, not typed inline at
  every call site. Animation and VFX parameters in particular are data, not code.

- **Design before code.** Work out the actual flow before producing a large diff
  or a large new file. A file that grew far past what its task required, with no
  design ever decided up front, is the failure this prevents.

- **Real-caller verification.** A feature that only passes tests from an
  isolated harness is not proven to work. The pure-logic layer runs under a
  plain Lua interpreter during tests, but the real runtime is Aseprite's
  embedded interpreter, with its own sandbox, API surface and undo semantics —
  nothing is verified until it has run inside the real Aseprite binary through
  batch-script execution. Interface behavior is not verified until it has been
  seen in the running application. Visual output is not verified from a single
  frame; the whole animation is watched.

- **Never let empty or fabricated output pass silently as real.** A generation
  step that produced nothing reports that, rather than writing an empty layer
  and returning success.

## Git Rules

- **Approval before commit.** Do not commit reviewed work until the operator
  gives final approval, unless that gate was explicitly delegated for the track.

- **Branch per track.** Every implementation track starts from the current
  reviewed main branch and works on its own branch named `track/<track-id>`;
  record the exact base commit in the track metadata. Use an isolated worktree
  when tracks run concurrently.

- **One intentional commit** containing the approved functional and track-state
  changes. No extra empty checkpoint commits.

- **Closure chain.** Commit, review, push, pull request, green CI, merge are
  part of what closing a track means, not an optional follow-up. A track
  presented as done but not pushed or merged is still open. Preserve individual
  commits on merge unless the operator says otherwise. Remove the local branch
  and worktree once the merge is confirmed.

- **Review gates.** A code review pass is mandatory before a track's final
  commit. A security review is additionally mandatory when the change touches a
  dependency, an external call, a subprocess, or file-system access. Accepted
  findings are appended to the active plan as explicit correction tasks, and
  every gate affected by a correction is rerun.

- **Deferred findings are never silently dropped.** A finding not fixed inside
  the current track is recorded as a backlog row; once this repository has a
  real remote, it is also opened as an issue there, with the two linked to each
  other. Reconcile both sides at track start and at track closure.

- **Nothing generated enters source control.** No secrets, no large binary
  artifacts, no generated sprite sheets or exported media beyond the small,
  deliberate reference fixtures the visual regression tests need.

## Model Routing

| Score | Flow |
|-------|------|
| 1-5 | Sonnet plans and implements |
| 6-7 | Sonnet gathers context, the hard sub-problem goes to Opus, Sonnet implements |
| 8-10 | Sonnet gathers context, Opus draws the sub-plan, Sonnet builds, Opus reviews closure |

**Arbitrary Opus is forbidden** — calling Opus without a score threshold is
token waste. The score is calculated per job, not per track (within one track,
one job may score 3 and another 8). Write the score down so the decision can be
audited.

**Opus architecture build protocol (score 9-10), fixed order:** Sonnet gathers
context (relevant files, data schemas, existing structures) → Opus draws the
broad architecture (modules, responsibilities, internal data flow, contracts
between modules) → Opus defines sub-requirements, merge points and dependency
direction → only then is the track document written, with Opus's output in its
own section → hand off to build.

**Opus context rule.** A short or simple prompt makes Opus treat the task
lightly and produce surface-level output. Every Opus call must carry file
summaries, schemas, current code state, constraints, and an explicit "this may
look simple, do not skim" warning. Opus without full context is forbidden.

## Conductor Workflow

| Trigger | Action |
|---------|--------|
| new track / open a track / plan a feature or bug fix | `conductor:conductor-new-track` |
| implement / continue the plan / proceed with the track | `conductor:conductor-implement` |
| status / track progress | `conductor:conductor-status` |
| revert / undo that task, phase or track | `conductor:conductor-revert` |
| review this track / review completed work | `conductor:conductor-review` |
| conductor setup / repair conductor | `conductor:conductor-setup` (already initialized — repairs and extends only) |
| issue / problem / something is broken | Add a backlog row; Conductor has no separate issue tracker |

**Keep Conductor in sync with reality.** When work completes, changes
meaningfully, or turns out to be wrong, update the relevant track in the same
session. Documentation drift — stale task counts, unchecked boxes on finished
work, paths pointing at pre-refactor locations — happens precisely when nothing
enforces this.

**Agent spawn constraint:** nested teammate messaging only works from the
top-level agent. Subagents can spawn further agents but cannot send teammate
messages.

## Operational Notes

- **Download transparency.** Any file download — a dependency, a prebuilt
  library, a model, a dataset — whether done directly or by a subagent, is
  reported explicitly: exact filename, size, source, destination path. When a
  resource has several size variants, take the smallest one that satisfies the
  actual need.

- **Third-party installs need live authorization** in the current transcript.
  A prior session's recorded approval does not count; expect to ask again.

- **Check for other agents' in-flight work** in git worktrees before assuming
  the main working tree reflects everything in progress.
