#include "inform7_clib.h"
#include "inform7_symbols.h"

int main(int argc, char **argv) {
	i7process_t proc = i7_new_process();
	i7_set_process_sender(&proc, NULL);
	if (i7_run_process(&proc) == 0) {
		i7word_t t = i7_read_variable(&proc, i7_V_the_time);
		printf("[C program reads 'time of day' as %d]\n", t);
		i7word_t A = i7_read_prop_value(&proc, i7_I_Linear_B_tablet, i7_P_age);
		printf("[C program reads 'age of Linear B tablet' as %d]\n", A);
		i7_try(&proc, i7_A_Take, i7_I_Linear_B_tablet, 0);	
		i7_try(&proc, i7_A_Inv, 0, 0);
		i7_write_variable(&proc, i7_V_the_time, 985);
		i7_try(&proc, i7_A_Examine, i7_I_watch, 0);	
		i7_write_variable(&proc, i7_V_the_time, 995);
		i7_try(&proc, i7_A_Examine, i7_I_watch, 0);	
		i7_write_prop_value(&proc, i7_I_Linear_B_tablet, i7_P_age, i7_I_modern);
		i7_try(&proc, i7_A_Examine, i7_I_Linear_B_tablet, 0);	
		return 0;
	} else {
		printf("*** Fatal error: halted ***\n");
		fflush(stdout); fflush(stderr);
		return 1;
	}
}
