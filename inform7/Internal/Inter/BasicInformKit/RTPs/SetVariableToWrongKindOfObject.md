# Attempt to set a variable to the wrong kind of object

Suppose we write `The favourite place is a room that varies.`, and then during play `now the favourite place is X`, where X is some value. If Inform can tell in advance that X can't be a room, it will produce a Problem message and refuse to translate the source. But sometimes it can't tell in advance, because Inform only knows that X will be an object - which might or might not be a room. When that happens, it has to check at run-time (now!) to make sure. That's the check which has just failed for a variable of yours.
