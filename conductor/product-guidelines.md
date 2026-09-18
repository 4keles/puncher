# Product Guidelines — Puncher

## Language

- **Interface, menus, parameter names, and end-user documentation:
  English.** The extension will be distributed to the general pixel art
  community.
- In-code identifiers and comments: English.
- Project documents, including everything under `conductor/`, and commit
  messages: English.
- Turkish is used only for live conversation with the operator and for
  presentations.

## Tone

Technical and clear; consistent with Aseprite's own plain language. Short
labels (`Speed`, `Weight`, `Exaggeration`, `VFX Intensity`), no
exaggeration, no jargon. Preset names are descriptive (`Forward Dash`,
`Ground Slam`), no marketing language. Error messages state both what
happened and how to fix it.

## Core UX Principles

1. **Strictly non-destructive.** Everything produced is added as a new
   layer/frame/tag; the user's existing artwork is never overwritten. Each
   command runs inside a single `app.transaction`, fully undoable with a
   single `Ctrl+Z`.
2. **Modular command architecture.** Each job is a separate menu command:
   `Ingest Sheet`, `Pixelate`, `Apply Motion`, `Add VFX`, `Export`.
   Commands can run independently and can be chained; the user can skip
   any step they want or use just a single step.
3. **Contract between steps.** Commands talk to each other through layer
   naming conventions and sprite metadata (properties / slices / tags);
   there is no hidden global state. This makes commands both independent
   and composable.
4. **Preview exists where it's cheap.** A canvas preview wherever possible
   in each command's dialog; for expensive operations, a low-resolution or
   single-frame preview.
5. **Parameters are visible and savable.** Every effect is driven by
   explicit numeric parameters (no hidden magic). Settings can be saved as
   presets and reused.
6. **The artist has the final say.** Output is always manually editable
   layers; the extension does not produce a "black box" render.
7. **Speed is first-class.** A command should finish in a few seconds on a
   typical character; progress feedback is given for long operations.
8. **Reasonable defaults.** When the user hits "Apply" without touching
   any slider, they should get a result that looks good.

## Visual and Aesthetic Rules

- Generated output stays faithful to the document's existing palette. When
  VFX requires an off-palette color, the user is asked, or it is
  explicitly reported that it will be added to the palette.
- Pixel integrity is preserved: grid alignment, no sub-pixel shifting, no
  unwanted anti-aliasing.
- Effects follow pixel art conventions: hard edges, limited palette,
  consistent pixel density.

## Documentation Rules

- For each preset and VFX: what it does, its parameters, typical frame
  count, and an example GIF.
- README in English; starts with installation steps, followed by the
  command reference.
- Release notes explicitly list user-visible behavior changes.
