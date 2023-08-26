# Attempt to move the player off-stage

The player always has to be inside some room, though sometimes indirectly so - for example, it's okay for the player to be on a table inside a room, or in a box on that table. But it's not okay (for example) to write `now the player is on the oak table` and then `now the oak table is nowhere`.
