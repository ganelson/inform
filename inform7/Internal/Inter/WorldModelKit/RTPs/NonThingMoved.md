# Only things can be moved

Most everyday items in an Inform work are `things` - which includes people, containers, vehicles and so on. Those can all move around, at least in theory. The other kinds of object - such as `room`, `region` and `direction` - do not represent portable items, and so can't be moved. An attempt to move them with a line like `now the Mirror Room is in Versailles` will cause this problem message.
