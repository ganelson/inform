[Writer::] Blorb Writer.

To write the Blorb file, our main output, to disc.

@h Blorbs.
"Blorb" is an IF-specific format, but it is defined as a form of IFF file.
IFF, "Interchange File Format", is a general-purpose wrapper format dating back
to the mid-1980s; it was designed as a way to gather together audiovisual media
for use on home computers. (Though Electronic Arts among others used IFF files
to wrap up entertainment material, Infocom, the pioneer of IF at the time, did
not.) Each IFF file consists of a chunk, but any chunk can contain other
chunks in turn. Chunks are identified with initial ID texts four characters
long. In different domains of computing, people use different chunks, and this
makes different sorts of IFF file look like different file formats to the end
user. So we have TIFF for images, AIFF for uncompressed audio, AVI for movies,
GIF for bitmap graphics, and so on.

@ Main variables:

=
int total_size_of_Blorb_chunks = 0; /* ditto, but not counting the |FORM| header or the |RIdx| chunk */
int no_indexed_chunks = 0;

@ As we shall see, chunks can be used for everything from a few words of
copyright text to 100MB of uncompressed choral music.

Our IFF file will consist of a front part and then the chunks, one after
another, in order of their creation. Every chunk has a type, a 4-character ID
like |"AUTH"| or |"JPEG"|, specifying what kind of data it holds; some
chunks are also given resource", " numbers which allow the story file to refer
to them as it runs -- the pictures, sound effects and the story file itself
all have unique resource numbers. (These are called "indexed", because
references to them appear in a special |RIdx| record in the front part
of the file -- the "resource index".)

@d MAX_CHUNK_DATA_STORED_IN_MEMORY MAX_FILENAME_LENGTH

=
typedef struct chunk_metadata {
	struct filename *chunk_file; /* if the content is stored on disc */
	unsigned char data_in_memory[MAX_CHUNK_DATA_STORED_IN_MEMORY]; /* if the content is stored in memory */
	int length_of_data_in_memory; /* in bytes; or $-1$ if the content is stored on disc */
	char *chunk_type; /* pointer to a 4-character string */
	char *index_entry; /* ditto */
	int resource_id; /* meaningful only if this is a chunk which is indexed */
	int byte_offset; /* from the start of the chunks, which is not quite the start of the IFF file */
	int size; /* in bytes */
	MEMORY_MANAGEMENT
} chunk_metadata;

@ It is not legal to have two or more Snd resources with the same number.  The
same goes for Pict resources.  These two linked lists are used to store all the
resource numbers encountered.

=
typedef struct resource_number {
	int num;
	MEMORY_MANAGEMENT
} resource_number;

linked_list *sound_resource = NULL; /* of |resource_number| */
linked_list *pict_resource = NULL; /* of |resource_number| */

@ And this is used to record alt-descriptions of resources, for the benefit
of partially sighted or deaf users:

=
typedef struct rdes_record {
	int usage;
	int resource_id;
	char *description;
	MEMORY_MANAGEMENT
} rdes_record;

@h Big-endian integers.
IFF files use big-endian integers, whereas Inblorb might or might not
(depending on the platform it runs on), so we need routines to write
32, 16 or 8-bit values in explicitly big-endian form:

=
void Writer::four_word(FILE *F, int n) {
	fputc((n / 0x1000000)%0x100, F);
	fputc((n / 0x10000)%0x100, F);
	fputc((n / 0x100)%0x100, F);
	fputc((n)%0x100, F);
}

void Writer::two_word(FILE *F, int n) {
	fputc((n / 0x100)%0x100, F);
	fputc((n)%0x100, F);
}

void Writer::one_byte(FILE *F, int n) {
	fputc((n)%0x100, F);
}

void Writer::s_four_word(unsigned char *F, int n) {
	F[0] = (unsigned char) (n / 0x1000000)%0x100;
	F[1] = (unsigned char) (n / 0x10000)%0x100;
	F[2] = (unsigned char) (n / 0x100)%0x100;
	F[3] = (unsigned char) (n)%0x100;
}

