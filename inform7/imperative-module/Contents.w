Title: imperative
Author: Graham Nelson
Purpose: Compiling imperative code inside phrase or rule definitions.
Language: InC
Licence: Artistic License 2.0

Preliminaries
	What This Module Does

Chapter 1: Configuration and Control
	Imperative Module

Chapter 2: Compilation Context
"Preparing a context at run-time in which code can be executed."
	Stack Frames
	Local Variable Slates
	Local Variables
	Local Parking
	Phrase Blocks
	Functions

Chapter 3: Compiling Propositions
"Generating code to test or assert propositions from predicate calculus."
	Compiling from Specifications
	Emitting from Schemas
	Compile Atoms
	Deciding to Defer
	Cinders and Deferrals
	Compile Deferred Propositions

Chapter 4: Compiling Invocations
"Generating code to perform individual phrases."
	Invocations
	Parse Invocations
	Compile Invocations
	Compile Invocations As Calls
	Compile Invocations Inline
	Compile Phrases
	Compile Arithmetic
	Compile Solutions to Equations
