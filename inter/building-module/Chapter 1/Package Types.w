[PackageTypes::] Package Types.

To manage the different types of packages emitted by Inform.

@h Package types.
Inter code is a nested hierarchy of "packages", which can be assigned "types".
Inter requires two types to exist, |_plain| and |_code|, and leaves the rest
to the user (i.e., us) to define as we see fit. In fact Inform generates
packages of slightly over 50 different types.

At run time, package types are pointers to the inter symbol which defined them,
but this is not a convenient way to refer to them in the Inform source code.
Instead we use the following function:

=
inter_symbol *PackageTypes::get(inter_tree *I, text_stream *name) {
	inter_symbols_table *scope = InterTree::global_scope(I);

	inter_symbol *ptype = InterSymbolsTables::symbol_from_name(scope, name);
	if (ptype == NULL) {
		int enclose = TRUE;
		@<Decide if this package type is to be enclosing@>;
		ptype = Produce::new_symbol(scope, name);
		Produce::guard(Inter::PackageType::new_packagetype(
			Site::package_types(I), ptype,
			0, NULL));
		if (enclose) Produce::annotate_symbol_i(ptype, ENCLOSING_IANN, 1);
	}
	return ptype;
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

@ Symbol lookups by name are fast, but not instant, so we might some day
want to optimise this by cacheing the result:

=
inter_symbol *PackageTypes::function(inter_tree *I) {
	return PackageTypes::get(I, I"_function");
}
