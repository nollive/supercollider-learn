s.boot;

(
SynthDef(\bing, { arg what, freq = 400;
    var env, sin;
    env = EnvGen.ar(Env.new([0, 0.5, 0], [Rand(0.1, 3.00)], 1), doneAction: 2);
    sin = Pulse.ar(freq, 0.5, env);
    Out.ar([0, 1], sin * 0.1);
}).add;

SynthDef(\piano, {arg freq = 440;
    var env, sig;
    env = EnvGen.ar(Env.perc(0.01, 1), doneAction: 2);
    sig = SinOsc.ar(freq) * env * 0.3;
    Out.ar([0, 1], sig);
}).add;

SynthDef(\drums, {
    var env, sig;
    env = EnvGen.ar(Env.perc(0.001, 0.2), doneAction: 2);
    sig = WhiteNoise.ar * env * 0.4;
    Out.ar([0, 1], sig);
}).add;

SynthDef(\hihat, {
    var env, sig;
    env = EnvGen.ar(Env.perc(0.001, 0.1), doneAction: 2);
    sig = HPF.ar(WhiteNoise.ar, 8000) * env * 0.2;
    Out.ar([0, 1], sig);
}).add;
)

// // Check the synths
// Synth(\bing);
// Synth(\piano);
// Synth(\drums);
// Synth(\hihat);


// Example of OSC message sent by IanniX (default)
// osc://ip_out:port_out/trigger trigger_id trigger_group_id trigger_value_x trigger_value_y trigger_value_z trigger_xPos trigger_yPos trigger_zPos cursor_id cursor_group_id


////////////
// EXAMPLE - IN IanniX WE DIVIDE THE TRIGGERS IN GROUPS, EACH GROUPS WILL USE A DIFFERENT SYNTH IN SuperCollider
////////////

// Using OSCFunc
(
OSCFunc({arg msg;
    var triggerID = msg[1];
    var groupID = msg[2].asInteger; // Conversion from String to Integer
    var freq = 440;

    // print the received message
	// msg.asString.postln;

    // Map the trigger ID to a frequency
	freq = triggerID.linexp(
		inMin: 0,
		inMax: 100,
		outMin: 200,
		outMax: 1000
	);

    // // print the mapped frequency
    // ("Mapped frequency: " ++ freq).postln;

	// Create a synth based on the groupID of the trigger (freq is used when needed)
    case
	{ groupID == 0 } { Synth(\piano, [\freq, freq]); "Playing Piano".postln; }
	{ groupID == 1 } { Synth(\drums); "Playing Drums".postln; }
	{ groupID == 2 } { Synth(\hihat); "Playing Hi-hat".postln; }
	{ groupID == 3 } { Synth(\bing, [\freq, freq]); "Playing Bing".postln; }
    { true } { ("Unknown groupID: " ++ groupID).postln; };
}, '/trigger');
)


// EXAMPLE OF OSC MESSAGES
NetAddr.localAddr.sendMsg("/trigger", 10, "0"); // trigger \piano
NetAddr.localAddr.sendMsg("/trigger", 2, "1"); // trigger \drums
NetAddr.localAddr.sendMsg("/trigger", 3, "2"); // trigger \hihat
NetAddr.localAddr.sendMsg("/trigger", 4, "3"); // trigger \bing
NetAddr.localAddr.sendMsg("/trigger", 5, "4"); // "Unknown groupID: 4"


s.quit;