# presets

Parameter sets as data, not code: animation presets, effect parameters and
palettes.

A preset is a table of named numbers. The engine that consumes it lives in
`core`; adding a preset must never require changing that engine. This is also
where the no-hardcoded-values rule lands in practice - a tunable that could
plausibly change belongs in a preset here, not inline at a call site.
