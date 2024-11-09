# Can't move nothing

This problem occurs if a phrase tries to move something which does not exist.

The most likely way for this to occur is if a plausible name has been given to what is, most of the time, indeed a genuine thing - but not always. For instance, if we say `let the heroine be the tallest woman in the Amphitheatre`, supposing that we have defined `tall` and made such a place, then we might expect that `move the heroine to the Arena` would always work. In fact it would fail if there were no women in the Amphitheatre at the time we tried to set `heroine`, and this is the problem message which would appear.