void Writer::s_two_word(unsigned char *F, int n) {
	F[0] = (unsigned char) (n / 0x100)%0x100;
	F[1] = (unsigned char) (n)%0x100;
}

void Writer::s_one_byte(unsigned char *F, int n) {
	F[0] = (unsigned char) (n)%0x100;
}

@h Chunks.
Although chunks can be written in a nested way -- that's the whole point
of IFF, in fact -- we will always be writing a very flat structure, in
which a single enclosing chunk (|FORM|) contains a sequence of chunks
with no further chunks inside.

=
chunk_metadata *current_chunk = NULL;

@ Each chunk is "added" in one of two ways. Either we supply a filename
for an existing binary file on disc which will hold the data we want to
write, or we supply a |NULL| filename and a |data| pointer to |length|
bytes in memory.

=
void Writer::add_chunk_to_blorb(char *id, int resource_num, filename *supplied_filename, char *index,
	unsigned char *data, int length) {
	if (Writer::chunk_type_is_legal(id) == FALSE)
		BlorbErrors::fatal("tried to complete non-Blorb chunk");
	if (Writer::index_entry_is_legal(index) == FALSE)
		BlorbErrors::fatal("tried to include mis-indexed chunk");
	if (length >= MAX_CHUNK_DATA_STORED_IN_MEMORY)
		BlorbErrors::fatal("too much chunk data stored in memory");

	current_chunk = CREATE(chunk_metadata);

	@<Set the filename for the new chunk@>;

    current_chunk->chunk_type = id;
	current_chunk->index_entry = index;
	if (current_chunk->index_entry) no_indexed_chunks++;
    current_chunk->byte_offset = total_size_of_Blorb_chunks;
    current_chunk->resource_id = resource_num;

	@<Compute the size in bytes of the chunk@>;
	@<Advance the total chunk size@>;

	if (verbose_mode)
		PRINT("! Begun chunk %s: fn is <%f> (innate size %d)\n",
			current_chunk->chunk_type, current_chunk->chunk_file, current_chunk->size);
}

@<Set the filename for the new chunk@> =
	if (data) {
		current_chunk->chunk_file = NULL;
		current_chunk->length_of_data_in_memory = length;
		int i;
		for (i=0; i<length; i++) current_chunk->data_in_memory[i] = data[i];
    } else {
    	current_chunk->chunk_file = supplied_filename;
		current_chunk->length_of_data_in_memory = -1;
    }

@<Compute the size in bytes of the chunk@> =
 	int size;
	if (data) {
 		size = length;
	} else {
		size = (int) BinaryFiles::size(supplied_filename);
	}
	if (Writer::chunk_type_is_already_an_IFF(current_chunk->chunk_type) == FALSE)
		size += 8; /* allow 8 further bytes for the chunk header to be added later */
    current_chunk->size = size;

@ Note the adjustment of |total_size_of_Blorb_chunks| so as to align the next
chunk's position at a two-byte boundary -- this betrays IFF's origin in the
16-bit world of the mid-1980s. Today's formats would likely align at four, eight
or even sixteen-byte boundaries.

@<Advance the total chunk size@> =
    total_size_of_Blorb_chunks += current_chunk->size;
    if ((current_chunk->size) % 2 == 1) total_size_of_Blorb_chunks++;

@h Our choice of chunks.
We will generate only the following chunks with the above apparatus. The full
Blorb specification does include others, but Inform doesn't need them.

The weasel words "with the above..." are because we will also generate two
chunks separately: the compulsory |"FORM"| chunk enclosing the entire Blorb, and
an indexing chunk, |"RIdx"|. Within this index, some chunks appear, but not
others, and they are labelled with the "index entry" text.

