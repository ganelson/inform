Version 2 of Metric Units (for Glulx only) by Graham Nelson begins here.

"Scientific kinds of value for simulations."

Use authorial modesty.

Part I - SI Base Units

Length is a kind of value.

The specification of length is "Used to measure heights, widths, distances,
thicknesses and so on."

1.0m (in metric units, in m) or 1 meter (in meters, singular) or 1 metre
(in metres, singular) or 2 meters (in meters, plural) or 2 metres (in
metres, plural) specifies a length.

1mm (in metric units, in mm) or 1 millimeter (in millimeters,
singular) or 1 millimetre (in millimetres, singular) or 2 millimeters
(in millimeters, plural) or 2 millimetres (in millimetres, plural)
specifies a length scaled down by 1000.

1cm (in metric units, in cm) or 1 centimeter (in centimeters,
singular) or 1 centimetre (in centimetres, singular) or 2 centimeters
(in centimeters, plural) or 2 centimetres (in centimetres, plural)
specifies a length scaled down by 100.

1km (in metric units, in km) or 1 kilometer (in kilometers, singular)
or 1 kilometre (in kilometres, singular) or 2 kilometers (in
kilometers, plural) or 2 kilometres (in kilometres, plural) specifies
a length scaled up by 1000.

Mass is a kind of value.

The specification of mass is "Used to measure how much of something is
present. Start fights with other nerds by deliberately mixing this up with
weight, which comes to the same thing for everyday purposes at ground level."

1.0kg (in metric units, in kg) or 1 kilogram (in kilograms, singular) or
2 kilograms (in kilograms, plural) specifies a mass.

1g (in metric units, in g) or 1 gram (in grams, singular) or 2 grams
(in grams, plural) specifies a mass scaled down by 1000.

1 tonne (in metric units, in tonnes, singular) or 2 tonnes (in metric units,
in tonnes, plural) specifies a mass scaled up by 1000.

Elapsed time is a kind of value.

The specification of elapsed time is "Used to measure how much time
something takes. Inform already has a built-in kind of value called
'time', which counts in minutes and keeps track of the time of day -
which is fine for most stories, but not good enough for science. So we
call this more precise version 'elapsed time'."

1.0s (in metric units, in s) or 1 second (in seconds, singular) or 2 seconds
(in seconds, plural) specifies an elapsed time.

1 min (in metric units, in min) specifies an elapsed time scaled up by 60.

1 hr (in metric units, in hr) specifies an elapsed time scaled up by 3600.

1 day (in metric units, in days, singular) or 2 days (in metric units,
in days, plural) specifies an elapsed time scaled up by 86400.

1 week (in metric units, in weeks, singular) or 2 weeks (in metric units,
in weeks, plural) specifies an elapsed time scaled up by 604800.

Electric current is a kind of value.

The specification of electric current is "Used to measure the amount of
electricity flowing through something at any given moment."

1.0A (in metric units, in A) or 1 amp (in amps, singular) or 2 amps
(in amps, plural) specifies an electric current.

1mA (in metric units, in mA) or 1 milliamp (in milliamps, singular) or
2 milliamps (in milliamps, plural) specifies an electric current scaled
down by 1000.

Temperature is a kind of value.

The specification of temperature is "Used to measure how hot or cold
something is. (Note that Inform writes '1 C' for one coulomb, and '1C' for
one degree centigrade.)"

1.0C (in metric units, in C) or 1 degree centigrade (in degrees centigrade,
singular) or 2 degrees centigrade (in degrees centigrade, plural) or 1 degree
Celsius (in degrees Celsius, singular) or 2 degrees Celsius (in degrees
Celsius, plural) specifies a temperature.

Luminosity is a kind of value.

