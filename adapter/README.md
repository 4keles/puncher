# adapter

The translation layer between pure data and the application.

Modules here take what `core` produced - frame positions, durations, pixel
matrices - and turn it into sprites, layers, cels, frames and tags. All writes
to a user's document happen inside a single transaction so one undo reverses
the whole operation.

This is the only place, besides `commands`, that is allowed to touch the
Aseprite API.

## One image, many cels

Every cel a motion produces is handed the *same* image object, not a copy.
Nothing writes to it today, so nothing goes wrong, and copying an image per
frame would be waste.

The moment a later track paints per frame - a smear, a squash, a flash, a
recoloured silhouette - that stops being true: painting onto one produced cel
would paint onto every cel sharing the reference, and the symptom is every
frame of the animation turning into the same frame. Copy before painting, and
copy only the cels that are actually painted.