=
char *legal_Blorb_chunk_types[] = {
	"AUTH", "(c) ", "Fspc", "RelN", "IFmd", /* miscellaneous identifying data */
	"JPEG", "PNG ", /* images in different formats */
	"AIFF", "OGGV", "MIDI", "MOD ", /* sound effects in different formats */
	"ZCOD", "GLUL", /* story files in different formats */
	"RDes", /* resource descriptions (added to the standard in March 2014) */
	NULL };

char *legal_Blorb_index_entries[] = {
	"Pict", "Snd ", "Exec", NULL };

@ Because we are wisely paranoid:

=
int Writer::chunk_type_is_legal(char *type) {
	int i;
	if (type == NULL) return FALSE;
	for (i=0; legal_Blorb_chunk_types[i]; i++)
		if (strcmp(type, legal_Blorb_chunk_types[i]) == 0)
			return TRUE;
    return FALSE;
}

int Writer::index_entry_is_legal(char *entry) {
	int i;
	if (entry == NULL) return TRUE;
	for (i=0; legal_Blorb_index_entries[i]; i++)
		if (strcmp(entry, legal_Blorb_index_entries[i]) == 0)
			return TRUE;
    return FALSE;
}

@ This function checks a linked list to see if a resource number is used twice.
If so, TRUE is returned and the rest of the program is expected to immediately
exit with a fatal error. Otherwise, FALSE is returned, indicating that
everything is fine.

=
int Writer::resource_seen(linked_list *L, int value) {
	resource_number *rn;
	LOOP_OVER_LINKED_LIST(rn, resource_number, L)
		if (rn->num == value)
			return TRUE;
	rn = CREATE(resource_number);
	rn->num = value;
	ADD_TO_LINKED_LIST(rn, resource_number, L);	
	return FALSE;
}

@ Because it will make a difference to how we embed a file into our Blorb,
we need to know whether the chunk in question is already an IFF in its
own right. Only one type of chunk is, as it happens:

=
int Writer::chunk_type_is_already_an_IFF(char *type) {
	if (strcmp(type, "AIFF")==0) return TRUE;
	return FALSE;
}

@ |"AUTH"|: author's name, as a null-terminated string.

=
void Writer::author_chunk(text_stream *t) {
	if (verbose_mode) PRINT("! Author: <%S>\n", t);
    Writer::add_chunk_to_blorb("AUTH", 0, NULL, NULL, (unsigned char *) t, Str::len(t));
}

@ |"(c) "|: copyright declaration.

=
void Writer::copyright_chunk(text_stream *t) {
	if (verbose_mode) PRINT("! Copyright declaration: <%S>\n", t);
    Writer::add_chunk_to_blorb("(c) ", 0, NULL, NULL, (unsigned char *) t, Str::len(t));
}

@ |"Fspc"|: frontispiece image ID number -- which picture resource provides
cover art, in other words.

=
void Writer::frontispiece_chunk(int pn) {
	if (verbose_mode) PRINT("! Frontispiece is image %d\n", pn);
    unsigned char data[4];
    Writer::s_four_word(data, pn);
    Writer::add_chunk_to_blorb("Fspc", 0, NULL, NULL, data, 4);
}

@ |"RelN"|: release number.

=
void Writer::release_chunk(int rn) {
	if (verbose_mode) PRINT("! Release number is %d\n", rn);
    unsigned char data[2];
    Writer::s_two_word(data, rn);
    Writer::add_chunk_to_blorb("RelN", 0, NULL, NULL, data, 2);
}

@ |"Pict"|: a picture, or image. This must be available as a binary file on
disc, and in a format which Blorb allows: for Inform 7 use, this will always
be PNG or JPEG. There can be any number of these chunks.

