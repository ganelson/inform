# Attempt to match against a non-topic

The tests `matches` and `does not match` can only be used when a snippet is compared with a topic. Topics look like text, being written in double-quotes, but in fact Inform stores them completely differently, and it's important not to mix them up. For instance, if double-quoted text appears in a table column called `topic`, then it'll be a topic: otherwise it will just be plain text.
