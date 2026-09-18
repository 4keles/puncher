#!/usr/bin/env python3
"""Drive the running application's interface and capture what it looks like.

The project's rules say interface work is not verified until it has been seen
in the running application. This makes that possible without a human in the
loop: it moves the pointer, sends keystrokes and grabs the window, so a change
to a menu or a dialog can be checked the same way a person would check it.

It talks to the X server directly through the two libraries every desktop
already ships, so there is nothing to install. On Wayland this still works,
because the editor runs as an X client under the compatibility layer.

Usage:
    python3 tools/uidriver.py shot out.png
    python3 tools/uidriver.py click 400 300
    python3 tools/uidriver.py key Escape
    python3 tools/uidriver.py combo Alt_L f
    python3 tools/uidriver.py geometry
"""

import ctypes
import ctypes.util
import subprocess
import sys
import time

WINDOW_TITLE = "Aseprite"

# Every interaction needs the interface to settle before the next one, and
# these are the delays that proved reliable rather than arbitrary guesses.
SETTLE_AFTER_MOVE = 0.15
SETTLE_AFTER_PRESS = 0.08
SETTLE_AFTER_ACTION = 0.4
SETTLE_AFTER_FOCUS = 0.8

_x11 = ctypes.CDLL(ctypes.util.find_library("X11"))
_xtest = ctypes.CDLL(ctypes.util.find_library("Xtst"))

_x11.XOpenDisplay.restype = ctypes.c_void_p
_x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
_x11.XStringToKeysym.restype = ctypes.c_ulong
_x11.XStringToKeysym.argtypes = [ctypes.c_char_p]
_x11.XKeysymToKeycode.restype = ctypes.c_ubyte
_x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
_x11.XFlush.argtypes = [ctypes.c_void_p]

_display = _x11.XOpenDisplay(None)
if not _display:
    sys.exit("cannot reach the display server")


def _flush():
    _x11.XFlush(ctypes.c_void_p(_display))


def _keycode(name):
    keysym = _x11.XStringToKeysym(name.encode())
    if keysym == 0:
        sys.exit("unknown key name: " + name)
    return _x11.XKeysymToKeycode(ctypes.c_void_p(_display), keysym)


def key_down(name):
    _xtest.XTestFakeKeyEvent(ctypes.c_void_p(_display), _keycode(name), True, 0)
    _flush()
    time.sleep(SETTLE_AFTER_PRESS)


def key_up(name):
    _xtest.XTestFakeKeyEvent(ctypes.c_void_p(_display), _keycode(name), False, 0)
    _flush()
    time.sleep(SETTLE_AFTER_PRESS)


def key(name):
    key_down(name)
    key_up(name)
    time.sleep(SETTLE_AFTER_ACTION)


def combo(modifier, name):
    key_down(modifier)
    key(name)
    key_up(modifier)
    time.sleep(SETTLE_AFTER_ACTION)


def move(x, y):
    _xtest.XTestFakeMotionEvent(ctypes.c_void_p(_display), -1, int(x), int(y), 0)
    _flush()
    time.sleep(SETTLE_AFTER_MOVE)


def click(x, y, button=1):
    move(x, y)
    _xtest.XTestFakeButtonEvent(ctypes.c_void_p(_display), button, True, 0)
    _flush()
    time.sleep(SETTLE_AFTER_PRESS)
    _xtest.XTestFakeButtonEvent(ctypes.c_void_p(_display), button, False, 0)
    _flush()
    time.sleep(SETTLE_AFTER_ACTION)


def geometry(title=WINDOW_TITLE):
    listing = subprocess.check_output(["wmctrl", "-lG"]).decode()
    for line in listing.splitlines():
        if title.lower() in line.lower():
            parts = line.split()
            return {
                "id": parts[0],
                "x": int(parts[2]),
                "y": int(parts[3]),
                "width": int(parts[4]),
                "height": int(parts[5]),
            }
    return None


def focus(title=WINDOW_TITLE):
    subprocess.run(["wmctrl", "-a", title], check=False)
    time.sleep(SETTLE_AFTER_FOCUS)


def shot(path, title=WINDOW_TITLE):
    window = geometry(title)
    if window is None:
        sys.exit("no window matching " + title)
    subprocess.run(["import", "-window", window["id"], path], check=True)
    return path


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)

    command = sys.argv[1]
    if command == "geometry":
        print(geometry())
    elif command == "focus":
        focus()
    elif command == "shot":
        print(shot(sys.argv[2]))
    elif command == "click":
        click(int(sys.argv[2]), int(sys.argv[3]))
    elif command == "key":
        key(sys.argv[2])
    elif command == "combo":
        combo(sys.argv[2], sys.argv[3])
    else:
        sys.exit("unknown command: " + command)


if __name__ == "__main__":
    main()