The specification of luminosity is "Used to measure the total amount of
light. (This is not quite the same thing as brightness - that's the amount
of light produced per unit of area, and is called luminance.) Candela is a
term adopted in 1948 to replace the old 'candlepower', but 1 cd remains
about the light of a single candle. A strong light-bulb produces about 100
cd; a very small indicator LED about 0.001 cd; and the old Blackpool
Illuminations were about 20000 cd."

1.0 cd (in metric units, in cd) or 1 candela (in candelas, singular) or
2 candelas (in candelas, plural) specifies a luminosity.

[There is also the mole, an amount of substance, as used in chemistry.]


Part II - SI Derived Units

Frequency is a kind of value. 

The specification of frequency is "Used to measure how often a series of events
takes place, with 1 Hertz meaning once per second. 1 mHz is about the frequency
of a bus arriving at an urban stop in daytime; human eyes can't detect
flickering faster than around 100 Hz, which is why high-end television sets
refresh at about that rate."

1.0 Hz (in metric units, in Hz) or 1 Hertz (in Hertz) specifies
a frequency.

1 mHz (in metric units, in mHz) or 1 millihertz (in millihertz)
specifies a frequency scaled down by 1000.

1 kHz (in metric units, in kHz) or 1 kilohertz (in kilohertz)
specifies a frequency scaled up by 1000.

Elapsed time times frequency specifies a number.

Force is a kind of value.

The specification of force is "Used to measure how much push or pull is
needed to make something move (properly speaking, accelerate). 1N is about
the force of Earth's gravity acting on a typical apple. 0.001N is a tug
which would barely move a pebble. A climber's rope will typically break
under a force of about 20kN, or half that if it's knotted. (Stylishly if
bizarrely, some people call the kilonewton the 'sthène', but Inform
doesn't.) 2000kN is roughly the thrust of one of the Space Shuttle Main
Engines, which is about the most violent controlled machine ever built."

1.0N (in metric units, in N) or 1 Newton (in Newtons, singular) or 2 Newtons
(in Newtons, plural) specifies a force.

1kN (in metric units, in kN) or 1 kilonewton (in kilonewtons, singular) or
2 kilonewtons (in kilonewtons, plural) specifies a force scaled up by 1000.

Energy is a kind of value.

The specification of energy is "Used to measure how much ability something
has to do work. Human beings give off about 100J in body heat every second
just sitting still. 2000kJ is twice the food energy stored in a Mars bar,
or enough to run a typical electric radiant heater for an hour."

1.0J (in metric units, in J) or 1 Joule (in Joules, singular) or 2 Joules
(in Joules, plural) specifies an energy.

1mJ (in metric units, in mJ) or 1 millijoule (in millijoules, singular) or
2 millijoules (in millijoules, plural) specifies an energy scaled down by 1000.

1kJ (in metric units, in kJ) or 1 kilojoule (in kilojoules, singular) or
2 kilojoules (in kilojoules, plural) specifies an energy scaled up by 1000.

Force times length specifies an energy.

Pressure is a kind of value.

The specification of pressure is "Used to measure how much force is being
applied per unit of area, sometimes by one object pulled against another,
sometimes by gas or water pressing in on things inside it. 1Pa is the tiny
pressure which a bank note applies to a table it's sitting on top of;
20000MPa can compress carbon into diamonds. Atmospheric pressure at sea level
is about 100kPa; water pressure at the bottom of the Mariana Trench a
thousand times greater, at about 100MPa."

1.0Pa (in metric units, in Pa) or 1 Pascal (in Pascals, singular) or 2 Pascals
(in Pascals, plural) specifies a pressure.

1kPa (in metric units, in kPa) or 1 kilopascal (in kilopascals, singular) or
2 kilopascals (in kilopascals, plural) specifies a pressure scaled up by 1000.

1MPa (in metric units, in MPa) or 1 megapascal (in megapascals, singular) or
2 megapascals (in megapascals, plural) specifies a pressure scaled up by
1000000.

Power is a kind of value.

