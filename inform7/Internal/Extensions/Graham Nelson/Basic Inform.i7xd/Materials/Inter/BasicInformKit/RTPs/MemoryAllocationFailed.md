# Memory allocation proved impossible

Memory is constantly being allocated and deallocated, as needed, to store indexed text, lists and other values which can stretch to contain large amounts of data. If you see this problem, then the story file has needed more memory at once than was available.

For projects running the Z-machine, there is only a predetermined amount of memory that can be used; you can raise this with the `Use dynamic memory allocation of at least N` option, but only until there's no more space in the Z-machine, which doesn't take long. On Glulx the situation is better: if a version of Glulx from around 2007 or later is used, then memory can be dynamically grown during play - this happens automatically - and even if not, the `dynamic memory allocation` setting can be made very large indeed if needed.
