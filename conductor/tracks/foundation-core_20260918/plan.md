# Implementation Plan — Track 1: Foundation and Mathematical Core

Every task follows the lifecycle in `conductor/workflow.md`: mark in progress,
write a failing test, implement the minimum to pass, refactor, verify coverage,
commit, attach the task summary as a git note, record the commit, commit the
plan update.

## Phase 1 — Development Environment and Skeleton

- [x] Task: Install and record the development tooling `bc05b5a`
  - [x] Confirm the Lua interpreter version matches the one Aseprite embeds
  - [x] Install the linter, the unit test library and the coverage tool into a
        user-local package tree, with explicit operator authorization
  - [x] Install the formatter binary, with explicit operator authorization
  - [x] If a coverage tool cannot be installed, stop and amend the coverage
        target in the process document before continuing (not needed: the
        coverage tool installed cleanly)
  - [x] Write the exact commands into the Development Commands section of the
        process document

- [x] Task: Create the source layout and its boundary `9d6f54c`
  - [x] Create the core, adapter, commands, presets, assets and tests
        directories with a short note in each stating what may live there
  - [x] Document the rule that the core directory may not reference Aseprite

- [x] Task: Extension manifest and menu entry stub `eb942a4`
  - [x] Write the manifest registering one menu entry
  - [x] Install the extension into Aseprite and confirm the entry appears
        (registration proven in batch; the menu itself is confirmed by the
        operator at the phase gate, as the process document requires for
        interface work)
  - [x] Record the installation steps in the process document

- [x] Task: Linter and formatter configuration `177f7cb`
  - [x] Declare the Aseprite globals so the linter does not report them
  - [x] Configure the formatter to the style stated in the Lua style guide
  - [x] Both run clean on the whole tree

- [x] Task: Test runner entry point `77c447a`
  - [x] One documented command discovers and runs the core test suite
  - [x] The command reports pass and fail counts and returns a non-zero exit
        code on failure

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `27e81c1`

## Phase 1 complete [checkpoint: 27e81c1]

## Phase 2 — Mathematical Core

- [x] Task: Easing curves `87821a2`
  - [x] Write failing tests: endpoint values are exact, output stays within
        bounds for non-overshoot curves, the out form is the mirror of the in
        form, the overshoot curve does exceed its target
  - [x] Implement the curve set
  - [x] Refactor and re-run

- [x] Task: Frame sampler `997de15`
  - [x] Write failing tests: a requested frame count produces exactly that many
        frames, the first and last positions are exact, durations may be
        non-uniform, hold frames repeat the extremes
  - [x] Implement the sampler
  - [x] Refactor and re-run

- [x] Task: Arcs `e1a8ee8`
  - [x] Write failing tests: the quadratic curve passes through its endpoints,
        the control point raises the midpoint as expected, the parabolic helper
        peaks at the halfway point and returns to zero
  - [x] Implement arc evaluation
  - [x] Refactor and re-run

- [x] Task: Transform, pixel snapping and the sub-pixel accumulator `9e5a792`
  - [x] Write failing tests: composed transforms equal the expected mapping,
        every emitted position is an integer, the accumulated remainder never
        lets total displacement drift from the requested value across a long
        sequence
  - [x] Implement the transform module
  - [x] Refactor and re-run

- [ ] Task: Seeded random source
  - [ ] Write failing tests: the same seed reproduces the same sequence, two
        different seeds diverge, values stay inside the requested range
  - [ ] Implement the random source
  - [ ] Refactor and re-run

- [ ] Task: Layer boundary check
  - [ ] Write a failing test that introduces a deliberate violation and expects
        the check to report it
  - [ ] Implement the check as a command that can also run in continuous
        integration
  - [ ] Remove the deliberate violation and confirm the check passes

- [ ] Task: Core coverage report
  - [ ] Produce a coverage report for the core modules
  - [ ] Confirm it meets the target, or add the missing tests until it does

- [ ] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`)

## Phase 3 — Motion Path Producer, Adapter and Demonstration

- [ ] Task: Motion path producer
  - [ ] Write failing tests: frame count, displacement and curve produce the
        expected integer offsets, the endpoints land exactly on the requested
        displacement, no drift accumulates, durations are returned alongside
  - [ ] Implement the producer on top of the core modules
  - [ ] Refactor and re-run

- [ ] Task: Aseprite adapter
  - [ ] Write a failing integration test, executed by the real binary, that
        expects the produced frames, cels and tag to exist and the source layer
        to be unchanged
  - [ ] Implement the adapter, wrapping all writes in a single transaction
  - [ ] Confirm a single undo removes the entire result

- [ ] Task: Sample character generator
  - [ ] Write a script that generates the bundled sample character
        deterministically
  - [ ] Confirm the generated file is small, has a known palette and is
        committed as a fixture

- [ ] Task: Demonstration command
  - [ ] Wire the producer and adapter behind the menu entry
  - [ ] Run it on the sample character and watch the resulting animation
  - [ ] Confirm the original layer is untouched and one undo clears everything

- [ ] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`)
  - [ ] Visual verification: the animation is watched in full, not judged from
        a single frame

## Phase 4 — Continuous Integration and Closure

- [ ] Task: Continuous integration workflow
  - [ ] Run lint, format check, core tests, coverage and the boundary check on
        every push and pull request
  - [ ] Do not build Aseprite in continuous integration

- [ ] Task: Confirm the workflow is green on the remote
  - [ ] Push and wait for the run to finish
  - [ ] Fix whatever the run reports until it is green

- [ ] Task: Machine-specific value sweep
  - [ ] Search the repository for absolute paths and remove any found
  - [ ] Document the environment variable that locates the Aseprite binary

- [ ] Task: Closing condition demonstration
  - [ ] Show the three proofs end to end: the core test report, the batch run
        inside the real runtime exiting zero, and the watchable animation on
        the sample character
  - [ ] Present the result to the operator for the closure decision

- [ ] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`)