The specification of power is "Used to measure how much energy something can
apply in a given time - in the same period of time powerful things can do a lot
while feeble things much less. Typical domestic light bulbs take 60W of power
to run (twice as much as the human brain), and electric heaters perhaps 3kW."

1.0W (in metric units, in W) or 1 Watt (in Watts, singular) or 2 Watts
(in Watts, plural) specifies a power.

1mW (in metric units, in mW) or 1 milliwatt (in milliwatts, singular) or
2 milliwatts (in milliwatts, plural) specifies a power scaled down by 1000.

1kW (in metric units, in kW) or 1 kilowatt (in kilowatts, singular) or
2 kilowatts (in kilowatts, plural) specifies a power scaled up by 1000.

Elapsed time times power specifies an energy.

Electric charge is a kind of value.

The specification of electric charge is "Electricity works because,
although matter is usually 'neutral', electric charge can flow between one
thing and another so that this balance is broken, and then a force is felt
between them. Electric forces are very strong, so even a small charge has a
big effect - a storm cloud might only have a charge of 20 C, but that's
enough to cause thunder and lightning. On the other hand batteries store
very large charges, but of course release them much more slowly - a typical
car battery holds about 200 kC. (Note that Inform writes '1 C' for one
coulomb, and '1C' for one degree centigrade.)"

1.0 C (in metric units, in C) or 1 Coulomb (in Coulombs, singular) or
2 Coulombs (in Coulombs, plural) specifies an electric charge.

1 kC (in metric units, in kC) or 1 kilocoulomb (in kilocoulombs, singular)
or 2 kilocoulombs (in kilocoulombs, plural) specifies an electric charge
scaled up by 1000.

Elapsed time times electric current specifies an electric charge.

Voltage is a kind of value.

The specification of voltage is "Measures the 'potential difference' between
two points, a sort of pulling power for electricity. Quite low voltages can be
dangerous on human skin - a 50V potential difference between two points on the
body can cause enough charge to flow to electrocute somebody."

1.0V (in metric units, in V) or 1 volt (in volts, singular) or 2 volts
(in volts, plural) specifies a voltage.

1mV (in metric units, in mV) or 1 millivolt (in millivolts, singular) or
2 millivolts (in millivolts, plural) specifies a voltage scaled down by 1000.

1kV (in metric units, in kV) or 1 kilovolt (in kilovolts, singular) or
2 kilovolts (in kilovolts, plural) specifies a voltage scaled up by 1000.

Voltage times electric current specifies a power. Voltage times electric
charge specifies energy.

Luminance is a kind of value.

The specification of luminance is "Used to measure the brightness of something:
how much light it produces per unit of its surface area. (The actual amount
of light produced is luminosity. A fully lit computer display of 2008 has a
brightness of about 330 cd/sq m, and has a surface area of maybe 0.5 sq m,
so pours out about 150 cd. This is more than a domestic light bulb
produces, but the bulb is much, much brighter - maybe 150000 cd/sq m -
because the light comes out of a smaller area.) A luminance of 0.001 cd/sq m
is so dim it can barely be seen, whereas 2000000 cd/sq m would be painful
to look at."

1.0 cd/sq m (in metric units, in cd/sq m) or 1 candela per square meter (in
candelas per square meter, singular) or 2 candelas per square meter
(in candelas per square meter, plural) specifies a luminance.

[I'm leaving out capacitance, resistance, conductance, magnetic flux, magnetic
field, and inductance for now, but they could easily be added.]

[There are also angle, solid angle, luminous flux, and some specialist
measures of radioactive dosage and level of catalysis.]


Part III - SI Compound Units

Area is a kind of value.

1.0 sq m (in metric units, in sq m) or 1 square meter (in square meters,
singular) or 2 square meters (in square meters, plural) or 1 square metre
(in square metres, singular) or 2 square metres (in square metres, plural)
specifies an area.

