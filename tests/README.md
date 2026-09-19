# tests

Two suites, deliberately separate.

`core/` holds unit tests that run under a plain Lua interpreter, with no
application involved. They are fast, they measure coverage, and they are what
runs on every push.

`integration/` holds tests executed by the real Aseprite binary in batch mode.
They are the only thing that proves a feature works where it actually runs,
because the application's interpreter carries its own sandbox, API surface and
undo semantics. They are run locally; the binary is located through the
`ASEPRITE_BIN` environment variable.

A feature that passes only the first suite is not verified.
