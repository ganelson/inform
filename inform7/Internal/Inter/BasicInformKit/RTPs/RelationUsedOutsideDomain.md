# Relations cannot be used outside their defined roles

When a relation is defined, it has to say which objects are allowed to be related: for instance, `Propinquity relates various rooms to various rooms` indicates that both of the objects involved in the relation must be rooms. It would make no sense to declare that a container and a person now satisfy the relation, and the attempt would be rejected by a run-time problem like this one.

More is true: it is not even allowed to test the relation for objects which do not meet its qualifications. So if we define the adjective `homely` to refer to any room which satisfies the propinquity relation with a special room called `Home Base`, say, then we are allowed to `say the list of homely rooms` but not to `say the list of homely things`.
