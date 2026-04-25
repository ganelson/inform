# Hyperlink tokens cannot contain ephemeral values

You cannot create a hyperlink token from an ephemeral value. You might be trying to make a hyperlink with a temporary local variable, which cannot be done. Or the I6 phrase might need to pass the value by reference: `{-by-reference:V}`.