Title: assertions
Author: Graham Nelson
Purpose: Dealing with top-level declarations in Inform source text.
Language: InC
Licence: Artistic License 2.0

Preliminaries
	What This Module Does

Chapter 1: Configuration and Control
	Assertions Module

Chapter 2: Top-Level Declarations
"Passing three times through top-level declarations and assertion sentences."
	Booting Verbs
	Passes through Major Nodes
	Anaphoric References
	Classifying Sentences

Chapter 3: Requests
"Sentences, often imperative, which have special meanings."
	Debugging Log Requests
	Pluralisation Requests
	Translation Requests
	New Use Option Requests
	Use Option Requests
	Test Requests
	Define by Table Requests
	Rule Placement Requests
	New Activity Requests
	New Literal Pattern Requests
	New Relation Requests
	New Property Requests
	New Verb Requests
	New Adjective Requests

Chapter 4: Assertions
"Turning regular assertion sentences into propositions about the model world."
	Refine Parse Tree
	The Creator
	Assertions
	New Property Assertions
	Property Knowledge
	Relation Knowledge
	Assemblies
	Implications
	Tree Conversions

Chapter 5: Verbs
"Verbs which establish relationships between nouns, and which give meaning
to binary predicates."
	The Equality Relation Revisited
	Quasinumeric Relations
	Adjective Meanings
	Relations
	Explicit Relations
	The Universal Relation
	Verbs at Run Time

Chapter 6: Sentences
"In which the stream of words is broken up into sentences and built into a
parse tree, recording primary verbs, noun phrases and some sub-clauses; and in
which these sentences are collected under a hierarchy of headings, with
material intended only for certain target virtual machines included or
excluded as need be."
	Parse Tree Usage
	Headings
	Rule Subtrees

Chapter 7: Table Data
"Inform's preferred data structure for small initialised databases."
	Table Columns
	Tables
	Runtime Support for Tables
	Listed-In Relations
