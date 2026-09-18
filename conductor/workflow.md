# Project Workflow — Puncher

## Guiding Principles

1. **The plan is the single source of truth:** All work is tracked within
   `plan.md`.
2. **The tech stack is deliberate:** Changes to the tech stack are
   documented in `tech-stack.md` *before* implementation.
3. **Test-Driven Development:** Tests are written before functionality.
4. **Coverage target:** **>80% coverage** for the mathematical core
   (motion, VFX, pixel transform algorithms — pure, side-effect-free
   functions). The Aseprite `Dialog`/UI layer is exempt from this target (it
   cannot be tested headlessly); manual verification is done there.
5. **Artist experience comes first:** Every decision must comply with the
   UX principles in `product-guidelines.md` (non-destructive, modular
   commands, sensible defaults).
6. **Non-interactive & CI-aware:** Commands are chosen so they run
   non-interactively (e.g. `aseprite --batch --script ...`).

## Task Workflow

Every task follows this lifecycle:

1. **Select Task:** Take the next task in order from `plan.md`.

2. **Mark In Progress:** Before starting work, change the task in
   `plan.md` from `[ ]` → `[~]`.

3. **Write a Failing Test (Red):**
   - Create a test file for the feature or bug fix.
   - Write tests that clearly define the expected behavior and acceptance
     criteria.
   - **CRITICAL:** Run the tests and confirm they fail as expected. Do not
     proceed without a failing test.

4. **Implement Just Enough to Pass (Green):**
   - Write the minimum code needed to pass the tests.
   - Re-run the test suite and confirm all tests pass.

5. **Refactor (optional, recommended):**
   - Simplify the code and remove duplication under the safety of passing
     tests.
   - Re-run the tests.

6. **Verify Coverage:** Run the coverage report for the core algorithm
   modules. Target: >80% for new core code. UI/Dialog files are excluded
   from the report.

7. **Document Deviations:** If the implementation deviates from the tech
   stack:
   - **STOP**
   - Update the `tech-stack.md` file with the new design
   - Add a dated note explaining the change
   - Continue the implementation

8. **Commit the Code:**
   - Stage all changes belonging to the task.
   - Propose a clear commit message, e.g. `feat(motion): Add cubic easing evaluator`.
   - Make the commit.

9. **Attach the Task Summary via Git Notes:**
   - **9.1:** Get the commit hash (`git log -1 --format="%H"`).
   - **9.2:** Prepare a detailed note draft containing the task name, a
     summary of changes, the list of created/modified files, and the "why"
     of the change.
   - **9.3:** Attach it with `git notes add -m "<note content>" <commit_hash>`.

10. **Record the Task Commit SHA:**
    - **10.1:** Find the completed task in `plan.md`, change `[~]` → `[x]`,
      and append the first 7 characters of the commit hash.
    - **10.2:** Write the updated content to the `plan.md` file.

11. **Commit the Plan Update:**
    - Stage the `plan.md` file.
    - Commit in the form `conductor(plan): Mark task '<TASK>' as complete`.

### Correction and Plan Change Flows

1. **In-Flight Fixes:** Small gaps found while the task is still in `[~]`
   state are fixed within the active implementation; tests must pass before
   committing.
2. **Code Review Fixes (`conductor-review`):** For issues found during
   review, the review agent adds a `Review Fixes` phase to the `plan.md`
   file; fixes are tracked formally.
3. **Logical Revert (`conductor-revert`):** If a task is fundamentally
   wrong, the relevant commits are safely reverted and the task status
   returns to `[ ]`.

### Phase Completion Verification and Checkpoint Protocol

**Trigger:** Runs when a task that also concludes a phase is completed.

1. **Announce the Protocol:** Inform the user that the phase has ended and
   the verification protocol has begun.

2. **Ensure Test Coverage for Phase Changes:**
   - **2.1:** Find the previous phase's checkpoint SHA in `plan.md`. If
     there is none, the scope is from the first commit onward.
   - **2.2:** List the changed files with
     `git diff --name-only <previous_checkpoint_sha> HEAD`.
   - **2.3:** For code files (excluding non-code files such as `.md`,
     `.json`), check whether a corresponding test file exists; create one
     if not. First examine the existing test files in the repo to learn the
     naming and style conventions. UI/Dialog files are exempt from this
     requirement; they go into the manual verification plan instead.

