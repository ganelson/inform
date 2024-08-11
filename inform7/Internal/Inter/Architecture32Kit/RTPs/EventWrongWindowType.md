# Glk event created for window of wrong type

Glk events can only be created for the appropriate window type. For example, line events can't be created for graphics window, mouse events can't be created for buffer windows. In particular, note that if you create an event without explicitly specifying the window, the main window will be used, which is usually a buffer window.