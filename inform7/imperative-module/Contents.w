Title: imperative
Author: Graham Nelson
Purpose: Compiling imperative code inside phrase or rule definitions.
Language: InC
Licence: Artistic License 2.0

Preliminaries
	What This Module Does

Chapter 1: Configuration and Control
	Imperative Module

Chapter 2: Compiling from Propositions
	Compiling from Specifications
	Compile Atoms
	Deciding to Defer
	Cinders and Deferrals
	Compile Deferred Propositions

Chapter 3: Phrases
"In which rules, To... phrases (and similar explicit instructions to do
with specific changes in the world) have their preambles parsed and their
premisses worked out, and are then collected together into rulebooks, before
being compiled as a great mass of Inform 6 routines and arrays."
	Introduction to Phrases
	Construction Sequence
	Phrases
	Phrase Usage
	Phrase Runtime Context Data
	Phrase Type Data
	Describing Phrase Type Data
	Phrase Options
	Phrases as Values
	To Phrases
	Timed Phrases
	Phrasebook Index

Chapter 4: Compilation Context
"Preparing a context at run-time in which code can be executed: creating
local variables, and so on."
	Local Variables
	Phrase Blocks
	Stack Frames
	Chronology

Chapter 5: Compilation
"Generating code to perform individual phrases."
	Invocations
	Parse Invocations
	Compile Invocations
	Compile Invocations As Calls
	Compile Invocations Inline
	Compile Phrases
	Compile Arithmetic
