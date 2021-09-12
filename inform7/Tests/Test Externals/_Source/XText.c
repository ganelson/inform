#include "inform7_clib.h"
asdkfjalkgalg;
int main(int argc, char **argv) {
	printf("Welcome to this hybrid program!\n");
	i7process proc = i7_new_process();
	i7_run_process(&proc, i7_default_receiver);
	if (proc.termination_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return proc.termination_code;
}
