# tools

Development helpers. Nothing here ships with the extension.

`uidriver.py` drives the running editor's interface and captures its window, so
a menu entry, a dialog or a generated animation can be checked by looking at
it. The project's rules say interface work is not verified until it has been
seen in the running application; this is what makes that check something the
machine can perform rather than a request handed to a person.

It needs a window manager control utility, a window information utility and an
image capture utility, all standard on a desktop system, and nothing else: the
input side talks to the display server through libraries already present.

**Work from a captured image.** Take a shot, read the position of what you want
straight off that image, and click the same position with `click-in`. Screen
positions are only needed for things outside the window.

That matters because of a mistake worth not repeating. The window manager
reports where a window sits *inside its decorated frame*, not where that frame
sits on screen. Treating the first as the second aimed every click tens of
pixels away from what was meant - far enough to sail past a menu and land in
the canvas. That bug is fixed, and with it fixed the menu opens, the submenu
expands and a command runs.

**Trust nothing here without looking.** Whether synthetic input reaches the
editor at all varies from one moment to the next on this desktop: the same
sequence that drove the menu once did nothing fifteen minutes later, with the
window still reported as active and the pointer still obeying. So the rule is
capture, look, then act on what the capture shows, and check afterwards that
the thing you clicked actually happened. A click that silently goes nowhere is
the normal failure here, and it looks exactly like a click that landed in the
wrong place - which is how the aiming bug above went undiagnosed long enough
to be written into this file as a fact about the display server.

`render_demo.lua` stays the better tool for checking motion, and does not need
a desktop session at all: it runs the same code the menu command runs, in batch
mode with no window, and writes the result out as an animation and as numbered
frames. Looking at those frames proves the motion; looking at the interface
proves the interface.
