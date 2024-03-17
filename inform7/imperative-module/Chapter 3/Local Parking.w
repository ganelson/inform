[LocalParking::] Local Parking.

Like Free Parking in Monopoly, except that it is not free and has an overhead cost.

@ This is one of several devices we employ to get around the lack of a call stack
in memory. Suppose we want the local variables in function A to be visible to
function B, which is called from A, and suppose they cannot be passed as call
parameters to B. B cannot access them using pointers to the stack frame for A,
because the call stack does not exist in memory. What to do?

What we do is to stash them into a "local parking" array, make the call to B,
and then in the code for B retrieve them again. A paraphrase might look
like this:
= (text)
void A(void) {
	int alpha = 2, beta = 3, gamma = 5;
	lp[0] = alpha;
	lp[1] = beta;
	lp[2] = gamma;
	B();
}

void B(void) {
	int alpha = lp[0];
	int beta = lp[1];
	int gamma = lp[2];
	...
}
=
Note that B can now read, but not write, the locals from A. The scratch array
|lp| used here for storage is meaningless except for immediately before and
after the call to B, so we don't need to worry about multiple uses of local
parking getting in each other's way.

@ This compiles the necessary code before the call to B:

=
int LocalParking::park(stack_frame *frame, local_parking_lot *lot) {
	int NC = 0;
	local_variable *lvar;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame) NC++;
	if (NC > 0) {
		inter_name *park = LocalParking::array(NC, lot);
		inter_ti j = 0;
		LOOP_OVER_LOCALS_IN_FRAME(lvar, frame) {
			EmitCode::inv(SEQUENTIAL_BIP);
			EmitCode::down();
				EmitCode::inv(STORE_BIP);
				EmitCode::down();
					EmitCode::reference();
					EmitCode::down();
						EmitCode::inv(LOOKUP_BIP);
						EmitCode::down();
							EmitCode::val_iname(K_value, park);
							EmitCode::val_number(j++);
						EmitCode::up();
					EmitCode::up();
					inter_symbol *lvar_s = LocalVariables::declare(lvar);
					EmitCode::val_symbol(K_value, lvar_s);
				EmitCode::up();
		}
	}
	return NC;
}

int LocalParking::park_with_private_lot(stack_frame *frame, rule *R, int marker) {
	int NC = 0;
	local_variable *lvar;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame) NC++;
	if (NC > 0) {
		local_parking_lot *lot = Responses::enable_private_parking(R, marker);
		LocalParking::array(NC, lot);
		return LocalParking::park(frame, lot);
	}
	return 0;
}

@ And this compiles the retrieval code just after B begins:

=
void LocalParking::retrieve(stack_frame *frame, local_parking_lot *lot) {
	inter_name *park = LocalParking::array(0, lot);
	inter_ti j=0;
	local_variable *lvar;
	LOOP_OVER_LOCALS_IN_FRAME(lvar, frame) {
		EmitCode::inv(STORE_BIP);
		EmitCode::down();
			EmitCode::ref_symbol(K_value, LocalVariables::declare(lvar));
			EmitCode::inv(LOOKUP_BIP);
			EmitCode::down();
				EmitCode::val_iname(K_value, park);
				EmitCode::val_number(j++);
			EmitCode::up();
		EmitCode::up();
	}
}

@ We support multiple different parking lots, though we almost always use a
single shared parking lot when we can prove that the values in it will not be
corrupted before use.

=
typedef struct local_parking_lot {
	int capacity;
	struct inter_name *storage_iname;
	CLASS_DEFINITION
} local_parking_lot;

local_parking_lot *shared_parking = NULL;

local_parking_lot *LocalParking::new_lot(inter_name *iname) {
	local_parking_lot *lot = CREATE(local_parking_lot);
	lot->capacity = 2;
	lot->storage_iname = iname;
	return lot;
}

@ So, then, this returns the array to use for storage, ensuring that it has
a capacity of at least |N|, and therefore has entries in the range |0 <= x < N|.

=
inter_name *LocalParking::array(int N, local_parking_lot *lot) {
	if (lot == NULL) {
		if (shared_parking == NULL)
			shared_parking = LocalParking::new_lot(Hierarchy::find(LOCALPARKING_HL));
		lot = shared_parking;
	}
	if (N > lot->capacity) lot->capacity = N;
	return lot->storage_iname;
}

@ We also sometimes use the shared parking lot to hold returned callings from
deferred propositions; and that needs to be large enough to hold values of
up to 26 variables, plus a single other value.

=
inter_name *LocalParking::callings(void) {
	return LocalParking::array(27, NULL);
}

@ The parking lot(s) is/are initialised to arrays of zero values: their
contents are meaningless at the start of execution.

=
void LocalParking::compile_array(void) {
	local_parking_lot *lot;
	LOOP_OVER(lot, local_parking_lot) {
		packaging_state save = EmitArrays::begin_word(lot->storage_iname, K_value);
		for (int i=0; i<lot->capacity; i++) EmitArrays::numeric_entry(0);
		EmitArrays::end(save);
//		Hierarchy::make_available(lot->storage_iname);
	}
}
