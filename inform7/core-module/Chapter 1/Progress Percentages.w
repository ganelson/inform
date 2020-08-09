[ProgressBar::] Progress Percentages.

This tiny section, the Lichtenstein of Inform, prints percentage of
completion estimates so that the host application can intercept them and
update its graphical progress bar.

@ Clearly we can only estimate how far Inform has progressed. While we could in
principle measure the number of CPU-seconds it has run for, we don't know
how many more it will need. Instead, we rely on experience to suggest that
its run can be broken down into the following five stages, which a given
percentage of time spent in each stage: thus, for instance, semantic
analysis takes up about ten percent of every run in which problems do
not cause an early halt. Within each stage, we have a reasonable measure
of how far we have got: what proportion of the phrases have been compiled,
for instance, tells us how far "generating code" has got. The result is
that (if the relevant command line setting has been set, so that
|show_progress_indicator| is true) Inform prints about thirty lines like this
one to |stderr|:

|++ 32% (Binding rulebooks)|

The Inform application can intercept and parse these lines to display a
progress bar with a rubric beneath it.

=
int show_progress_indicator = TRUE; /* Produce percentage of progress messages */
void ProgressBar::enable_or_disable(int which) {
	show_progress_indicator = which;
}

int last_progress_pc = -100;
int progress_stage_from[] = { 0, 5, 15, 20, 40, 100 };
char *progress_stage_name[] = {
	"Reading text",
	"Analysing sentences",
	"Drawing inferences",
	"Binding rulebooks",
	"Generating code"
};

void ProgressBar::update(int stage, float proportion) {
	int r1 = progress_stage_from[stage], r2 = progress_stage_from[stage+1];
	int pc = r1 + ((int) (proportion*(r2-r1)));
	if (show_progress_indicator == FALSE) return;
	if (pc-last_progress_pc < 3) return;
	WRITE_TO(STDERR, "++ %d%% (%s)\n", pc, progress_stage_name[stage]);
	STREAM_FLUSH(STDERR);
	last_progress_pc = pc;
}

void ProgressBar::final_state_of_progress_bar(void) {
	if (show_progress_indicator) {
		WRITE_TO(STDERR, "++ 100%% (Finishing work)\n");
		STREAM_FLUSH(STDERR);
	}
}

@ Finally, the following sends a pithy summary back to the app to use as
a final status indicator.

=
text_stream *ProgressBar::begin_outcome(void) {
	if (show_progress_indicator == FALSE) return NULL;
	WRITE_TO(STDERR, "++ Ended: ");
	return STDERR;
}

void ProgressBar::end_outcome(void) {
	if (show_progress_indicator == FALSE) return;
	WRITE_TO(STDERR, "\n");
	STREAM_FLUSH(STDERR);
}