1.0 sq cm (in metric units, in sq cm) or 1 square centimeter (in square
centimeters, singular) or 2 square centimeters (in square centimeters,
plural) or 1 square centimetre (in square centimetres, singular) or 2
square centimetres (in square centimetres, plural) specifies an area scaled
down by 10000.

1.0 hectare (in metric units, in hectares, singular) or 2 hectares (in metric
units, in hectares, plural) specifies an area scaled up by 10000.

The specification of area is "Measures the extent of a two-dimensional surface,
usually a patch of land or the covering of an object. 1 sq cm is about the
area of a small coin, whereas 20 hectares would be the grounds of a large
country house or a typical French vineyard. A boxing ring is 36 sq m; a sports
field about 6000 sq m."

Length times length specifies an area. Pressure times area specifies
a force. Area times luminance specifies a luminosity.

A Volume is a kind of value. [That "A" prevents Inform mistaking the line for
a volume heading, in the literary sense.]

1.0 cu m (in metric units, in cu m) or 1 cubic meter (in cubic meters,
singular) or 2 cubic meters (in cubic meters, plural) or 1 cubic metre
(in cubic metres, singular) or 2 cubic metres (in cubic metres, plural)
specifies an volume.

1.0 l (in metric units, in l) or 1 liter (in liters, singular) or 2 liters
(in liters, plural) or 1 litre (in litres, singular) or 2 litres (in
litres, plural) specifies a volume scaled down by 1000.

1.0 cc (in metric units, in cc) or 1 cubic centimeter (in cubic centimeters,
singular) or 2 cubic centimeters (in cubic centimeters, plural) or 1 cubic
centimetre (in cubic centimetres, singular) or 2 cubic centimetres (in
cubic centimetres, plural) or 1 ml (in ml) or 1 millilitre (in millilitres,
singular) or 2 millilitres (in millilitres, plural) or 1 milliliter (in
milliliters, singular) or 2 milliliters (in milliliters, plural) specifies
a volume scaled down by 1000000.

The specification of volume is "Measures the extent of a three-dimensional
space, usually the space taken up by an object or the space inside a
container. 1 cc (or 1 ml - same thing) is about a teaspoon-full, whereas
1000 cu m is roughly the capacity of an Olympic swimming pool."

Length times area specifies a volume.

Velocity is a kind of value.

1.0 m/s (in metric units, in m/s) or 1 meter per second (in meters per
second, singular) or 1 metre per second (in metres per second, plural)
specifies a velocity.

1.0 km/s (in metric units, in km/s) or 1 kilometer per second (in kilometers per
second, singular) or 1 kilometre per second (in kilometres per second, plural)
specifies a velocity scaled up by 1000.

The specification of velocity is "Measures how fast something is moving
relative to something else - usually something apparently fixed, like the
ground. 0.01 m/s is the speed of a garden snail; people walk at about 1.2 m/s,
cars drive at about 30 m/s; high speed trains are up to 160 m/s. The speed
of sound is around 330 m/s at sea level on a cool day, and nothing travels
faster than light, at 299792458 m/s."

Velocity times elapsed time specifies a length.

Acceleration is a kind of value.

1.0 m/ss (in metric units, in m/ss) or 1 meter per second squared (in meters
per second squared, singular) or 2 meters per second squared (in meters per
second squared, plural) or 1 metre per second squared (in metres
per second squared, singular) or 2 metres per second squared (in metres per
second squared, plural) specifies an acceleration.

The specification of acceleration is "Measures the rate at which something
is gaining velocity - a positive acceleration makes something speed up,
negative makes it slow down. Accelerations look small, numerically, but have
large effects very quickly in practice - a high-performance Bugatti sports
car accelerates at only about 6 m/ss, but you'd notice all right if it
happened in front of you. Surface gravity on the tiny asteroid of Gaspra
is about 0.002 m/ss; whereas on Earth, gravity accelerates falling objects
at about 9.789 m/ss at the equator, 9.832 m/ss at the poles, so people
usually calculate with an average mid-latitudes value of 9.807 m/ss."

