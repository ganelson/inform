[Telemetry::] Telemetry.

An optional facility for transcribing the outcome of runs of software.

@ The telemetry file is optional, and transcribes the outcome of each run. This
is mainly for testing Inform, but may also be useful for teachers who want
to monitor how a whole class is using the system.

Nothing is done unless a filename is sent to the following function:

=
filename *spool_telemetry_to = NULL;
void Telemetry::locate_telemetry_file(filename *F) {
	spool_telemetry_to = F;
}

@ A little lazily, the telemetry file once opened stays open until the process
finishes.

=
int attempts_to_open_telemetry = 0;
text_stream telemetry_file_struct; /* The actual telemetry file (if created) */
text_stream *telemetry_file = &telemetry_file_struct; /* Main telemetry stream */
text_stream *telmy = NULL; /* Current telemetry stream */

void Telemetry::ensure_telemetry_file(void) {
	if (spool_telemetry_to == NULL) return;
	if (telmy) return;
	if (attempts_to_open_telemetry++ > 0) return;
	if (STREAM_OPEN_TO_FILE_APPEND(telemetry_file, spool_telemetry_to, ISO_ENC) == FALSE)
		Problems::fatal_on_file("Can't open telemetry file", spool_telemetry_to);
	telmy = telemetry_file;
	WRITE_TO(telmy, "\n-- -- -- -- -- -- -- --\n%B (build %B): telemetry.\n",
		FALSE, TRUE);
	int this_month = the_present->tm_mon + 1;
	int this_day = the_present->tm_mday;
	int this_year = the_present->tm_year + 1900;
	WRITE_TO(telmy, "Running on %4d-%02d-%02d at %02d:%02d.\n\n",
		this_year, this_month, this_day, the_present->tm_hour, the_present->tm_min);
	LOG("Opening telemetry file.\n");
}

@ And log messages can be written here:

=
void Telemetry::write_to_telemetry_file(wchar_t *m) {
	Telemetry::ensure_telemetry_file();
	WRITE_TO(telmy, "The user says:\n\n%w\n\n", m);
}
