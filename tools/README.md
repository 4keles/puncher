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
the canvas. The symptom looks exactly like synthetic input not arriving at all,
which is what it was mistaken for: this file previously claimed the display
server ignored pointer moves outright and that unattended checks were therefore
impossible. That was wrong. Pointer moves and keystrokes both arrive; the
driver was simply aiming at the wrong place. Menus open, submenus expand,
dialogs can be dismissed and the whole chain can be driven without a person
present.

One real limit remains: the editor only receives synthetic input while it holds
the session's keyboard focus, so a check that runs while the desktop is busy
with something else will still go nowhere.

`render_demo.lua` stays the better tool for checking motion, and does not need
a desktop session at all: it runs the same code the menu command runs, in batch
mode with no window, and writes the result out as an animation and as numbered
frames. Looking at those frames proves the motion; looking at the interface
proves the interface.
