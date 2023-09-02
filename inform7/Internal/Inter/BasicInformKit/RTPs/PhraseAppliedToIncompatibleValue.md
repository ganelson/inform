# Phrase applied to an incompatible kind of value

When Inform is given one or more definitions for a phrase, and it is not clear in advance that these definitions apply to a particular situation, it has to check this during play. If it turns out that none of the available definitions can apply, this run-time problem is generated.

For instance, suppose the source defines: `To greet (M - a man): ...` and also `To greet (W - a woman): ...`, and also says: `Before kissing someone (called the partner), greet the partner.` And suppose the player then does something which the author didn't expect, by typing KISS FELIX, where Felix is a cat (an object of kind `person`, but neither a `man` nor a `woman`). Inform is then unable to apply `greet` correctly because neither definition can be applied to Felix's kind.
