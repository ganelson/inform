P/legal: Licence and Copyright Declaration.

A verbatim copy of the Artistic License 2.0, which governs the
use and distribution of Inform 7 materials.

@h Declaration of copyright.
The Inform 6 compiler and its associated library are copyright (c) Graham
Nelson 1993-2007. The following materials associated with the Inform 7
project are copyright (c) Graham Nelson 2003-2007: the source code to the
NI compiler; the I6T template files; the "natural" version of the I6 library;
the icons, images and other non-executable resources supplied for use
within Inform user interfaces; the Inform 7 documentation and website,
including the Examples; the Inform Tools Suite; and the test cases used for
regression-testing with |intest|, their associated material and ideal
results. The {\it Inform [6] Designer's Manual, Fourth Edition} (DM4) is
copyright (c) Graham Nelson 2001. We will call this whole body of
intellectual property, with the exception of the typeset and printed form
of the DM4, "the Package".

GN is the primary author of the Package, but not the only one: indeed the
examples were very largely written by Emily Short, and others have also
made modest contributions. However, GN holds the copyright to all of it so
that there is a single point of reference for licencing of Inform.

Note that this does {\it not} include the officially recognised Inform user
interface applications: the authors of these programs retain their own
copyrights and are responsible for their own licencing. (It is a condition
to be officially recognised by the Inform project that some form of free
licence be used: in practice, most have chosen the GPL version 2.)

@h The former Inform licence, 1993-2007.
The Package was previously governed by a short, largely free but in some
ways restrictive licence. (The text of this was published in the DM4, which
is freely browsable online.)

The new licence is both more explicit and more liberal. The change was made
for cultural reasons: over those years the Internet became a highly
litigious domain, where even those who espouse freedoms are obsessed with
the terms of licenses. Some users are now frightened off by any retention
of rights by the author of software, worrying that the rug might be pulled
at any moment. Some institutions enforce their ideological position by
refusing to distribute software under a licence which they deem impure: for
instance, under the old licence Inform could not be aggregated with Debian
Linux, even though it had been completely free and open for 15 years. Also,
there are some possible complications about the way NI and other components
combine with GPL-licensed software for the user interfaces, and I feel
reluctantly compelled to finally include a disclaimer of warranty, some
degree of anti-patent-troll protection, and so forth -- something I dislike
doing since it implicitly acknowledges some validity in such distasteful
legal claims.

There are two practical differences between the old and new licences. First,
the new licence removes the requirement that any work of IF compiled by Inform
should name "Inform" in its banner text. Authors are now legally free to
suppress the banner text altogether, though I hope they won't: it's only a
small gesture of respect to all those who have worked on Inform, and costs
nothing. Second, the old licence forbade (at any rate did not permit) the
making of a modified version of Inform, whereas the new licence largely permits
this (see below).

@h The current licence, 2008-.
As from the first publication on the Inform website of the source code to
Inform 7, in 2008:

(a) The Package is hereby placed under the Artistic License 2.0.
(b) For the avoidance of doubt, the Author additionally grants the right
for all users of the Package to make unlimited use of story files produced
by the Package.

To clarify (b): the structure of Inform means that it copies large pieces
of the I6 library and the I6T template files almost verbatim into the I6
source code used to make a story file. Someone might then worry that any
resulting story file is therefore a derivative work of the Package itself,
and so inherits the Artistic License 2.0. The Author wishes to clarify that
this is not the case, and that {\it people using Inform to make a story
file can sell, distribute, modify or otherwise use it exactly as they
please, and under any licence(s) they choose}. (The same issue arises with
the Free Software Foundation's |bison|, and they solve it in the same way,
by making an additional grant of rights on top of the licence for |bison|
itself.)

@ The Artistic License 2.0, used by Perl among other notable projects, is
widely considered to be one offering generous permissions for the user, and
was chosen because:

(a) it is recognised by the Open Source Initiative as an open source licence;
(b) it is recognised by the Free Software Foundation as a guarantee that the
software is free not only in the economic way, but also in a more libertarian
sense;
(c) by freely allowing modifications and derivative works, but requiring any
such to be issued under different names, it allows the authors to retain
the moral right of authorship: the ability to decide what is, and is not,
the Inform design.

The licence is the sole legal document governing these matters, of course,
but our interpretation of clause (9) is that, in particular, it is legal to
distribute an aggregation of the Package along with any of the recognised
user interface application(s) and also with Extensions by third parties
which are subject to the Creative Commons Attribution licence (such as
those published on the Inform website), and to call the result "Inform".

The verbatim text of the licence now follows. It is copyrighted by the Perl
Foundation, 2006, whose work in creating it we acknowledge with thanks.
(The boldface section numbers in the typeset form of this preface are just
typography, and not a part of the licence: but the clause numbers, "(10)"
and so forth, are. The American spelling "license" is used, since that's
how the Foundation wrote it.)

@h Preamble.
This license establishes the terms under which a given free software
Package may be copied, modified, distributed, and/or redistributed. The
intent is that the Copyright Holder maintains some artistic control over
the development of that Package while still keeping the Package available
as open source and free software.

You are always permitted to make arrangements wholly outside of this
license directly with the Copyright Holder of a given Package. If the terms
of this license do not permit the full use that you propose to make of the
Package, you should contact the Copyright Holder and seek a different
licensing arrangement.

@h Definitions.
{\it Copyright Holder} means the individual(s) or organization(s) named in
the copyright notice for the entire Package. {\it Contributor} means any
party that has contributed code or other material to the Package, in
accordance with the Copyright Holder's procedures. {\it You} and {\it your}
means any person who would like to copy, distribute, or modify the Package.
{\it Package} means the collection of files distributed by the Copyright
Holder, and derivatives of that collection and/or of those files. A given
Package may consist of either the Standard Version, or a Modified Version.
{\it Distribute} means providing a copy of the Package or making it
accessible to anyone else, or in the case of a company or organization, to
others outside of your company or organization. {\it Distributor Fee} means
any fee that you charge for Distributing this Package or providing support
for this Package to another party. It does not mean licensing fees. {\it
Standard Version} refers to the Package if it has not been modified, or has
been modified only in ways explicitly requested by the Copyright Holder.
{\it Modified Version} means the Package, if it has been changed, and such
changes were not explicitly requested by the Copyright Holder. {\it
Original License} means this Artistic License as Distributed with the
Standard Version of the Package, in its current version or as it may be
modified by The Perl Foundation in the future. {\it Source} form means the
source code, documentation source, and configuration files for the Package.
{\it Compiled} form means the compiled bytecode, object code, binary, or
any other form resulting from mechanical transformation or translation of
the Source form.

@h Permission for Use and Modification Without Distribution.

(1) You are permitted to use the Standard Version and create and use
Modified Versions for any purpose without restriction, provided that you do
not Distribute the Modified Version.

@h Permissions for Redistribution of the Standard Version.

(2) You may Distribute verbatim copies of the Source form of the Standard
Version of this Package in any medium without restriction, either gratis or
for a Distributor Fee, provided that you duplicate all of the original
copyright notices and associated disclaimers. At your discretion, such
verbatim copies may or may not include a Compiled form of the Package.

(3) You may apply any bug fixes, portability changes, and other
modifications made available from the Copyright Holder. The resulting
Package will still be considered the Standard Version, and as such will be
subject to the Original License.

@h Distribution of Modified Versions of the Package as Source.

(4) You may Distribute your Modified Version as Source (either gratis or
for a Distributor Fee, and with or without a Compiled form of the Modified
Version) provided that you clearly document how it differs from the
Standard Version, including, but not limited to, documenting any
non-standard features, executables, or modules, and provided that you do at
least ONE of the following:

(a) make the Modified Version available to the Copyright Holder of the
Standard Version, under the Original License, so that the Copyright Holder
may include your modifications in the Standard Version.

(b) ensure that installation of your Modified Version does not prevent the
user installing or running the Standard Version. In addition, the Modified
Version must bear a name that is different from the name of the Standard
Version.

(c) allow anyone who receives a copy of the Modified Version to make the
Source form of the Modified Version available to others under

(i) the Original License or

(ii) a license that permits the licensee to freely copy, modify and
redistribute the Modified Version using the same licensing terms that apply
to the copy that the licensee received, and requires that the Source form
of the Modified Version, and of any works derived from it, be made freely
available in that license fees are prohibited but Distributor Fees are
allowed.

@h Distribution of Compiled Forms of the Standard Version or Modified Versions without the Source.

(5) You may Distribute Compiled forms of the Standard Version without the
Source, provided that you include complete instructions on how to get the
Source of the Standard Version. Such instructions must be valid at the time
of your distribution. If these instructions, at any time while you are
carrying out such distribution, become invalid, you must provide new
instructions on demand or cease further distribution. If you provide valid
instructions or cease distribution within thirty days after you become
aware that the instructions are invalid, then you do not forfeit any of
your rights under this license.

(6) You may Distribute a Modified Version in Compiled form without the
Source, provided that you comply with Section 4 with respect to the Source
of the Modified Version.

@h Aggregating or Linking the Package.

(7) You may aggregate the Package (either the Standard Version or Modified
Version) with other packages and Distribute the resulting aggregation
provided that you do not charge a licensing fee for the Package.
Distributor Fees are permitted, and licensing fees for other components in
the aggregation are permitted. The terms of this license apply to the use
and Distribution of the Standard or Modified Versions as included in the
aggregation.

(8) You are permitted to link Modified and Standard Versions with other
works, to embed the Package in a larger work of your own, or to build
stand-alone binary or bytecode versions of applications that include the
Package, and Distribute the result without restriction, provided the result
does not expose a direct interface to the Package.

@h Items That are Not Considered Part of a Modified Version.

(9) Works (including, but not limited to, modules and scripts) that merely
extend or make use of the Package, do not, by themselves, cause the Package
to be a Modified Version. In addition, such works are not considered parts
of the Package itself, and are not subject to the terms of this license.

@h General Provisions.

(10) Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify, or
distribute the Package, if you do not accept this license.

(11) If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

(12) This license does not grant you the right to use any trademark,
service mark, tradename, or logo of the Copyright Holder.

(13) This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims licensable
by the Copyright Holder that are necessarily infringed by the Package. If
you institute patent litigation (including a cross-claim or counterclaim)
against any party alleging that the Package constitutes direct or
contributory patent infringement, then this Artistic License to you shall
terminate on the date that such litigation is filed.

(14) Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT
HOLDER AND CONTRIBUTORS "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT
PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@ That final burst of shouting concludes the verbatim text of the
Artistic License 2.0, and we can now return to your scheduled program.