3. **Run Automated Tests:**
   - Announce the exact command you will use before running it.
   - **Example announcement:** "I will run the tests. **Command:**
     `aseprite --batch --script tests/run_all.lua`"
   - Run the command.
   - If tests fail, inform the user and start debugging. Make **at most
     two** fix attempts; if still failing, **stop**, report the status, and
     ask the user for direction.

4. **Propose a Manual Visual Verification Plan:**
   - To produce the plan, first analyze the `product.md`,
     `product-guidelines.md`, and `plan.md` files to derive the phase's
     user-facing goals.
   - This project is a visual tool: verification is done through **the
     appearance of the generated animation**. The plan must be in this
     format:

     ```
     Automated tests passed. For manual verification:

     **Manual Verification Steps:**
     1. **Open Aseprite and load this sample file:** `examples/dummy-character.aseprite`
     2. **Run this command:** Menu → Puncher → Apply Motion → "Forward Dash"
     3. **You should see:** A new 8-frame tag, a dash where the character
        accelerates and decelerates forward, with a smear on frames 3 and 4;
        the original layer must remain unchanged.
     4. **Undo check:** A single `Ctrl+Z` should remove the entire
        generation.
     ```

   - If possible, produce an exported GIF for verification and show it to
     the user.

5. **Wait for User Approval:**
   - After presenting the plan, ask: "**Does this meet your expectations?
     Confirm with yes or write what needs to change.**"
   - **STOP** and do not proceed without explicit approval.

6. **Determine the Target Commit for the Report:** Do not create an empty
   commit for the checkpoint; target the last functional commit in the
   phase.

7. **Attach the Verification Report via Git Notes:** Attach a report
   containing the automated test command, the manual verification steps,
   and the user's approval to the target commit using `git notes`.

8. **Record the Phase Checkpoint SHA:** Add `[checkpoint: <sha>]` to the
   phase heading in `plan.md`.

9. **Commit the Plan Update:**
   `conductor(plan): Mark phase '<PHASE NAME>' as complete`

10. **Announce Completion.**

### Quality Gates

Verify before a task is considered complete:

- [ ] All tests pass
- [ ] Core algorithm coverage meets the target (>80%)
- [ ] Code complies with the `code_styleguides/` rules
- [ ] All public functions are documented (LuaDoc/docstring)
- [ ] No lint / static analysis errors
- [ ] **Non-destructive guarantee is preserved** (the user's existing
      layers are not modified, all generation is within a single
      `app.transaction`, and can be undone with a single Ctrl+Z)
- [ ] **Pixel integrity is preserved** (grid alignment, no unwanted
      anti-aliasing, no off-palette colors silently added)
- [ ] Visual output has been eyeballed (the whole animation, not just a
      single frame)
- [ ] Documentation updated (if necessary)

## Development Commands

The extension itself has no runtime dependencies. Everything below is
development tooling, installed per developer, never bundled with the
extension.

### Setup

Requires Lua 5.4 (the version Aseprite embeds), LuaRocks, and the Lua
development headers.

```bash
luarocks --local install luacheck   # linter
luarocks --local install luaunit    # unit test library
luarocks --local install luacov     # coverage measurement
```

LuaRocks installs these under `~/.luarocks`; make sure `~/.luarocks/bin` is on
`PATH`.

The formatter is a standalone binary, downloaded from its own releases rather
than built from source:

```bash
gh release download --repo JohnnyMorganz/StyLua --pattern "stylua-linux-x86_64.zip"
unzip stylua-linux-x86_64.zip && install -m 755 stylua ~/.local/bin/stylua
```

Aseprite itself is built from source following the upstream instructions. Its
location is never hardcoded: export `ASEPRITE_BIN` to point at the binary.

```bash
export ASEPRITE_BIN=/path/to/aseprite
```

### Installing the Extension for Development

