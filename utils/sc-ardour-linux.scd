// CONNECT TO OS MIDI LAYER -> ALSA FOR LINUX
MIDIClient.init(inports: 2, outports:  4, verbose: true);

// LINUX ONLY
MIDIClient.getClientID;

// LIST SOURCES AND DESTINATIONS
// MIDIClient.list;
MIDIClient.sources;
MIDIClient.destinations;

// CREATE MIDIOut instances to connect to the MIDI Outputs of supercollider -> using SuperCollider, out0
m = MIDIOut(port: 0);
n = MIDIOut(0)

// sc can't see ardour, can't connect from here
MIDIClient.destinations

// run a2jmidid -e. You can also do this from another terminal
// CREATE A BRIDGE FROM ALSA (SC) TO JACK (ARDOUR)
"a2jmidid -e".unixCmd

// one precisation:
// - ardour is running on JACK, not on alsa
// - create a new MIDI track in ardour
// - from MIDI Connections panel (Windows pannel) , connect the track to SuperCollider:out0 (in sources > others)
// (source -> external to destination -> track

// - enable recording on that track
// - start recording in ardour

m.noteOn(60);
m.noteOff(60);

Pbind(\type,\midi,\midiout,m,\note,Pxrand((0..12),12),\dur,0.05).play
// a very fast random 12-tone row appeared in ardour's track


/////////
// CHANNEL SELECTION IN ARDOUR -> SELECT CHANNEL FOR EACH SYNTH
// ARDOUR: For each synth, we right click on the header and open the (MIDI) Channel Selector -> INBOUND -> RECORD ONLY SELECTED CHANNEL -> SELECT THE CHANNEL USED BY THE SYNTH (different index start)

// SUPERCOLLIDER: In our MIDI message, we specify the CHANNEL used
m.noteOn(chan: 0, note: 60, veloc: 64);
m.noteOn(chan: 1, note: 52, veloc: 64);

m.noteOn(chan: 0, note: 50, veloc: 64);
n.noteOn(chan: 1, note: 55, veloc: 64);


// Example from Eli Fieldsteel's tutorial 18
// https://www.youtube.com/watch?v=ih2uqOaqb4c&list=PLPYzvS8A_rTaNDweXe6PX4CXSGq4iEWYC&index=19

(
~fm8 = Pbind(
	\type, \midi,
	\midicmd, \noteOn, // using
	\midiout, m, // specify where to send the midi,
	\chan, 0, // specifying the channel
	\midinote, Pwrand([62,74,86,98],[0.1,0.8,0.08,0.02],inf),
	\amp, Pexprand(5,100,inf)/127, // 1=max velocity, 0.5=63% of max -> or 80/127
	\sustain, 0.02, // time between two message, BETWEEN NOTE ON AND NOTE OFF
	\dur, 1/16,
	\stretch, 4*60/108,
).play(quant:4*60/108);


~retroSynth = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\midiout, m,
	\chan, 1, // 2nd channel
	\midinote, Pxrand([
		[38,50,72,77,81],
		[43,55,70,77,79],
		[46,58,69,74,77,84],
	],inf),
	\amp, Pwhite(15,30,inf),
	\sustain, Pexprand(4,8,inf),
	\dur, Prand([4,6,8],inf),
	\strech, 4*60/108,
).play(quant:4*60/108);

)

// Add a new function evaluated when ctrl+. is pressed -> to send NoteOff for all midinotes througt MIDI using MIDIOut instance m
CmdPeriod.add({(0..127).do{arg n; m.noteOff(1, n)}});

// Cleans up the MIDIClient
MIDIClient.disposeClient;


/* BASED ON
elgiano on scsynth.org
https://scsynth.org/t/approaches-to-recording-generated-midi-in-daw/2326/11

Eli FieldSteel on youtube.com
https://www.youtube.com/watch?v=ih2uqOaqb4c&list=PLPYzvS8A_rTaNDweXe6PX4CXSGq4iEWYC&index=19
*/