Acceleration times elapsed time specifies a velocity. Mass times
acceleration specifies a force.

Momentum is a kind of value.

1.0 Ns (in metric units, in Ns) or 1 Newton-second (in Newton-seconds) specifies
a momentum.

The specification of momentum is "Momentum is the product of mass and velocity
for a moving object, so it measures in effect how hard it would shove you;
historical physicists had some trouble finding a good word for this concept,
but it's important because of the Principle of Conservation of Momentum -
the total momentum of all the bodies involved in a collision is constant
whatever happens in it. Billiard balls weigh about 150g, and travel at about
0.25 m/s, so each one has a momentum of about 0.038 Ns."

Mass times velocity specifies a momentum.

Density is a kind of value.

1.0 kg/cu m (in metric units, in kg/cu m) or 1 kilogram per cubic meter (in
kilograms per cubic meter, singular) or 2 kilogram per cubic meters (in
kilograms per cubic meter, plural) or 1 kilogram per cubic metre (in
kilograms per cubic meter, singular) or 2 kilograms per cubic metre (in
kilograms per cubic meter, plural) specifies a density.

1 g/cu m (in metric units, in kg/cu m) or 1 gram per cubic meter (in
grams per cubic meter, singular) or 2 gram per cubic meters (in
grams per cubic meter, plural) or 1 gram per cubic metre (in
grams per cubic meter, singular) or 2 grams per cubic metre (in
grams per cubic meter, plural) specifies a density scaled down by 1000.

1 g/cc (in metric units, in g/cc) or 1 gram per cubic centimeter (in
grams per cubic centimeter, singular) or 2 gram per cubic centimeters (in
grams per cubic centimeter, plural) or 1 gram per cubic centimetre (in
grams per cubic centimeter, singular) or 2 grams per cubic centimetre (in
grams per cubic centimeter, plural) specifies a density scaled up by 1000.

The specification of density is "Density is the amount of mass per unit volume.
(When people say that a substance is heavy, they usually mean it has a high
density.) The densest stuff on Earth is osmium metal, at 22610 kg/cu m; the
least dense is hydrogen gas, at 90 g/cu m. All else being equal, objects
whose density is below that of water - 1000 kg/cu m - will float up to the
surface if submerged. (That only includes human beings - 1010 kg/cu m - when
they have air in their lungs, reducing their density.)"

Density times volume specifies a mass.

Heat capacity is a kind of value.

1.0 J/C (in metric units, in J/C) or 1 Joule per degree centigrade (in Joules
per degree centigrade, singular) or 2 Joules per degree centigrade (in Joules
per degree centigrade, plural) specifies a heat capacity.

The specification of heat capacity is "Heat capacity is also known as thermal
mass, and measures how much energy it takes to increase the temperature of
something by one degree. (See specific heat capacity for typical values.)
Entropy is also measured as a heat capacity."

Heat capacity times temperature specifies an energy.

Specific heat capacity is a kind of value.

1.0 J/kg/C (in metric units, in J/kg/C) or 1 Joule per kilogram per degree
centigrade (in Joules per kilogram per degree centigrade, singular) or 2 Joules
per kilogram per degree centigrade (in Joules per kilogram per degree
centigrade, plural) specifies a specific heat capacity.

Specific heat capacity times a mass specifies a heat capacity.

The specification of specific heat capacity is "Whereas heat capacity measures
the energy needed to heat up a specific object - say, a whole house - specific
heat capacity is the energy needed per kilogram of its mass. Thus wood, at
420 J/kg/C, heats up and cools down twice as fast as brick, marble, sand or
soil, all at about 800 J/kg/C; glass is somewhere in between. Liquid water
takes a lot more energy to heat up, at 4180 J/kg/C; but at least this means
that hot baths stay hot for a little while. Butters and oils tend to be in
the range 1500 to 2000 J/kg/C, and most foodstuffs in the 3000s: banana,
3350 J/kg/C; chicken, 3200 J/kg/C; eggs, 3180 J/kg/C and so forth."

