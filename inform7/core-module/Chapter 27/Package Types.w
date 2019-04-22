[PackageTypes::] Package Types.

To manage the different types of packages emitted by Inform.

@h Package types.
Inter code is a nested hierarchy of "packages", which can be assigned "types".
Inter requires two types to exist, |_plain| and |_code|, and leaves the rest
to the user (i.e., us) to define as we see fit. In fact Inform generates
packages of slightly over 50 different types.

At run time, package types are pointers to the inter symbol which defined them,
but this is not a convenient way to refer to them in the Inform source code.
Instead we use the following dictionary in order to be able to refer to them
by name. So, for example, |PackageTypes::get(I"_cake")| returns the package
type for |_cake|, declaring it if it doesn't already exist.

=
dictionary *ptypes_indexed_by_name = NULL;
int ptypes_created = FALSE;

inter_symbol *PackageTypes::get(text_stream *name) {
	if (ptypes_created == FALSE) {
		ptypes_created = TRUE;
		ptypes_indexed_by_name = Dictionaries::new(512, FALSE);
	}
	if (Dictionaries::find(ptypes_indexed_by_name, name))
		return (inter_symbol *) Dictionaries::read_value(ptypes_indexed_by_name, name);
	
	int enclose = TRUE;
	@<Decide if this package type is to be enclosing@>;
	
	inter_symbol *new_ptype = Emit::packagetype(name, enclose);
	Dictionaries::create(ptypes_indexed_by_name, name);
	Dictionaries::write_value(ptypes_indexed_by_name, name, (void *) new_ptype);
	return new_ptype;
}

@ Most package types are "enclosing". Suppose that Inform is compiling
something to go into the package, but finds that it needs to compile something
else in order to do so -- for example, it's compiling code to set a variable
to be equal to a literal piece of text, which must itself be compiled as a
small array. Where does Inform put that array? If the current package is
"enclosing", then Inform puts it into the package itself; and if not, then
into the package holding the current package, if that in turn is "enclosing";
and so on.

It seems tidy to make all packages enclosing, and in fact (after much
experiment) Inform nearly does that. But |_code| packages have to be an
exception, because the Inter specification doesn't allow constants (and
therefore arrays) to be defined inside |_code| packages.

@<Decide if this package type is to be enclosing@> =
	if (Str::eq(name, I"_code")) enclose = FALSE;

@ Dictionary lookups by name are fast, but not instant, and the one package
type which we need frequently is |_function|, so we cache that one:

=
inter_symbol *function_ptype = NULL;
inter_symbol *PackageTypes::function(void) {
	if (function_ptype == NULL) function_ptype = PackageTypes::get(I"_function");
	return function_ptype;
}
