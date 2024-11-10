# Tried to access property for bad value

When values are defined using a table, the columns of that table become properties. For instance, if the table defines colours and there is a column called `wavelength`, it then becomes legal to talk about `the wavelength of blue` (supposing that `blue` is one of colours defined).

Here, an attempt has been made to read or write such a property for something which cannot possibly be a qualifying value - for instance, `the wavelength of -21` would be such a case, though many such mistakes are rejected at translation time rather than now.
