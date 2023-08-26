# Too many rulebooks

There is no limit to the number of rulebooks which can exist in a given work, and there are typically several hundred. However, only 20 can be active at any given moment.

Rulebooks typically pile up when the rules governing one action call for another action to take place first, since action-processing is the most intensive use for rulebooks. If the limit is hit, this is usually a symptom of a circularity mistake - where an action is directly or indirectly duplicating itself. For instance, `Before going north, try going north.` has this effect.
