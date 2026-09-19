# commands

One file per menu command. Each command owns its dialog, reads its parameters,
calls into `core` and `adapter`, and reports failures in language the artist
can act on.

Commands stay thin: a command that contains mathematics belongs in `core`, and
a command that contains document manipulation belongs in `adapter`.
