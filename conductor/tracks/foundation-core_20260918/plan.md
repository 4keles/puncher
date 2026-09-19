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

- [x] Task: Seeded random source `f13a388`
  - [x] Write failing tests: the same seed reproduces the same sequence, two
        different seeds diverge, values stay inside the requested range
  - [x] Implement the random source
  - [x] Refactor and re-run

- [x] Task: Layer boundary check `ac935c9`
  - [x] Write a failing test that introduces a deliberate violation and expects
        the check to report it
  - [x] Implement the check as a command that can also run in continuous
        integration
  - [x] Remove the deliberate violation and confirm the check passes

- [x] Task: Core coverage report `ac935c9`
  - [x] Produce a coverage report for the core modules
  - [x] Confirm it meets the target, or add the missing tests until it does
        (every core module fully covered, target was eighty percent)

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `86969bd`

## Phase 2 complete [checkpoint: 86969bd]

## Phase 3 — Motion Path Producer, Adapter and Demonstration

- [x] Task: Motion path producer `3691554`
  - [x] Write failing tests: frame count, displacement and curve produce the
        expected integer offsets, the endpoints land exactly on the requested
        displacement, no drift accumulates, durations are returned alongside
  - [x] Implement the producer on top of the core modules
  - [x] Refactor and re-run

- [x] Task: Aseprite adapter `4e64970`
  - [x] Write a failing integration test, executed by the real binary, that
        expects the produced frames, cels and tag to exist and the source layer
        to be unchanged
  - [x] Implement the adapter, wrapping all writes in a single transaction
  - [x] Confirm a single undo removes the entire result (now an automated
        check inside the integration suite)

- [x] Task: Sample character generator `c167906`
  - [x] Write a script that generates the bundled sample character
        deterministically
  - [x] Confirm the generated file is small, has a known palette and is
        committed as a fixture

- [x] Task: Demonstration command `c167906`
  - [x] Wire the producer and adapter behind the menu entry
  - [x] Run it on the sample character and watch the resulting animation
  - [x] Confirm the original layer is untouched and one undo clears everything

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `89757b9`
  - [x] Visual verification: the animation is watched in full, not judged from
        a single frame

## Phase 3 complete [checkpoint: 89757b9]

## Phase 4 — Continuous Integration and Closure

Every step below is a single action with an observable result. A step whose
result cannot be seen is not a step.

- [x] Task: Coverage threshold gate `f6e69a2`
  - [x] Write a failing test that hands the checker a summary reporting less
        than the target and expects it to report a shortfall, a summary at the
        target and expects it to pass, and a report with no summary at all and
        expects it to fail rather than assume success
  - [x] Run the test suite and confirm the new tests fail for the stated reason
  - [x] Implement the checker: it reads the coverage report the coverage tool
        writes, finds the total line, compares it against the target held in a
        named configuration entry, and returns a non-zero exit code below it
  - [x] Run the test suite and confirm every test passes
  - [x] Run the linter, the formatter check and the boundary check clean
  - [x] Commit, then attach the task summary as a git note

- [x] Task: Continuous integration workflow `4ae70f8`
  - [x] Decide and write down what the automation may and may not do: it runs
        the checks that need only a plain Lua interpreter, and it never builds
        the drawing application, because that build takes tens of minutes and
        a gigabyte of disk and would make every push unusable as feedback
  - [x] Write the workflow so it triggers on every push and on every pull
        request aimed at the main branch
  - [x] Install the interpreter and the package manager from the runner image's
        own package source, and the three development packages from the package
        manager, each pinned to the interpreter version this project uses
  - [x] Install the formatter by downloading the exact released version
        recorded in the process document, not the newest one, so a formatter
        release cannot turn a passing branch red on its own
  - [x] Run, in order and each as its own visible step: the linter, the format
        check, the core test suite, the coverage report with its threshold
        gate, and the boundary check
  - [x] Confirm the file parses as valid workflow syntax before pushing
  - [x] Commit, then attach the task summary as a git note

- [x] Task: Confirm the workflow is green on the remote `4ae70f8`
  - [x] Push the branch and confirm the automation actually started; a workflow
        that never triggers is a silent failure, not a pass
  - [x] Watch the run to completion and read the log of every step
  - [x] Fix whatever the run reports, push again, and repeat until it is green
  - [x] Confirm the run really executed the checks rather than skipping them:
        the test count and the coverage figure in the remote log must match the
        ones produced locally
  - [x] Prove the automation can also fail: push a deliberately broken tree
        on a throwaway branch, confirm the run turns red and stops at the
        broken step, then remove the branch

- [x] Task: Machine-specific value sweep `7ac37a4`
  - [x] Search every tracked file for absolute paths belonging to this machine,
        for the account name, and for the location the drawing application was
        built in
  - [x] Remove anything found, replacing it with a documented environment
        variable or a path relative to the repository
  - [x] Confirm the process document states how to point the environment
        variable at the drawing application's binary, and that every command in
        the document uses it rather than a fixed location
  - [x] Re-run the test suites after the sweep, because a path change can break
        a runner silently
  - [x] Commit the sweep result, then attach the task summary as a git note

- [x] Task: Closing condition demonstration `e76da1b`
  - [x] Prove the first clause: from a clean copy of the repository taken out
        of version control into an empty directory, one command runs the core
        test suite to a passing report
  - [x] Prove the second clause: install the extension into the application's
        configuration directory from that clean copy, start the application
        once with verbose logging, and confirm from the log that the extension
        loaded; then capture the menu entry visibly
  - [x] Prove the third clause: run the batch script inside the real runtime and
        confirm it exits zero, showing the exit code rather than asserting it
  - [x] Prove the fourth clause: run the extension's motion on the bundled
        sample character and watch the produced animation frame by frame, not
        a single frame
  - [x] Write the four proofs up with their raw output and present them to the
        operator for the closure decision

- [x] Correction: The interface driver aimed every click wide `e76da1b`
  - [x] Cause: the window's position inside its decorated frame was taken for
        its position on screen, so clicks missed by tens of pixels and looked
        like input that never arrived
  - [x] Fix the aim, and let a position read off a captured image be clicked
        as it is
  - [x] Correct the tool documentation, which had recorded the wrong diagnosis
        as fact
  - [x] Prove the fix by opening the menu and its submenu from coordinates read
        off a captured image
  - [x] Rerun every gate affected

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`)
  - [x] Run the whole gate set one final time and record the counts
  - [x] Attach the phase verification report as a git note
  - [x] Mark the phase complete with its checkpoint, tag the savepoint, push
        the branch and the tags

## Phase 4 complete [checkpoint: e76da1b]
