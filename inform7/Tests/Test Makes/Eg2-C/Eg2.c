#include "inform7_clib.h"

int main(int argc, char **argv) {
	printf("Hello from the C source code.\n");
	i7process_t proc = i7_new_process();
	int exit_code = i7_run_process(&proc);
	if (exit_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return exit_code;
}
