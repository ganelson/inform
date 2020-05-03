What This Module Does.

An overview of the supervisor module's role and abilities.

@h Prerequisites.
The supervisor module is a part of the Inform compiler toolset. It is
presented as a literate program or "web". Before diving in:
(a) It helps to have some experience of reading webs: see //inweb// for more.
(b) The module is written in C, in fact ANSI C99, but this is disguised by the
fact that it uses some extension syntaxes provided by the //inweb// literate
programming tool, making it a dialect of C called InC. See //inweb// for
full details, but essentially: it's C without predeclarations or header files,
and where functions have names like |Tags::add_by_name| rather than just |add_by_name|.
(c) This module uses other modules drawn from the //compiler//, and also
uses a module of utility functions called //foundation//.
For more, see //foundation: A Brief Guide to Foundation//.

@h The Supervisor and its Parent.
The //supervisor// module is part of both //inform7// and //inbuild//, and acts
as a build manager. To compile an Inform project is not so atomic a task as
it sounds, because the project involves not only the original source text but
also some extensions, and they may need kits of Inter code, which may need to
be assimilated using pipelines, ... and so on. //supervisor// manages this:
it finds such dependent resources, and sees that they are ready as needed.

When included in //inform7//, the Supervisor is given a single task which
is always the same: build the current Inform 7 project. (See //core: Main Routine//.)
But when included in //inbuild//, it might be asked to perform quite a variety
of tasks, sometimes several at once, as specified by the user at the command line.
(See //inbuild: Main//.) In this discussion, "the parent" means the tool which
is using //supervisor//, and might be either //inform7// or //inbuild//.

@ //supervisor// has a relationship with its parent tool which involves to and
fro: it's not as simple as single one-time call from the parent to //supervisor//
saying "now build this".

(1) //supervisor// has to be started and stopped at each end of the parent's
run, by calling //SupervisorModule::start// and //SupervisorModule::end//.
The former calls //Supervisor::start// in turn, and that activates a number of
subsystems with further calls. But all modules do something like this.
(2) More unusually, when the parent is creating its command-line options, it
should call //Supervisor::declare_options// to add more. This allows all tools
containing the Supervisor to offer a unified set of command-line options to
configure it.[1] When the parent is given a switch that it doesn't recognise,
it should call //Supervisor::option//; and when it has fully processed the
command line, it should call //Supervisor::optioneering_complete//.
(3) The parent can now, if it chooses, make calls into //supervisor// to set
up additional dependencies. But eventually it will call //Supervisor::go_operational//.
The Supervisor is now ready for use!

There is no single "go" button: instead, the Supervisor provides a suite
of functions to call, each acting on a "copy" -- an instance of some software
at a given filing system location. When //inform7// is the parent, it follows
the call to //Supervisor::go_operational// with a single call to //Copies::build//
on the copy representing the current Inform 7 project. But when //inbuild//
is the parent, a variety of other functions may be made.

[1] Compare //inform7: Reference Card// and //inbuild: Reference Card//
to see the effect.

@h Genre, work, edition, copy.
A "genre" is a category of software or artistic work for us to manage. For
example, "Inform 7 extension" and "website template" are both genres. Each
different genre is represented by an //inbuild_genre// object, whose method
calls provide the behaviour distinctive to that genre. The currently seven
genre objects are created during //Supervisor::start//, which calls out to
//ExtensionManager::start//, //KitManager::start//, and so on: the seven
sections of //Chapter 4// are exactly the method calls for the seven genre
objects.

A "work" is a single artistic or programming creation; for example, the IF
story Bronze by Emily Short might be a work. Each different one we deal with
is represented by an //inbuild_work// object. Works are identified by genre,
title and author name, but see //Works::normalise_casing// for exactly how.

An "edition" is a versioned work; for example, release 7 of Bronze by Emily
Short is an edition. These are represented by //inbuild_edition// objects.
Such objects carry with them a note of which virtual machine architectures
they work with: see //arch: Compatibility// for more on this.

A "copy" is an instance of an edition actually present somewhere in the file
system -- note that we might have several copies of the same edition in
different places. Each copy known to the Supervisor is an //inbuild_copy// object.

When copies are claimed, they are typically scanned -- exactly how depends
on the genre -- and this can reveal damage: if so, a //copy_error// object is
attached to the copy for each different defect turned up. These errors are not
necessarily reported at once, or at all: if they are reported, the function
//CopyErrors::write// is used to write a suitable command-line error, but it's
also possible for the parent to issue its own errors instead. |inform7|
does this to convert copy errors into Inform problem messages: see
//core: Problems With Source Text//.[1]

[1] Note that because it is //supervisor// which causes source text to be read
in, and not //core//, lexical problems such as improperly paired comment
brackets or overly long quoted strings will come to light as copy errors,
as will blunders in identifying extensions. In general, though, a copy which
has no copy errors is not necessarily a correct program: only one which is
in good enough condition for the compiler to look at.

@h Searches and requirements.
Copies may be strewn all over the user's file system, and it's not for us to
go poking around without being asked.[1] Instead, the user will give the
parent tool some locations at the command line: and those command-line
instructions will be processed by //supervisor//. For example, if the user
typed:
= (text as ConsoleText)
	$ inform7 -internal inform7/Internal -external ~/mystuff -project Tadpoles.inform
=
then all three command-line switches here would actually be parsed by
//Supervisor::option//, rather than by anything in the //core// module.
They would set the "internal" and "external" nest (see //inbuild: Manual//),
creating an //inbuild_nest// object for each. The Inform 7 project for the
run would also be set.[2] This would become whose genre is |project_bundle_genre|.

Other copies would swiftly be needed -- the definition of the English language
(found inside the Internal nest), the Standard Rules extension, and several more.
These are not explicitly named on the command line: instead, they are found by
searching through the nests. //supervisor// does this by creating an
//inbuild_requirement// object to specify what it wants, and then calling its
search engine //Nests::search_for//. This builds a list of //inbuild_search_result//
objects, each pointing to a new copy which matches the requirement given.

Requirements can be quite flexible, and are converitble to and from text: see
//Requirements::from_text// and //Requirements::write//.[3] The crucial routine
here is //Requirements::meets//, which tests whether an edition meets the
requirement.

[1] Indeed, such a scan would violate sandboxing restrictions, for example
when //supervisor// is running as part of //inform7// inside the MacOS Inform app.

[2] The project, singular: see the Limitation note below.

[3] A typical requirement might read, say, "genre=extension, author=Emily Short",
which matches any extension by Emily Short.

@ Although such searches can be used with vague requirements to scan for,
say, everything with a given genre, they can also be used to seek specific
pieces of software which we will need. //Nests::search_for_best// is a version
of the search engine which returns a single result (or none): the best one.
Best is defined by //Nests::better_result// and makes careful use of both
semantic versioning and the user's intentions to ensure a happy outcome.
For example, if an Inform project says

>> Include Upturned Faces by Raphael.

then //Nests::search_for_best// will be used to seek which copy of this
extension to use.

@h Discovery.
A copy is "claimed" when it is found in the file system: either by being
right where the user said it would be, or by a search.

When the search engine wants to look for, say, kits in a given nest, it will
ask the kit genre how to do this, by a method call: and this will be handled
by //KitManager::search_nest_for//. That enables kits to be looked for in
a different part of a nest than extensions, for example. Similarly, each
genre scans and generally vets a copy differently, attaching copy errors
for different reasons. But in general, a function like //KitManager::new_copy//
will "claim" the copy.

For most genres, we want each copy to be claimed only once. We might run
into the copy of version 1.2 of |WorldModelKit| at |inform7/Internal/Inter|
for multiple reasons, as a result of several different searches: we want to
return the same //inbuild_copy// object each time we do, rather than create
duplicates. This is done with a dictionary of pathnames: i.e., the Kit
Manager keeps a dictionary of which pathnames lead to copies it has already
claimed. Most other managers do the same.

But if a new //inbuild_copy// is made, then we also give it a rich set of
genre-specific metadata by attaching "content". In this case, that will be
an //inform_kit// object, and code in //Kit Services// will provide
special functionality by working on this //inform_kit//. If |C| is a copy
which is a kit, then |KitManager::from_copy(C)| produces its //inform_kit//
object |K|; conversely, |K->as_copy| produces |C| again. They correspond in
a one-to-one fashion.

This table summarises the genres, where they managed, what type of metadata
object is attached to each copy of that genre, and where such metadata is
handled. Note that the two Inform project genres -- one for single files,
one for whole bundles -- share a metadata format: a project is a project,
however it is managed on disc.
= (hyperlinked text)
	GENRE INSTANCE        WHOSE METHODS ARE AT     COPIES GET AN     WHICH IS HANDLED BY
    extension_genre       //Extension Manager//        inform_extension  //Extension Services//        
    kit_genre             //Kit Manager//              inform_kit        //Kit Services//
    language_genre        //Language Manager//         inform_language   //Language Services//
    pipeline_genre        //Pipeline Manager//         inform_pipeline   //Pipeline Services//
    project_bundle_genre  //Project Bundle Manager//   inform_project    //Project Services//
    project_file_genre    //Project File Manager//     inform_project    //Project Services//
    template_genre        //Template Manager//         inform_template   //Template Services//
=

@h Limitation.
A pragmatic design choice in the Supervisor is that, although it can manage
large numbers of copies and dependencies simultaneously -- and often does,
when managing extensions or kits, for example -- it imposes one big limitation
for simplicity's sake.

(a) It can claim only one full-scale Inform 7 project in a single run.
To find this, call //Supervisor::project//, which returns the associated
//inform_project// object. Of course, there doesn't have to be even one,
in which case this returns |NULL|.
(b) This can be built for just one virtual machine architecture in a single
run. To find it, call //Supervisor::current_vm//.
(c) There is consequently a single |.Materials| directory to worry about --
the one for the current project. Its pathname can be found by calling
//Supervisor::materials//.
(d) And because the search list of nests has to include the |.Materials|
directory as one of those nests, there is just one search list at a time.
This can be found with //Supervisor::nest_list//, while the nest designated
as "internal" and "external" are //Supervisor::internal// and //Supervisor::external//.

It would be more elegant not to impose these restrictions, but the result would
seldom be more useful. It's easy enough to batch-run Inbuild with shell
scripting to handle multiple projects; |inform7| can only handle one project
on each run anyway; and constantly having to specify which project we mean in
function calls would involve much more passing of parameters around.

@h Build graph.
See //Build Graphs// for the infrastructure of how a dependency graph is stored.
Basically these consist of //build_vertex// objects joined together by edges,
represented by lists of other vertices -- each vertex has two lists, one of
"use edges", the other of "build edges". See the manual at //inbuild: Using Inbuild//
for an explanation and examples.

There are three "colours" of vertex: copy, file and requirement. Each copy
vertex corresponds to a single //inbuild_copy// and vice versa: thus, the
dependencies for a copy are represented by the component of the graph which
runs out from its vertex. File vertices correspond to single files needed
during a build process, and requirement vertices to unfilled requirements,
such as extensions which could not be found.

The three colours of vertex are created by //Graphs::copy_vertex//,
//Graphs::file_vertex// and //Graphs::req_vertex// respectively, and the
two colours of edge by //Graphs::need_this_to_build// and //Graphs::need_this_to_use//.

@ When are graphs actually built? It would be appealing to do this the moment a
copy is claimed (i.e., as soon as the //inbuild_copy// object is created),
but this is impractical: it happens before we know enough about dependencies.
So when a copy is claimed it gets an isolated copy vertex with no edges, as a
placeholder.

The answer in fact depends on genre. For pipelines, languages and website
templates, there are no dependencies, so there's nothing to build. For kits
and projects, the task is performed by //KitManager::construct_graph//,
//ProjectBundleManager::construct_graph//, and //ProjectFileManager::construct_graph//
respectively -- though in fact those three functions simply pass the buck to
//Kits::construct_graph// and //Projects::construct_graph//.

All of that happens when the Supervisor "goes operational", because
//Supervisor::go_operational// calls //Copies::construct_graph// for
every extant copy. The idea is that all the graphs need to be made before we
can be ready to do any building.

And yet... they are not, because extensions dependencies are missing from
this account. Extensions have rich dependency graphs, but they are built
on demand as the need arises, not at the going operational stage. This is
becauses //supervisor// may have to deal with very large numbers of
extension copies (for example, when performing a census inside the Inform
app, or to install or copy extensions), and it takes significant computation
to read and parse the full text of extensions.[1]

[1] Arguably the speed hit would be worth it for the gain in simplicity,
except that there's also another obstacle: an extension's dependencies
depend on the virtual machine they are to be used for. Some extensions
claimed during searches will not be compatible with the current VM at all,
and that's fine, since they won't be used: but we can't read their text in
without throwing copy errors. We solve this by reading in only those
extensions we will actually use, and that means building the graph only
for those.

@h Reading source text.
For any copy, //Copies::get_source_text// will instruct the Supervisor to
read in the Inform source text associated with it -- if any: this does nothing
for languages, pipelines, website templates or kits. Text for a copy is read
at most once, and is cached so that a second read produces the same result
as the first.

Reading is performed by //Projects::read_source_text_for// and
//Extensions::read_source_text_for//. For extensions this involves reading
only a single file, but for projects it can involve multiple files. Each
such is read by a call to //SourceText::read_file//, which then sends out
to the //words// module to break the text file into a stream of words:
see //words: Text From Files//. But it is //SourceText::read_file// which
prints console messages like these:
= (text as ConsoleText)
	I've now read your source text, which is 70 words long.
	I've also read Basic Inform by Graham Nelson, which is 7645 words long.
	I've also read English Language by Graham Nelson, which is 2328 words long.
	I've also read Standard Rules by Graham Nelson, which is 32123 words long.
=
Any lexical errors arising in //words// are converted by us into copy errors
and attached to the //inbuild_copy// object for the extension or project.

The text is not left as a simple stream of words, but is also "sentence-broken"
into a syntax tree: that service is also one we subcontract out, to the
//syntax// module. (See //syntax: Sentences// for details of how.) Once
again, syntax errors can arise, and once again, these are converted into
copy errors.

It might seem beyond the scope of a build manager to have to construct a
syntax tree for the Inform source text it encounters. But (a) we have to do
this to identify the Include ... sentences in them, and thus detect extension
dependencies, and (b) the syntax tree is only a rudimentary one at this stage,
parsing only a few "structural sentences".

@ The definition of "structural sentence" is given in the form of Preform grammar
in //Source Text//. (Preform is the natural-language parsing engine provided
by the //words// module, and which the InC dialect of C provides a simple way
to type into code.)

For reasons which will become clear shortly, the sentences we care most about
are extension inclusions and headings. Headings are sentences such as:

>> Chapter the First - The Voyage

These are detected for us by the sentence-breaker in //syntax//, which
calls out to our function //Headings::new// when it finds one. Each is
given a //heading// object. We will do three things with headings:
(1) Form them into a tree structure, to be able to determine quickly
which is a subheading of which;
(2) Parse their bracketed caveats, such as "for use with ... only",
which we will soon need -- this is done by another Preform grammar; and
(3) Move content around to satisfy annotations such as "in place of...",
though this stage is performed only later -- see below.

@ What happens next involves is carefully timed. What we want is to look
through for sentences like this one:

>> Include Holy Bat Artefacts by Bruce Wayne.

...so that we can see what extensions the project/extension we are reading
will further need. And this is performed by the //Inclusions::traverse//
function, which crawls over the syntax tree looking for such. However, if
an extension inclusion occurs under a heading in the source text like this one:

>> Chapter 9 - External Files (not for Z-machine)

and the current virtual machine doesn't meet stipulation, then we must ignore
the inclusion and there's no dependency; and similarly:

>> Section 1 - Figures (for figures language element only)

Because of this, we make sure to call //Projects::activate_elements// before
looking for inclusion sentences, in order to know whether or not, e.g., the
figures language element is present.

Worst of all is the case of an extension inclusion coming underneath a
heading like this:

>> Section 15 - Bolts (for use with Locksmith by Emily Short)

We can only base the decision on whether we have so far included Locksmith.
Otherwise, it would be easy to set up flip-flop like paradoxes where if X
is not present, Y is present, and vice versa, leaving it a matter of chance
which of those states actually happens.

@ At any rate, when //Inclusions::traverse// finds an Include sentence which
it decides is valid, it calls //Inclusions::fulfill_request_to_include_extension//.
This performs a search for the best compatible copy of the extension named --
see above -- and, once such a copy is found, calls //Inclusions::load// to
merge its text into the current syntax tree. (Note: it doesn't form an
isolated syntax tree of its own.) This is why Inform reads the text of an
extension as if it appeared at the same position as the Include sentence.

When a valid Include is found, //Inclusions::fulfill_request_to_include_extension//
also puts a dependency edge in between the vertex for our copy and the vertex
for the new extension's copy. That will be a use edge if our copy is also an
extension -- i.e., you can't use Existing Extension unless you also have
New Extension -- but a build edge if our copy is a project -- i.e., you can't
build Existing Project unless you also have New Extension.

By the end of the process, therefore, all dependencies on or between extensions
will have been added to the build graph.

@ Finally comes the complicated business of rearranging the syntax tree due
to headings like:

>> Chapter 7a (in place of Chapter 7 in Applied Pathology by Attila Hun)

This is performed by //Headings::satisfy_individual_heading_dependency//,
and it has to be done after all the extension inclusions have been made. It's
a step only performed for the syntax tree of a whole project: if we've just
made an isolated tree for a single extension, we don't bother, because we
couldn't compile that in isolation anyway.

@ This is all quite a long road, and the way is strewn with potential errors.
What if a requested extension can't be found? Or is damaged? Or not compatible
with our VM? Or if a heading is "in place of" one which isn't where it claimed?
And so on. Such issues are converted into still more copy errors.

If //supervisor// is running in the parent //inbuild//, then all errors are
all issued to the console when text reading is complete. But if it is running
in the parent //inform7//, they are suppressed for now, and will be picked
up later and issued as problem messages by //core: Problems With Source Text//.

@ Now that we have read in the text of a project/extension, we know all of its
dependencies on other extensions. If we were reading an extension, we now have
its complete graph made, because it can only be dependent on other extensions.
But a project also depends on kits of Inter codes, on a language definition,
and so forth: and also on the files it draws its source text from. See
//Projects::construct_graph// for the details.

@h Incremental builds.
So, then, at this point we can determine the complete build graph for any copy.
The parent can do several things:

(a) Call //Copies::show_graph//, or //Copies::show_needs//, or //Copies::show_missing//,
to print out the graph, show what a project needs in order to be built, or
show what it needs but doesn't currently have;
(b) Call //Copies::archive// to make archived copies of all dependent resources;
(c) Or, the big one, call //Copies::build// or //Copies::rebuild// to perform
a build.

A "build" is incremental, and uses time-stamps of files to avoid unnecessary
duplication of previous compilation work; a "rebuild" is not. They are otherwise
the same, both calling //IncrementalBuild::build//. This works rather like the
traditional Unix tool |make|: if it wants to build the resource which a vertex
represents, it first has to build the resources which that vertex depends on,
i.e., has edges out to.

How does one "build a vertex", though? The answer is that if a vertex has been
given a //build_script//, one follows this script. The script is only a list
of //build_step// objects, and each step is an application of a //build_skill//.
There are only a few skills known to the Supervisor, created by //Supervisor::start//.
For example, assimilating a kit is a skill; but the need to apply this skill to
a particular copy of |WorldModelKit| is a build step.

Some build steps can be carried out in two different ways: externally, by
issuing a command to the shell; or internally, by calling a function in some
module also present in the parent tool. The Supervisor chooses which way
according to the //build_methodology// object passed to //IncrementalBuild::build//
to configure how it should go about its business.

@h Extension census.
That's basically everything except for a few special features to provide
the Inform GUI apps with nice-looking documentation pages on installed
extensions. These are constructed by a "census", when the parent calls
//Extensions::Census::new//. Copies for extensions are annotated with
metadata on, for example, when they were last used, and such metadata is stored
between runs in the //Extension Dictionary//, and used as part of the
//Extension Documentation// generated for the benefit of the Inform user
interface apps.