[That leaves torque, energy density, and a few other oddities.]

Metric Units ends here.

---- DOCUMENTATION ----

The metric system provides a consistent set of units for scientific measurement of the world. Though often associated with the French Revolution or with Napoleon, the system of metric units only really began to displace existing units in May 1875, when it was made official by an international treaty. In 1960, it was renamed the "Système international d'unités", which is usually abbreviated "SI".

This extension is a kit for writers who want to make realistic simulations, backed up by some quantitative physics. It defines kinds of values for the 25 or so SI units in common usage, and more than 100 notations for them. It also makes sure they multiply correctly. For instance, a mass times an acceleration produces a force, so

	say "You feel a force of [2kg times 5 m/ss]."

will produce the text "You feel a force of 10N." The easiest way to see how all these units combine is to run one of the examples below and look at the Kinds index which results.

For each unit, both names and notations are allowed. Thus '2 kilograms' is
equivalent to '2kg'. Both English and French spellings of 'meter'/'metre' and 'liter'/'litre' are allowed, but we insist on 'gram' not 'gramme' and 'tonne' not 'ton'. ('Ton' is too easily confused with the Imperial measure, which is not quite the same.) We can print back the same value in a variety of ways. For instance:

	say "[m0 in metric units]";
	say "[m0 in kg]";
	say "[m0 in g]";
	say "[m0 in kilograms]";
	
might produce: '2.04kg', '2.04kg', '2040g', '2.04 kilograms'. The text expansion '... in metric units' prints any value of any of these units in its most natural notation: 2.04kg is thought to be better than 2040g, but 981g would be better than 0.981kg. Or in the case of our variant spellings:

	say "[C in metric units]";
	say "[C in milliliters]";
	say "[C in millilitres]";

might produce '47 ml', '47 milliliters', '47 millilitres'. It's also worth remembering that any value can be rounded:

	say "[C to the nearest 5 ml]";

would produce '45 ml', for instance.

For detailed notes on each of the units, consult the Kinds index for any project using this extension.

We haven't included every SI unit. There are hundreds of kinds of value which turn up in physics, and we only include the commonest 25 or so. The missing ones which have named SI units are:

	angle (measured in radians), solid angle (measured in steradians), luminous flux (lux), electric capacitance (Farads), electric resistance (Ohms), electric conductance (Siemens), magnetic flux (Webers), magnetic field (Teslas), inductance (Henries), radioactivity (Becquerels), absorbed radioactive dose (Grays), equivalent radioactive dose (Sieverts), chemical quantity (mole), catalytic activity (katals).

As can be seen, we've missed out units for chemistry, electromagnetic effects beyond the basic ones, and radioactivity. It would be easy to add any of these which might be needed:

	Electric resistance is a kind of value.

	1.0 Ohm (in metric units, in Ohms, singular) or 2 Ohms (in metric units, in Ohms, plural) specifies an electric resistance.

	Electric resistance times electric current specifies a voltage.

Similarly, there are many kinds of value which don't have named SI units, but where physicists write them down as compounds. These are also easy to add as needed:

	Angular momentum is a kind of value.
	
	1.0 Nms specifies an angular momentum.
	
	Momentum times length specifies an angular momentum.

Besides angular momentum, 'Metric Units' also leaves out:

	volumetric flow (cu m/s), jerk (m/sss), snap (m/ssss), angular velocity (rad/s, though Inform would probably use degrees/s), torque (Nm), wavenumber (1/m), specific volume (cu m/kg), molar volume (cu m/mole), molar heat capacity (J/K/mol), molar energy (J/mol), specific energy (J/kg), energy density (J/cu m), surface tension (J/sq m), thermal conductivity (W/m/C), viscosity (sq m/s), conductivity (S/m), permittivity (F/m), permeability (H/m), electric field strength (V/m), magnetic field strength (A/m), resistivity (Ohm metre).

