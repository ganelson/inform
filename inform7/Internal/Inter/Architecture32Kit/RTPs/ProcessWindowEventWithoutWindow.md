# Can't process a window-based event when there is no event window

When there is no current glk event window, we cannot switch to a window-based event. For example, in a timer event you cannot run `process a line event`. Instead, run `process a line event in (win)` to specify which window the new event will be for.