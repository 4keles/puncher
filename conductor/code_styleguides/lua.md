# Lua Style Guide — Puncher (Aseprite)

Mandatory rules specific to this project, in addition to the `general.md`
rules, derived directly from the Aseprite API research (see
`conductor/research/01-aseprite-lua-api.md`).

## Layer Discipline

- **References to the Aseprite API are FORBIDDEN inside `core/`.** Globals
  such as `app`, `Image`, `Sprite`, `Dialog` must not appear in any file
  under `core/`. `core/` only produces numbers, tables, and pure functions
  (e.g. pixel matrix, transform list, parameter table).
- Anything that touches Aseprite belongs under `adapter/` or `commands/`.
- This rule is testable: a grep check runs against `core/` in CI.

## Aseprite API Usage

- **`Image:putPixel` will not be used** — deprecated and generates an undo
  record on every call. Use `drawPixel` instead.
- Performance-critical pixel operations are done on the raw `Image.bytes` +
  `rowStride` buffer; the result is written back in one shot. A
  `getPixel`/`drawPixel` loop over hundreds of pixels must be justified in
  code review.
- **Every command that modifies the user's document runs inside
  `app.transaction`.** No exceptions. On error, `error()` is thrown; the
  transaction rolls back automatically.
- Manual interpolation is not written for rotation/scaling; the native
  `Image:resize{ method = 'rotsprite' }` is used.
- `os.execute`, `io.popen`, and external process invocation are
  **forbidden** (they trigger a permission dialog and break distribution).
  `io.open` may only be used in an export flow explicitly initiated by the
  user.

## Language Rules

- Every variable is `local`. Defining globals is forbidden (the one
  exception: globals provided by Aseprite itself).
- Modules return a table: `local M = {} ... return M`.
- Module loading: `dofile` or `require`, as long as it is consistent within
  the project; the two are not mixed.
- `math.floor` / explicit rounding is used; implicit number→integer
  conversion is not relied upon. Pixel coordinates are always rounded to
  integers.
- Pay attention to the distinction between `nil` and `false` in
  comparisons; for optional parameters, the form
  `if x == nil then x = default end` is preferred (`x = x or default` only
  where `false` is not a valid value).
- String concatenation inside a loop is not done with `..`; `table.concat`
  is used.

## Naming

- File and directory names: `snake_case.lua`.
- Functions and variables: `camelCase`.
- Module tables and "class"-like structures: `PascalCase`.
- Constants: `UPPER_SNAKE_CASE`.
- All user-facing text is in English (see `product-guidelines.md`).

## Documentation

- A short LuaDoc block above every public function: what it does,
  parameters (type + unit + range), return value.
- Units are written explicitly: `-- @param distance number  Displacement (pixels)`.
- Comments are written only for "why"; the code itself explains "what" it
  does.

## Formatting

- `stylua` default settings; 2-space indentation, line length 100.
- `luacheck` must pass without warnings; the `globals` list is configured
  with the Aseprite globals (`app`, `Image`, `Sprite`, `Dialog`, `Point`,
  `Rectangle`, `Color`, `json`, ...).

## Test

- Tests for `core/` modules are written with LuaUnit and run with the
  system Lua (without Aseprite).
- Test file name: `tests/core/<module>_test.lua`.
- In numeric tests, floating-point comparison is done with an epsilon
  (`assertAlmostEquals`).
