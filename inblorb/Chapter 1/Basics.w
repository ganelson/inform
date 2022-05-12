[Basics::] Basics.

Some fundamental definitions.

@h Build identity.
This notation tangles out to the current build number as specified in the
contents section of this web.

@d PROGRAM_NAME "inblorb"

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate:

@e auxiliary_file_CLASS
@e chunk_metadata_CLASS
@e heading_CLASS
@e placeholder_CLASS
@e rdes_record_CLASS
@e request_CLASS
@e resource_number_CLASS
@e segment_CLASS
@e skein_node_CLASS
@e table_CLASS
@e template_CLASS
@e template_path_CLASS

@ And then expand:

=
DECLARE_CLASS(auxiliary_file)
DECLARE_CLASS(skein_node)
DECLARE_CLASS(chunk_metadata)
DECLARE_CLASS(placeholder)
DECLARE_CLASS(heading)
DECLARE_CLASS(table)
DECLARE_CLASS(rdes_record)
DECLARE_CLASS(resource_number)
DECLARE_CLASS(segment)
DECLARE_CLASS(request)
DECLARE_CLASS(template)
DECLARE_CLASS(template_path)

@h Simple allocations.
Not all of our memory will be claimed in the form of structures: now and then
we need to use the equivalent of traditional |malloc| and |calloc| routines.

@e RDES_MREASON
@e CHUNK_STORAGE_MREASON

=
void Basics::register_mreasons(void) {
	Memory::reason_name(RDES_MREASON, "resource descriptions");
	Memory::reason_name(CHUNK_STORAGE_MREASON, "chunk data storage");
}