=
void Writer::picture_chunk(int n, filename *fn, text_stream *alt) {
	char *type = "PNG ";
	int form = Filenames::guess_format(fn);
	if (form == FORMAT_PERHAPS_JPEG) type = "JPEG";
	else if (form == FORMAT_PERHAPS_PNG) type = "PNG ";
	else BlorbErrors::error_1f("image file has unknown file extension "
		"(expected e.g. '.png' for PNG, '.jpeg' for JPEG)", fn);

	if (n < 1) BlorbErrors::fatal("Picture resource number is less than 1");
	if (pict_resource == NULL) pict_resource = NEW_LINKED_LIST(resource_number);
	if (Writer::resource_seen(pict_resource, n))
		BlorbErrors::fatal("Duplicate Picture resource number");

    Writer::add_chunk_to_blorb(type, n, fn, "Pict", NULL, 0);
    if (Str::len(alt) > 0) {
    	int L = Str::len(alt)+1;
    	char *alt_Cs = Memory::malloc(L, STRING_STORAGE_MREASON);
    	Str::copy_to_ISO_string(alt_Cs, alt, L);
    	Writer::add_rdes_record(1, n, alt_Cs);
	}
	no_pictures_included++;
}

@ For images identified by name. The older Blorb creation program, |perlBlorb|,
would emit helpful I6 constant declarations, allowing the programmer to
include these an I6 source file and then write, say, |PlaySound(SOUND_Boom)|
rather than |PlaySound(5)|. (Whenever the Blurb file is changed, the constants
must be included again.)

=
void Writer::picture_chunk_text(text_stream *name, filename *F) {
	if (Str::len(name) == 0) {
		PRINT("! Null picture ID, using %d\n", picture_resource_num);
	} else {
		PRINT("Constant PICTURE_%S = %d;\n", name, picture_resource_num);
	}
	picture_resource_num++;
	Writer::picture_chunk(picture_resource_num, F, I"");
}

@ |"Snd "|: a sound effect. This must be available as a binary file on
disc, and in a format which Blorb allows: for Inform 7 use, this is officially
Ogg Vorbis or AIFF at present, but there has been repeated discussion about
adding MOD ("SoundTracker") or MIDI files, so both are supported here.

There can be any number of these chunks, too.

=
void Writer::sound_chunk(int n, filename *fn, text_stream *alt) {
	char *type = "AIFF";
	int form = Filenames::guess_format(fn);
	if (form == FORMAT_PERHAPS_OGG) type = "OGGV";
	else if (form == FORMAT_PERHAPS_MIDI) type = "MIDI";
	else if (form == FORMAT_PERHAPS_MOD) type = "MOD ";
	else if (form == FORMAT_PERHAPS_AIFF) type = "AIFF";
	else BlorbErrors::error_1f("sound file has unknown file extension "
		"(expected e.g. '.ogg', '.midi', '.mod' or '.aiff', as appropriate)", fn);

	if (n < 3) BlorbErrors::fatal("Sound resource number is less than 3");
	if (sound_resource == NULL) sound_resource = NEW_LINKED_LIST(resource_number);
	if (Writer::resource_seen(sound_resource, n)) BlorbErrors::fatal("Duplicate Sound resource number");

    Writer::add_chunk_to_blorb(type, n, fn, "Snd ", NULL, 0);
    if (Str::len(alt) > 0) {
    	int L = Str::len(alt)+1;
    	char *alt_Cs = Memory::malloc(L, STRING_STORAGE_MREASON);
    	Str::copy_to_ISO_string(alt_Cs, alt, L);
    	Writer::add_rdes_record(2, n, alt_Cs);
	}
	no_sounds_included++;
}

@ And again, by name:

=
void Writer::sound_chunk_text(text_stream *name, filename *F) {
	if (Str::len(name) == 0) {
		PRINT("! Null sound ID, using %d\n", sound_resource_num);
	} else {
		PRINT("Constant SOUND_%S = %d;\n", name, sound_resource_num);
	}
	sound_resource_num++;
	Writer::sound_chunk(sound_resource_num, F, I"");
}

@ |"RDes"|: the resource description, a repository for alt-texts describing
images or sounds.

