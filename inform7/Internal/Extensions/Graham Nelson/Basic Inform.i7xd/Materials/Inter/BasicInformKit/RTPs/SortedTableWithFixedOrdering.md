# Attempt to sort a table whose ordering must remain fixed

Most tables can be sorted freely, but those which are used to define a kind of value cannot. This is because they are used internally to store the properties belonging to those values, and in such a way that if the rows were rearranged, the properties would also be rearranged - and chaos would ensue. So, such tables are protected from sorting by this run-time problem message.
