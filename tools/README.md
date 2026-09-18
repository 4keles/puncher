# tools

Development helpers. Nothing here ships with the extension.

`uidriver.py` drives the running editor's interface and captures its window, so
a menu entry, a dialog or a generated animation can be checked by looking at
it. The project's rules say interface work is not verified until it has been
seen in the running application; this is what makes that check something the
machine can perform rather than a request handed to a person.

It needs a window manager control utility and an image capture utility, both
standard on a desktop system, and nothing else: the input side talks to the
display server through libraries already present.
