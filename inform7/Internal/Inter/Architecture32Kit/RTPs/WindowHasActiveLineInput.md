# Cannot set current line input of a window with active line input

The `set the current line input` phrase cannot be used for a window which currently has active line input; there'd be no point as the text you set would be overwritten once the player submitted their input. You should only use `set the current line input` while handling a line event, or after using `suspend text input`.