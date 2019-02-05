[Basics::] Basics.

Some fundamental definitions.

@h Build identity.
This notation tangles out to the current build number as specified in the
contents section of this web.

@d INTOOL_NAME "inblorb"
@d CBLORB_BUILD "inblorb [[Build Number]]"

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e auxiliary_file_MT
@e skein_node_MT
@e chunk_metadata_MT
@e placeholder_MT
@e heading_MT
@e table_MT
@e segment_MT
@e request_MT
@e template_MT
@e template_path_MT
@e rdes_record_MT

@ And then expand:

=
ALLOCATE_INDIVIDUALLY(auxiliary_file)
ALLOCATE_INDIVIDUALLY(skein_node)
ALLOCATE_INDIVIDUALLY(chunk_metadata)
ALLOCATE_INDIVIDUALLY(placeholder)
ALLOCATE_INDIVIDUALLY(heading)
ALLOCATE_INDIVIDUALLY(table)
ALLOCATE_INDIVIDUALLY(rdes_record)
ALLOCATE_INDIVIDUALLY(segment)
ALLOCATE_INDIVIDUALLY(request)
ALLOCATE_INDIVIDUALLY(template)
ALLOCATE_INDIVIDUALLY(template_path)

@h Simple allocations.
Not all of our memory will be claimed in the form of structures: now and then
we need to use the equivalent of traditional |malloc| and |calloc| routines.

@e RDES_MREASON

=
void Basics::register_mreasons(void) {
	Memory::reason_name(RDES_MREASON, "resource descriptions");
}
