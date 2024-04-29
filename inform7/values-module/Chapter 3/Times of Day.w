[TimesOfDay::] Times of Day.

To make a built-in kind of value for times of day, such as "11:22 AM".

@ "Men can do nothing without the make-believe of a beginning. Even Science,
the strict measurer, is obliged to start with a make-believe unit, and must fix
on a point in the stars' unceasing journey when his sidereal clock shall pretend
that time is at Nought. His less accurate grandmother Poetry has always been
understood to start in the middle; but on reflection it appears that her
proceeding is not very different from his; since Science, too, reckons backwards
as well as forwards, divides his unit into billions, and with his clock-finger
at Nought really sets off in medias res" (George Eliot, "Daniel Deronda").

Our make-believe here is midnight, our unit is divided not into billions but
into 1440, and a value of this kind holds one of two possibilities:

(i) an absolute time, measured as the number of minutes since midnight;
(ii) a relative time, measured in minutes.

Thus the value 70 might mean 1:10 AM, or it might mean 70 minutes, and
type-checking does not try to distinguish the two. This is so that arithmetic
will be easier -- we can add 70 minutes to 1:10 AM to get 2:20 AM, but if they
had different kinds, this would be illegal.[1]

[1] The down side is that it allows adding, say, 4:52 PM to 3:31 PM, which
Inform does by considering each as time since the previous midnight, but makes
little sense. We also need two different notations for time -- compare the
command parser tokens "[a time]", recognising, say, "4:12 AM" and "[a
time period]", for "3 HOURS".

@ This section of code is a feature: that is, it can be deactivated, removing
support for times of day from the Inform language. If so, |K_time| remains null.

= (early code)
kind *K_time = NULL;
kind *K_time_period = NULL;

@ The plugin intervenes only to notice the "time" and "duration" kinds when they
appear.

=
void TimesOfDay::start(void) {
	PluginCalls::plug(NEW_BASE_KIND_NOTIFY_PLUG, TimesOfDay::times_new_base_kind_notify);
}

int TimesOfDay::times_new_base_kind_notify(kind *new_base, text_stream *name, wording W) {
	if (Str::eq_wide_string(name, U"TIME_TY")) {
		K_time = new_base; return TRUE;
	}
	if (Str::eq_wide_string(name, U"TIME_PERIOD_TY")) {
		K_time_period = new_base; return TRUE;
	}
	return FALSE;
}

kind *TimesOfDay::kind(void) {
	return K_time;
}

kind *TimesOfDay::time_period(void) {
	return K_time_period;
}

parse_node *TimesOfDay::elapsed_time_rvalue(int N, wording W) {
	if (K_time_period) return Rvalues::from_time_period(N, W);
	else return Rvalues::from_time(N, W);
}

@h Parsing.
Although they are eventually stored in variables of the same kind ("time"),
relative and absolute times are parsed differently -- they really are not
linguistically the same thing at all.

=
<s-literal-time> ::=
	minus <elapsed-time> |  ==> { -, TimesOfDay::elapsed_time_rvalue(-R[1], W) }
	<elapsed-time> |        ==> { -, TimesOfDay::elapsed_time_rvalue(R[1], W) }
	<clock-time>            ==> { -, Rvalues::from_time(R[1], W) }

<elapsed-time> ::=
	<cardinal-number> hour/hours |                                 ==> { 60*R[1], - }
	<cardinal-number> minute/minutes |                             ==> { pass 1 }
	<cardinal-number> hour/hours <cardinal-number> minute/minutes  ==> { 60*R[1]+R[2], - }

<clock-time> ::=
	<cardinal-number> <am-pm> |    ==> @<Vet the time for clock range@>
	<digital-clock-time> <am-pm>   ==> @<Vet the time for clock range@>

<am-pm> ::=
	am |
	pm

@ Note that we allow "12:01 AM" (one minute past midnight) and "12:01 PM"
(ditto noon), and also "0:01 AM" and "00:01 AM", but not "0:01 PM".
Lawrence Sanders's sci-fi thriller "The Tomorrow File", if that can be
mentioned on the same page as "Daniel Deronda", had a terrific cover of
a digital clock glowing with "24:01" -- but we won't allow that, either.

@<Vet the time for clock range@> =
	int time_cycles = 12*60*R[2];
	int t = R[1], time_hours, time_minutes;
	if (R[0] == 0) { time_hours = t; time_minutes = 0; }
	else { time_hours = t/60; time_minutes = t%60; }
	if ((time_hours == 0) && (time_cycles > 0)) return FALSE; /* reject for example "0:01 PM" */
	if (time_hours == 12) time_hours = 0; /* allow for example "12:01 AM" */
	==> { time_minutes + 60*time_hours + time_cycles, - };

@ These are times of day written in the style of a digital clock: "00:00",
"5:21", "17:21". The syntax must be one or two digits, followed by a
colon, followed by exactly two digits; it is permissible for the first of
two digits to be zero; when that is discarded, the hours part must be in
the range 0 to 23, and the minutes part in the range 0 to 59.

=
<digital-clock-time> internal 1 {
	int time_minutes = 0, time_hours = 0;
	int ratchet = 0, t, colons = 0, digits = 0;
	inchar32_t *wd = Lexer::word_text(Wordings::first_wn(W));
	for (t=0; wd[t]; t++) {
		if (((t==1) || (t==2)) && (wd[t] == ':') && (wd[t+1])) {
			if (ratchet >= 24) { ==> { fail nonterminal }; }
			time_hours = ratchet;
			ratchet = 0; digits = 0;
			colons++;
		} else if (Characters::isdigit(wd[t])) {
			ratchet = 10*ratchet + (int) (wd[t]-'0'); digits++;
			if ((ratchet >= 60) || (digits > 2)) { ==> { fail nonterminal }; }
		} else { ==> { fail nonterminal }; }
	}
	if (colons != 1) { ==> { fail nonterminal }; }
	time_minutes = ratchet;
	if ((time_hours < 0) || (time_hours > 12)) { ==> { fail nonterminal }; }
	if ((time_minutes < 0) || (time_minutes >= 60)) { ==> { fail nonterminal }; }
	==> { time_minutes + time_hours*60, - };
	return TRUE;
}

@ And these are the Continental equivalent, with an "h" instead of
the colon: thus "16h15" for quarter past four in the afternoon. (The
standard English grammar doesn't use this, but translators might want to.)

=
<continental-clock-time> internal 1 {
	int time_minutes = 0, time_hours = 0;
	int ratchet = 0, t, colons = 0, digits = 0;
	inchar32_t *wd = Lexer::word_text(Wordings::first_wn(W));
	for (t=0; wd[t]; t++) {
		if (((t==1) || (t==2)) && (wd[t] == 'h') && (wd[t+1])) {
			if (ratchet >= 24) { ==> { fail nonterminal }; }
			time_hours = ratchet;
			ratchet = 0; digits = 0;
			colons++;
		} else if (Characters::isdigit(wd[t])) {
			ratchet = 10*ratchet + (int) (wd[t]-'0'); digits++;
			if ((ratchet >= 60) || (digits > 2)) { ==> { fail nonterminal }; }
		} else { ==> { fail nonterminal }; }
	}
	if (colons != 1) { ==> { fail nonterminal }; }
	time_minutes = ratchet;
	if ((time_hours < 0) || (time_hours > 12)) { ==> { fail nonterminal }; }
	if ((time_minutes < 0) || (time_minutes >= 60)) { ==> { fail nonterminal }; }
	==> { time_minutes + time_hours*60, - };
	return TRUE;
}
