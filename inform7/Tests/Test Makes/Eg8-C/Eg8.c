#include "inform7_clib.h"
#include "inform7_symbols.h"

i7val collatz(i7process_t *proc, i7val x) {
	printf("MR C: My friend Mrs I calls my attention to %d, ", x);
	if (x == 1) {
		printf("so I win! Haha!\n");
	} else if (x % 2 == 0) {
		printf("so I divide by two.\n");
		i7_F_run_the_collatz_algorithm_on_X(proc, x/2);
	} else {
		printf("so I triple and add one.\n");
		i7_F_run_the_collatz_algorithm_on_X(proc, 3*x + 1);
	}
	return 0;
}

int main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	int exit_code = i7_run_process(&proc);
	if (exit_code == 1) {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
	}
	return exit_code;
}
