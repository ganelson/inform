#include "inform7_clib.h"
#include "inform7_symbols.h"

int main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	i7_set_process_sender(&proc, NULL);
	if (i7_run_process(&proc) == 0) {
		char *M = i7_read_string(&proc, i7_read_variable(&proc, i7_V_meaning));
		printf("[C program reads 'meaning' as %s]\n", M);
		i7_try(&proc, i7_A_Examine, i7_I_Linear_B_tablet, 0);	
		i7_write_string(&proc, i7_read_variable(&proc, i7_V_meaning),
			"the goddess of the winds beckons you!");
		i7_try(&proc, i7_A_Examine, i7_I_Linear_B_tablet, 0);	

		int L = 0;
		i7word_t *D = i7_read_list(&proc, i7_read_variable(&proc, i7_V_dial), &L);
		printf("[C program reads 'dial' as");
		for (int i=0; i<L; i++) printf(" %d", D[i]);
		printf("]\n");
		i7_try(&proc, i7_A_Examine, i7_I_watch, 0);
		D[0] = 2;
		D[1] = 10;
		i7_write_list(&proc, i7_read_variable(&proc, i7_V_dial), D, 2);
		i7_try(&proc, i7_A_Examine, i7_I_watch, 0);	
		return 0;
	} else {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
		return 1;
	}
}
