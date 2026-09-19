# core

Pure mathematics. Easing curves, frame sampling, arcs, transforms, pixel
snapping and seeded randomness.

Nothing here may reference an Aseprite global. A module in this directory takes
numbers and tables and returns numbers and tables; it never knows that a sprite
exists. That boundary is what lets this layer be tested without the
application, and it is enforced by an automated check.

The rule and its rationale live in `conductor/code_styleguides/lua.md`.
