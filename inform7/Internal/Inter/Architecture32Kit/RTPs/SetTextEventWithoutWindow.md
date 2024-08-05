# Can't set the glk event type to a text input event when there is no glk event window

The glk event type cannot be changed to a text input event (character or line) if the `glk event window` is currently unset (such as in a timer event).