The application reads user extensions from `extensions/` inside its
configuration directory, one real directory per extension:

```bash
mkdir -p "$HOME/.config/aseprite/extensions/puncher"
cp -r package.json main.lua core adapter commands presets \
  "$HOME/.config/aseprite/extensions/puncher/"
```

**A symbolic link does not work.** The application enumerates only real
directories when it scans for extensions, so a link pointing at a working copy
is silently skipped - no error, the extension simply never appears. Copy after
every change you want to see in the running application.

To confirm an extension actually loaded, run the application once with
`--verbose` and look for its name in `Aseprite.log` inside the configuration
directory; the log is truncated on every run and only written in verbose mode.

### Daily Development

```bash
lua tests/run_all.lua                        # core unit tests, no Aseprite needed
"$ASEPRITE_BIN" --batch --script tests/integration/run_all.lua   # runtime tests
```

### Before Commit

```bash
luacheck .            # lint
stylua --check .      # format check
lua tests/run_all.lua # core tests
```

### Verified Versions

Recorded when the tooling was installed on 2026-09-18: Lua 5.4.8,
luacheck 1.2.0, luaunit 3.5, luacov 0.17.0, stylua 2.5.2.

## Test Requirements

### Unit Tests

- Every core module (easing, arc, squash&stretch, particle, quantizer)
  must have a corresponding test.
- Tests target pure functions: input parameters → expected numeric output
  or pixel matrix.
- Test both success and error cases (e.g. invalid frame count, missing
  anchor).

### Integration Tests

- End-to-end command flow: sample sheet → ingest → pixelate → motion → VFX.
- Structural validation of the generated sprite: expected frame count,
  layer naming, tags, palette size.
- Must be runnable in Aseprite headless mode (`--batch --script`).

### Visual Regression

- Reference outputs (golden files) are stored with sample characters;
  generated pixels are verified via hash or pixel comparison.
- For intentional visual changes, reference files are explicitly updated
  and noted in the commit message.

## Code Review Checklist

1. **Functionality:** The feature works as specified, edge cases (0
   frames, single frame, very large sprite, empty layer) are handled, and
   error messages are clear.
2. **Code Quality:** Complies with the style guide, no duplication, clear
   names, no unnecessary comments.
3. **Tests:** Comprehensive unit tests, integration tests pass.
4. **Performance:** Per-pixel loops do not repeat unnecessarily, acceptable
   time on large sprites, no unnecessary Image copies.
5. **Artist Experience:** Non-destructive, parameters are clear, defaults
   are sensible, preview is accurate.

## Commit Rules

### Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting
- `refactor`: Code change that does not alter behavior
- `test`: Adding missing tests
- `chore`: Maintenance tasks

### Examples

```bash
git commit -m "feat(motion): Add anticipation-overshoot curve generator"
git commit -m "fix(pixelate): Correct palette mapping in OKLab distance"
git commit -m "test(vfx): Add tests for shockwave ring radius falloff"
```

## Definition of Done

A task is complete when:

1. Code was implemented according to the specification
2. Unit tests were written and pass
3. The core coverage target was met
4. Documentation was completed (if necessary)
5. Lint / static analysis is clean
6. Visual output was eyeballed and the non-destructive guarantee was
   preserved
7. Implementation notes were added to `plan.md`
8. Changes were committed with an appropriate message
9. The task summary was attached to the commit as a git note

## Release and Distribution

### Pre-Release Checklist

- [ ] All tests pass
- [ ] Core coverage target is met
- [ ] No lint errors
- [ ] Manually tested on the minimum supported Aseprite version
- [ ] README and command reference are up to date
- [ ] `package.json` (extension manifest) version was updated
- [ ] Sample GIFs were regenerated

### Distribution Steps

1. Merge the feature branch into the main branch
2. Tag the release (semver)
3. Produce the `.aseprite-extension` package
4. Test the package on a clean Aseprite installation
5. Publish a GitHub release (with changelog)

## Continuous Improvement

- Review the workflow regularly, update it based on pain points
- Document lessons learned
- Keep it simple and sustainable
