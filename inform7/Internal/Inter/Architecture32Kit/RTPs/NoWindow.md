# Cannot perform this Glk window operation on nothing

A Glk window function is being called on nothing. This could happen, for example, if you're assuming the `glk event window` is valid, but for timer events it is nothing.