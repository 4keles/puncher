# adapter

The translation layer between pure data and the application.

Modules here take what `core` produced - frame positions, durations, pixel
matrices - and turn it into sprites, layers, cels, frames and tags. All writes
to a user's document happen inside a single transaction so one undo reverses
the whole operation.

This is the only place, besides `commands`, that is allowed to touch the
Aseprite API.