This extension is pretty faithful to SI conventions. It chooses centigrade rather than Kelvin for temperature, but otherwise it's strictly metric, and does not define Imperial measures. See the example below for how to add these.

Example: ** Galileo, Galileo - Dropping a cannonball or a feather from a variety of heights.

This experiment was first proposed in Pisa in the 1630s, but more definitively carried out by the crew of Apollo 15 in 1971, using a geological hammer and the feather of a falcon. Galileo's point was that heavy objects and light objects fall at the same speed because of gravity, and that only air resistance makes us think feathers fall more slowly than cannonballs. (Of course, heavy objects do land harder; the hammer kicked up a lot more lunar dust than the feather did.)

	*: "Galileo, Galileo"
	
	Include Metric Units by Graham Nelson.
	
	The acceleration due to gravity is an acceleration that varies.
	
	Laboratory is a room. "An elegant Pisan room, with fine Renaissance panels, except for the teleport corridor to the east." A cannon ball and a feather are in the Laboratory.
	
	Martian Outpost is east of the Laboratory. "A reddish-lit room with steel walls, whose only exit is the teleport corridor to west."
	
	A room has an acceleration called gravitational field. The gravitational field of a room is usually 9.807 m/ss. The gravitational field of the Martian Outpost is 3.69 m/ss.
	
	A thing has a mass. The mass of a thing is usually 10g. The mass of the cannon ball is 2kg.
	
	Dropping it from is an action applying to one thing and one length.
	
	Understand "drop [thing] from [length]" as dropping it from.
	
	Check dropping it from:
		if the player is not holding the noun:
			say "You would need to be holding that first." instead.
	
	Check dropping it from:
		if the length understood is greater than 3m:
			say "Just how tall are you, exactly?" instead.
	
	Check dropping it from:
		if the length understood is 0m:
			try dropping the noun instead.
	
	Equation - Newton's Second Law
			F=ma
	where F is a force, m is a mass, a is an acceleration.
	
	Equation - Principle of Conservation of Energy
			mgh = mv^2/2
	where m is a mass, h is a length, v is a velocity, and g is the acceleration due to gravity.
	
	Equation - Galilean Equation for a Falling Body
			v = gt
	where g is the acceleration due to gravity, v is a velocity, and t is an elapsed time.
	
	Carry out dropping something (called the falling body) from:
		now the acceleration due to gravity is the gravitational field of the location;
		let m be the mass of the falling body;
		let h be the length understood;	
		let F be given by Newton's Second Law where a is the acceleration due to gravity;
		say "You let go [the falling body] from a height of [the length understood], and, subject to a downward force of [F], it falls. ";
		now the noun is in the location;
		let v be given by the Principle of Conservation of Energy;
		let t be given by the Galilean Equation for a Falling Body;
		let KE be given by KE = mv^2/2 where KE is an energy;
		say "[t to the nearest 0.01s] later, this mass of [m] hits the floor at [v] with a kinetic energy of [KE].";
		if the KE is greater than 50J:
			say "[line break]This is not doing either the floor or your ears any favours."
	
	Test me with "get ball / drop it from 1m / get ball / drop it from 2m / get ball / drop it from 3m / get ball / drop it from 3.2m / get ball / drop it from 0m / get all / east / drop ball from 3m / drop feather from 3m".

Note the way Inform is able to solve the conservation equation, which says the potential energy at the start equals the kinetic energy at the end, to find the velocity v: this involves taking a square root, but it all happens automatically. Square roots tend to cause rounding errors - so on Mars the cannon ball and feather actually land 0.02s apart, in the calculation above, despite Galileo. But no human observer would notice that discrepancy.

Example: ** The Empire Strikes Back - Using good old Imperial measures of length and area alongside these Frenchified metric ones.

