# Event is on unknown Glk window

A Glk event has occurred which references a window we don't know about. This could be caused by old extensions which created their own windows in Inform 6. Inform now requires such extensions to also create a `glk window` object and keep it updated, so that the events system can track all windows.