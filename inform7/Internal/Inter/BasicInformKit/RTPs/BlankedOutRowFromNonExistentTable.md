# Attempt to blank out a row from a non-existent table

This is one of the most difficult run-time problems to achieve, so perhaps congratulations are in order. I think you must have set up some sort of indirect code to operate on arbitrary tables, then got that wrong so that it tried to act on an illegal value for the identity of the table (the value is printed in numerical form in the message opposite), then tried to blank out one of its rows.
