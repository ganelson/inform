#include "inform7_clib.h"

char *the_quitter(int count) {
	char *cmd = "";
	switch (count) {
		case 0: cmd = "quit"; break;
		case 1: cmd = "y"; break;
	}
	printf("%s\n", cmd);
	return cmd;
}

int main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	i7_set_process_sender(&proc, the_quitter);
	int exit_code = i7_run_process(&proc);
	if (exit_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return exit_code;
}
