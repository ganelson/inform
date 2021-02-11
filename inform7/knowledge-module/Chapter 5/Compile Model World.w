[World::Compile::] Compile Model World.

To manage the compilation of the diverse run-time arrays and/or code
needed to set up the initial state of the model world.

@ A modest temporary array is needed to tally up the memory cost of creating
objects of given kinds, for the sake of the index:

=
int *rough_array_memory_used = NULL; /* in words, not bytes; for kinds only */

void World::Compile::set_rough_memory_usage(kind *K, int words_used) {
	if (K == NULL) return;
	if (rough_array_memory_used == NULL)
		internal_error("rough_array_memory_used unallocated");
	rough_array_memory_used[Kinds::get_construct(K)->allocation_id] = words_used;
}

int World::Compile::get_rough_memory_usage(kind *K) {
	if (K == NULL) return 0;
	if (rough_array_memory_used == NULL)
		internal_error("rough_array_memory_used unallocated");
	return rough_array_memory_used[Kinds::get_construct(K)->allocation_id];
}

@ The actual compilation is entirely delegated: we ask if the plugins want
to write anything, then put the same question to the subjects.

=
void World::Compile::compile(void) {
	Plugins::Call::compile_model_tables();
	int nc = NUMBER_CREATED(kind_constructor), i;
	rough_array_memory_used = (int *)
		(Memory::calloc(nc, sizeof(int), COMPILATION_SIZE_MREASON));
	for (i=0; i<nc; i++) rough_array_memory_used[i] = 0;
	InferenceSubjects::emit_all();
	Memory::I7_array_free(rough_array_memory_used, COMPILATION_SIZE_MREASON, nc, sizeof(int));
	rough_array_memory_used = NULL;
}