=
size_t size_of_rdes_chunk = 0;

void Writer::add_rdes_record(int usage, int n, char *alt) {
	rdes_record *rr = CREATE(rdes_record);
	rr->usage = usage;
	rr->resource_id = n;
	rr->description = Memory::new_string(alt);
	size_of_rdes_chunk += 12 + (size_t) strlen(alt);
}

void Writer::rdes_chunk(void) {
	if (size_of_rdes_chunk > 0) {
		unsigned char *rdes_data =
			(unsigned char *) Memory::malloc((int) size_of_rdes_chunk + 9, RDES_MREASON);
		if (rdes_data == NULL) BlorbErrors::fatal("Run out of memory");
		size_t pos = 4;
		Writer::s_four_word(rdes_data, NUMBER_CREATED(rdes_record));
		rdes_record *rr;
		LOOP_OVER(rr, rdes_record) {
			if (rr->usage == 1) strcpy((char *) (rdes_data + pos), "Pict");
			else if (rr->usage == 2) strcpy((char *) (rdes_data + pos), "Snd ");
			else Writer::s_four_word(rdes_data + pos, 0);
			Writer::s_four_word(rdes_data + pos + 4, rr->resource_id);
			Writer::s_four_word(rdes_data + pos + 8, (int) strlen(rr->description));
			strcpy((char *) (rdes_data + pos + 12), rr->description);
			pos += 12 + (size_t) strlen(rr->description);
		}
		if (pos != size_of_rdes_chunk + 4) BlorbErrors::fatal("misconstructed rdes");
		Writer::add_chunk_to_blorb("RDes", 0, NULL, NULL, rdes_data, (int) pos);
	}
}

@ |"Exec"|: the executable program, which will normally be a Z-machine or
Glulx story file. It's legal to make a blorb with no story file in, but
Inform 7 never does this.

=
void Writer::executable_chunk(filename *fn) {
	char *type = "ZCOD";
	int form = Filenames::guess_format(fn);
	if (form == FORMAT_PERHAPS_GLULX) type = "GLUL";
	else if (form == FORMAT_PERHAPS_ZCODE) type = "ZCOD";
	else BlorbErrors::error_1f("story file has unknown file extension "
		"(expected e.g. '.z5' for Z-code, '.ulx' for Glulx)", fn);

	Writer::add_chunk_to_blorb(type, 0, fn, "Exec", NULL, 0);
}

@ |"IFmd"|: the bibliographic data (or "metadata") about the work of IF
being blorbed up, in the form of an iFiction record. (The format of which
is set out in the "Treaty of Babel" agreement.)

=
void Writer::metadata_chunk(filename *fn) {
    Writer::add_chunk_to_blorb("IFmd", 0, fn, NULL, NULL, 0);
}

@h Main construction.

=
void Writer::write_blorb_file(filename *out) {
	Writer::rdes_chunk();
	if (NUMBER_CREATED(chunk_metadata) == 0) return;

	FILE *IFF = BinaryFiles::open_for_writing(out);

	int RIdx_size, first_byte_after_index;
	@<Calculate the sizes of the whole file and the index chunk@>;
	@<Write the initial FORM chunk of the IFF file, and then the index@>;
	if (verbose_mode) @<Print out a copy of the chunk table@>;

	chunk_metadata *chunk;
	LOOP_OVER(chunk, chunk_metadata) @<Write the chunk@>;

	BinaryFiles::close(IFF);
}

@ The bane of IFF file generation is that each chunk has to be marked
up-front with an offset to skip past it. This means that, unlike with XML
or other files having flexible-sized ingredients delimited by begin-end
markers, we always have to know the length of a chunk before we start
writing it.

That even extends to the file itself, which is a single IFF chunk of type
|"FORM"|. So we need to think carefully. We will need the |FORM| header,
then the header for the |RIdx| indexing chunk, then the body of that indexing
chunk -- with one record for each indexed chunk; and then room for all of
the chunks we'll copy in, whether they are indexed or not.

