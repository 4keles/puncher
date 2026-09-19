# Implementation Plan — Track 2: Rig and Draw List

Every task follows the lifecycle in `conductor/workflow.md`: mark in progress,
write a failing test, implement the minimum to pass, refactor, verify
coverage, commit, attach the task summary as a git note, record the commit,
commit the plan update.

Every step below is a single action with an observable result.

## Phase 1 — The Pixel Matrix and the Transforms That Are Safe

- [x] Task: Pixel matrix `fca65c7`
  - [x] Write failing tests: a new matrix is uniformly the transparent value;
        reading outside the bounds returns the transparent value rather than
        failing; writing outside the bounds is ignored rather than growing the
        matrix; blitting one matrix into another lands at the offset asked
        for; shrinking to content returns the smallest rectangle holding a
        non-transparent pixel, and returns nothing for an empty matrix
  - [x] Implement the matrix
  - [x] Refactor and re-run

- [x] Task: Translation and mirroring `fca65c7`
  - [x] Write failing tests: translating by whole numbers moves every pixel
        and invents none; mirroring twice returns the original exactly;
        mirroring preserves the set of colours used
  - [x] Implement both
  - [x] Refactor and re-run

- [x] Task: Shear as integer row offsets `fca65c7`
  - [x] Write failing tests: each row is displaced by a whole number of
        pixels; no row is resampled, so the set of colours is unchanged; a
        shear of zero is the identity
  - [x] Implement the shear
  - [x] Refactor and re-run

- [x] Task: Colour conservation as a shared property test `fca65c7`
  - [x] Write a check, used by every transform's tests, that the output's set
        of colours is a subset of the input's
  - [x] Apply it to every transform written so far

- [x] Correction: A lean lost the rows that travelled furthest `1f3014f`
  - [x] Cause: the result kept the source's size, so at any lean worth having
        the rows furthest from the pivot ran off the edge and were dropped
        without a word
  - [x] Found by rendering the transforms inside the real runtime on the real
        sample and looking at them; the unit tests use pictures too small to
        run out of room
  - [x] Grow the frame and report where its left edge moved to

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `1f3014f`
  - [x] Visual verification: the transforms were rendered in the real runtime
        and the sheet was looked at

## Phase 1 complete [checkpoint: 1f3014f]

## Phase 2 — Rotation, Decided by Measurement

- [x] Task: Rotation by inverse mapping `580c902`
  - [x] Write failing tests: rotating by a quarter turn matches the exact
        expected pixels; rotating by zero is the identity; four quarter turns
        return the original; the rotated bounds are computed from the corners
        rather than assumed square; no colour is invented
  - [x] Implement the rotation
  - [x] Refactor and re-run

- [x] Task: Edge-aware enlargement `580c902`
  - [x] Write failing tests: every output pixel is copied from the source
        neighbourhood and never blended; a flat region enlarges unchanged; a
        diagonal edge gains the expected stepped corner; applying it twice
        gives four times the size
  - [x] Implement the doubling filter, applied repeatedly to reach a factor
  - [x] Refactor and re-run

- [x] Task: Reduction that picks rather than blends `580c902`
  - [x] Write failing tests: each output pixel is one of the values in the
        block it came from; ties resolve the same way every run, so the whole
        pipeline stays deterministic; a uniform block reduces to its own value
  - [x] Implement the reduction
  - [x] Refactor and re-run

- [x] Task: The rotation comparison `580c902`
  - [x] Build the three candidates over the same part: enlarge-rotate-reduce,
        quarter turns and mirrors only, and a pre-computed fixed angle set
  - [x] Render all three at the same angles, at a limb's real size, into one
        sheet
  - [x] Look at the sheet and decide
  - [x] Measure how long each takes for one part and record the figure
  - [x] Write the decision and its evidence into the stack document
  - [x] If every candidate is rejected, stop and bring the fallback back to
        the operator rather than choosing quietly (not needed: two candidates
        cleared the bar and one was chosen on cost)

- [x] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`) `580c902`
  - [x] Visual verification: the comparison sheet is looked at, not inferred

## Phase 2 complete [checkpoint: 580c902]

## Phase 3 — Parts, the Tree and Forward Kinematics

- [ ] Task: The part contract and the whole-drawing supplier
  - [ ] Write failing tests: a drawing with nothing marked yields one part
        covering it, with the pivot at a documented place; the shape of a part
        is exactly what everything downstream expects
  - [ ] Implement the fallback supplier
  - [ ] Refactor and re-run

- [ ] Task: Reading parts from the artist's slices
  - [ ] Confirm inside the running application whether extension properties
        survive a save; if they do not, carry the parent and role in the
        slice's own text field and record why
  - [ ] Write a runtime test that marks parts on a sprite, saves, reopens and
        reads them back
  - [ ] Implement the reader
  - [ ] Refactor and re-run

- [ ] Task: The part tree
  - [ ] Write failing tests: children resolve under their parent; a missing
        parent is refused with the part named; a cycle is refused with the
        part named; a pivot outside its rectangle is refused
  - [ ] Implement the tree
  - [ ] Refactor and re-run

- [ ] Task: Forward kinematics
  - [ ] Write failing tests: a parent's rotation carries its children; a
        child's own transform composes after its parent's; a two-level chain
        matches the transform computed by hand; the identity pose leaves every
        part where the artist drew it
  - [ ] Implement the composition on the existing transform helpers
  - [ ] Refactor and re-run

- [ ] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`)

## Phase 4 — The Draw List and the Adapter as Interpreter

- [ ] Task: The draw list and its validator
  - [ ] Write failing tests: a well-formed list passes; an instruction naming
        a part that does not exist is refused; an instruction with no
        transform is refused; a frame with no duration is refused; the
        refusal names the frame and the instruction
  - [ ] Implement the structure and the validator
  - [ ] Refactor and re-run

- [ ] Task: A path becomes a one-part draw list
  - [ ] Write failing tests: the translation produces exactly the offsets the
        path carried, with durations and holds preserved
  - [ ] Implement the translation
  - [ ] Refactor and re-run

- [ ] Task: The adapter interprets a draw list
  - [ ] Write a failing runtime test expecting parts drawn under their own
        transforms onto the layers named, the source cel untouched, and one
        undo removing everything
  - [ ] Implement the interpreter, keeping the single transaction
  - [ ] Confirm reading a cel into a matrix and writing it back in bulk
        round-trips exactly

- [ ] Task: The old demonstration, through the new machinery
  - [ ] Render the dash before and after and prove the frames are identical
  - [ ] Keep that comparison as a regression check

- [ ] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`)

## Phase 5 — The Rigged Sample and the Closing Demonstration

- [ ] Task: A rigged sample character
  - [ ] Extend the generator to draw a figure whose parts are separable and to
        mark them with pivots
  - [ ] Confirm the file stays small and its palette known

- [ ] Task: The demonstration command
  - [ ] Wire a motion that rotates one part while the body translates
  - [ ] Run it on the rigged sample and watch every frame
  - [ ] Run it on an unmarked character and confirm the old dash comes out

- [ ] Task: Closing condition demonstration
  - [ ] Show the three proofs end to end: the arm rotating while the body
        travels, the unmarked character producing the old dash unchanged, and
        the rotation comparison with its recorded decision
  - [ ] Present the result to the operator for the closure decision

- [ ] Task: Phase Verification and Checkpoint (refer to `conductor/workflow.md`)
  - [ ] Visual verification: the animation is watched in full
