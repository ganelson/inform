#include "inform7_clib.h"
#include "inform7_symbols.h"

int main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	i7_set_process_sender(&proc, NULL);
	if (i7_run_process(&proc) == 0) {
		i7_try(&proc, i7_A_Take, i7_I_Linear_B_tablet, 0);	
		i7_try(&proc, i7_A_Inv, 0, 0);	
		return 0;
	} else {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
		return 1;
	}
}