@<Calculate the sizes of the whole file and the index chunk@> =
	int FORM_header_size = 12;
	int RIdx_header_size = 12;
	int index_entry_size = 12;

	RIdx_size = RIdx_header_size + index_entry_size*no_indexed_chunks;

	first_byte_after_index = FORM_header_size + RIdx_size;

	blorb_file_size = first_byte_after_index + total_size_of_Blorb_chunks;

@ Each different IFF file format is supposed to provide its own "magic text"
identifying what the file format is, and for Blorbs that text is "IFRS",
short for "IF Resource".

@<Write the initial FORM chunk of the IFF file, and then the index@> =
	fprintf(IFF, "FORM");
	Writer::four_word(IFF, blorb_file_size - 8); /* offset to end of |FORM| after the 8 bytes so far */
	fprintf(IFF, "IFRS"); /* magic text identifying the IFF as a Blorb */

	fprintf(IFF, "RIdx");
	Writer::four_word(IFF, RIdx_size - 8); /* offset to end of |RIdx| after the 8 bytes so far */
	Writer::four_word(IFF, no_indexed_chunks); /* i.e., number of entries in the index */

	chunk_metadata *chunk;
	LOOP_OVER(chunk, chunk_metadata)
		if (chunk->index_entry) {
			fprintf(IFF, "%s", chunk->index_entry);
			Writer::four_word(IFF, chunk->resource_id);
			Writer::four_word(IFF, first_byte_after_index + chunk->byte_offset);
		}

@ Most of the chunks we put in exist on disc without their headers, but AIFF
sound files are an exception, because those are IFF files in their own right;
so they come with ready-made headers.

@<Write the chunk@> =
	int bytes_to_copy;
	char *type = chunk->chunk_type;
	if (Writer::chunk_type_is_already_an_IFF(type) == FALSE) {
		fprintf(IFF, "%s", type);
		Writer::four_word(IFF, chunk->size - 8); /* offset to end of chunk after the 8 bytes so far */
		bytes_to_copy = chunk->size - 8; /* since here the chunk size included 8 extra */
	} else {
		bytes_to_copy = chunk->size; /* whereas here the chunk size was genuinely the file size */
	}

	if (chunk->length_of_data_in_memory >= 0)
		@<Copy that many bytes from memory@>
	else
		@<Copy that many bytes from the chunk file on the disc@>;

	if ((bytes_to_copy % 2) == 1) Writer::one_byte(IFF, 0); /* as we allowed for above */

@ Sometimes the chunk's contents are on disc:

@<Copy that many bytes from the chunk file on the disc@> =
	FILE *CHUNKSUB = BinaryFiles::open_for_reading(chunk->chunk_file);
	for (int i=0; i<bytes_to_copy; i++) {
		int j = fgetc(CHUNKSUB);
		if (j == EOF) BlorbErrors::fatal_fs("chunk ran out incomplete", chunk->chunk_file);
		Writer::one_byte(IFF, j);
	}
	BinaryFiles::close(CHUNKSUB);

@ And sometimes, for shorter things, they are in memory:

@<Copy that many bytes from memory@> =
	int i;
	for (i=0; i<bytes_to_copy; i++) {
		int j = (int) (chunk->data_in_memory[i]);
		Writer::one_byte(IFF, j);
	}

@ For debugging purposes only:

@<Print out a copy of the chunk table@> =
	PRINT("! Chunk table:\n");
	chunk_metadata *chunk;
	LOOP_OVER(chunk, chunk_metadata)
		PRINT("! Chunk %s %06x %s %d <%f>\n",
			chunk->chunk_type, chunk->size,
			(chunk->index_entry)?(chunk->index_entry):"unindexed",
			chunk->resource_id,
			chunk->chunk_file);
	PRINT("! End of chunk table\n");
