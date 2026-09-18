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

**Its reach has a hard limit.** On a Wayland desktop the editor runs through
the X compatibility layer, which only receives synthetic input while it truly
holds the session's keyboard focus. When focus sits elsewhere, keystrokes go
nowhere and pointer moves are ignored outright - a click then lands wherever
the real pointer happens to rest, which is worse than doing nothing. So the
driver is for looking at the interface when someone is already in front of it,
not for unattended checks.

Unattended visual checks use `render_demo.lua` instead: it runs the same code
the menu command runs, in batch mode with no window at all, and writes the
result out as an animation and as numbered frames. Looking at those frames
proves the motion without depending on a desktop session.
