[CSUtilities::] C# Utility Functions.

Rounding out the C# library with a few functions intended for external code to use.

@ We will frequently need to reinterpret |int| values as |float|,
or vice versa. The following functions must be perfect inverses of each other.

= (text to inform7_cslib.cs)
partial class Process {
	static int i7_encode_float(float val) {
		return BitConverter.SingleToInt32Bits(val);
	}

	static float i7_decode_float(int val) {
		return BitConverter.Int32BitsToSingle(val);
	}
=

@ These two functions allow external C# code to read to, or write from, an
Inform 7 variable inside a currently running process.


= (text to inform7_cslib.cs)
	int i7_read_variable(int var_id) {
		return state.variables[var_id];
	}
	void i7_write_variable(int var_id, int val) {
		state.variables[var_id] = val;
	}

=

@ Text values extracted from such variables would be difficult to interpret
from the outside because of the complex way in which text is stored within an
Inform 7 process, so the following functions allow text inside the process
to be converted to or from null-terminated C strings.

= (text to inform7_cslib.cs)
	string i7_read_string(int S) {
		#if i7_mgl_BASICINFORMKIT
		i7_fn_TEXT_TY_Transmute(proc, S);
		int L = i7_fn_TEXT_TY_CharacterLength(proc, S, 0, 0, 0, 0, 0, 0);
		string A = malloc(L + 1);
		if (A == NULL) {
			Console.Error.WriteLine("Out of memory"); i7_fatal_exit();
		}
		for (int i=0; i<L; i++)
			A[i] = i7_fn_BlkValueRead(proc, S, i, 0);
		A[L] = 0;
		return A;
		#endif
		#if !i7_mgl_BASICINFORMKIT
		return null;
		#endif
	}

	void i7_write_string(int S, string A) {
		#if i7_mgl_BASICINFORMKIT
		i7_fn_TEXT_TY_Transmute(proc, S);
		i7_fn_BlkValueWrite(proc, S, 0, 0, 0);
		if (A) {
			int L = strlen(A);
			for (int i=0; i<L; i++)
				i7_fn_BlkValueWrite(proc, S, i, A[i], 0);
		}
		#endif
	}
=

@ And similarly for list values, which we convert to and from C arrays.

= (text to inform7_cslib.cs)
	int[] i7_read_list(int S, out int N) {
		#if i7_mgl_BASICINFORMKIT
		int L = i7_fn_LIST_OF_TY_GetLength(proc, S);
		int *A = calloc(L + 1, sizeof(int));
		if (A == NULL) {
			Console.Error.WriteLine("Out of memory"); i7_fatal_exit();
		}
		for (int i=0; i<L; i++) A[i] = i7_fn_LIST_OF_TY_GetItem(proc, S, i+1, 0, 0);
		A[L] = 0;
		N = L;
		return A;
		#endif
		#if !i7_mgl_BASICINFORMKIT
		N = 0;
		return null;
		#endif

	}

	void i7_write_list(int S, out int A, int L) {
		#if i7_mgl_BASICINFORMKIT
		i7_fn_LIST_OF_TY_SetLength(proc, S, L, 0, 0, 0, 0, 0, 0);
		if (A) {
			for (int i=0; i<L; i++) 
				i7_fn_LIST_OF_TY_PutItem(proc, S, i+1, A[i], 0, 0);
		}
		#endif
		#if !i7_mgl_BASICINFORMKIT
		A = 0;
		#endif

	}
=

@ Lastly, this function allows an action to be tried -- something which is only
meaningful in an Inform project which uses WorldModelKit: it will fail in a
Basic Inform only project.

= (text to inform7_cslib.cs)
#if i7_mgl_TryAction
	int i7_fn_TryAction(int i7_mgl_local_req,
		int i7_mgl_local_by, int i7_mgl_local_ac, int i7_mgl_local_n,
		int i7_mgl_local_s, int i7_mgl_local_stora, int i7_mgl_local_smeta,
		int i7_mgl_local_tbits, int i7_mgl_local_saved_command,
		int i7_mgl_local_text_of_command);
	int i7_try(int action_id, int n, int s) {
		return i7_fn_TryAction(proc, 0, 0, action_id, n, s, 0, 0, 0, 0, 0);
	}
#endif
}
=

@ Because the C library file and its header are both wrapped inside conditional
compilations to guard against errors if they are included more than once, those
conditionals both need to be ended. So this is the bottom of both files: finis.

= (text to inform7_cslib.cs)
}
=
