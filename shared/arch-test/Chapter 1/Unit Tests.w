[Unit::] Unit Tests.

How we shall test it.

@ =
void Unit::test_compatibility(OUTPUT_STREAM) {
	Unit::test_one(OUT, I"for all");
	Unit::test_one(OUT, I"all");
	Unit::test_one(OUT, I"not for all");
	Unit::test_one(OUT, I"not all");
	Unit::test_one(OUT, I"for none");
	Unit::test_one(OUT, I"none");
	Unit::test_one(OUT, I"not for none");
	Unit::test_one(OUT, I"not none");
	Unit::test_one(OUT, I"for 16-bit with debugging");
	Unit::test_one(OUT, I"not for 32-bit");
	Unit::test_one(OUT, I"for 16-bit with debugging or 32-bit with debugging");
	Unit::test_one(OUT, I"not for 32-bit or 16-bit");
	Unit::test_one(OUT, I"for 16-bit with debugging, 32-bit with debugging or 32-bit");
	Unit::test_one(OUT, I"not for 16-bit with debugging, 32-bit with debugging or 32-bit");
	Unit::test_one(OUT, I"for glulx");
	Unit::test_one(OUT, I"for glulx or z-machine version 8");
	Unit::test_one(OUT, I"for glulx without debugging");
	Unit::test_one(OUT, I"for z-machine version 8");
	Unit::test_one(OUT, I"for z-machine version 5 with debugging");
	Unit::test_one(OUT, I"for z-machine version 8, or Glulx without debugging");
	Unit::test_one(OUT, I"for z-machine version 5 or 8");
}

void Unit::test_one(OUTPUT_STREAM, text_stream *test) {
	WRITE("'%S': ", test);
	compatibility_specification *C = Compatibility::from_text(test);
	if (C == NULL) { WRITE("not a valid compatibility specification\n\n"); return; }
	Compatibility::write(OUT, C);
	WRITE(":\n"); INDENT;
	target_vm *VM;
	LOOP_OVER(VM, target_vm) {
		if (Compatibility::test(C, VM)) {
			TargetVMs::write(OUT, VM);
			WRITE("\n");
		}
	}
	OUTDENT; WRITE("\n");
}