Imperial measures, often going back to obscure customs in Anglo-Saxon England, were inflicted across much of the world in the heyday of the British Empire.  Some are still very much alive in England and its former colonies (Australia, India, New Zealand, Canada, Ireland, the USA and so on) - miles and feet, for instance. Others continue only in unscientific social customs, like sport: horse-races are measured in furlongs; the running distance between the two wickets of a cricket pitch is 22 yards, which is 1 chain exactly; and even in France, a football goal must be 8 feet high and 8 yards wide.

	*: "The Empire Strikes Back"
	
	Include Metric Units by Graham Nelson.
	
	Steeple Aston Cricket Pitch is a room.

	1 inch (in imperial units, in inches, singular) or 2 inches (in imperial units, in inches, plural) specifies a length equivalent to 2.5cm.
	1 foot (in imperial units, in feet, singular) or 2 feet (in imperial units, in feet, plural) specifies a length equivalent to 12 inches.
	1 yard (in imperial units, in yards, singular) or 2 yards (in imperial units, in yards, plural) specifies a length equivalent to 3 feet.
	1 chain (in imperial units, in chains, singular) or 2 chains (in imperial units, in chains, plural) specifies a length equivalent to 22 yards.
	1 furlong (in imperial units, in furlongs, singular) or 2 furlongs (in imperial units, in furlongs, plural) specifies a length equivalent to 10 chains.
	1 mile (in imperial units, in miles, singular) or 2 miles (in imperial units, in miles, plural) specifies a length equivalent to 8 furlongs.
	1 league (in imperial units, in leagues, singular) or 2 leagues (in imperial units, in leagues, plural) specifies a length equivalent to 3 miles.
	
	1 square foot (in imperial units, in square feet, singular) or 2 square feet (in imperial units, in square feet, plural) specifies an area equivalent to 900 sq cm.
	1 square yard (in imperial units, in square yards, singular) or 2 square yards (in imperial units, in square yards, plural) specifies an area equivalent to 9 square feet.
	1 acre (in imperial units, in acres, singular) or 2 acres (in imperial units, in acres, plural) specifies an area equivalent to 4840 square yards.
	
	Understand "convert [a length]" as converting. Converting is an action applying to one length.
	
	Carry out converting:
		let A be the length understood;
		say "Measuring A = [A], which ";
		say "= [A in millimetres] ";
		say "= [A in centimetres] ";
		say "= [A in metres] ";
		say "= [A in kilometres] ";
		say "= [A in inches] ";
		say "= [A in feet] ";
		say "= [A in yards] ";
		say "= [A in chains] ";
		say "= [A in furlongs] ";
		say "= [A in miles] ";
		say "= [A in leagues].";
		say "Metric: [A in metric units].";
		say "Imperial: [A in Imperial units].[paragraph break]";
		
	Test me with "convert 1.2m / convert 2m / convert 30cm / convert 20 chains".

The above conversions are based on 1 inch equals 2.5cm, which is not very accurate: 2.54cm would be closer. But to get that accuracy we would need to represent lengths down to 0.4mm, which is below the 1mm cutoff imposed by 'Metric Units'. We'll accept this 2% error in lengths (or 4% error in areas) as harmless, given that we're not going to be doing any serious calculations in Imperial units; if we were, we'd do better to make a fresh extension for them.

Confusions still cause spectacular failures, as when an Air Canada ground crew mixed up pounds and kilograms and fuelled a Boeing 767 so lightly in 1983 that it ran dry at 41,000 feet, losing all engines, avionics and electricity. The captain, by great good luck also an amateur glider pilot, made a now-legendary landing at an obscure airstrip which the first officer by great good luck had once flown from. The USA's Mars Climate Orbiter spacecraft, whose navigation software confused pounds and newtons, was not so lucky and burned up in the Martian atmosphere in 1998 at a cost of $330 million.
