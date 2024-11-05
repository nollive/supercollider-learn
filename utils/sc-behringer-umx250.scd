//////////////////////////////////////////////////////////////////////////////
// 1. server config
//////////////////////////////////////////////////////////////////////////////
(
s = Server.local;
s.boot;

s.newBufferAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;

s.options.sampleRate_(48000);
s.options.memSize_(2.pow(20));

//////////////////////////////////////////////////////////////////////////////
// 2. initialize global variables
//////////////////////////////////////////////////////////////////////////////
~out = 0;

~makeBusses =  {
	~bus = Dictionary.new;
	~bus.add(\reverb -> Bus.audio(s,2));
	~bus.add(\chorus -> Bus.audio(s,2));
	~bus.add(\filter -> Bus.audio(s,2));
	~bus.add(\another -> Bus.audio(s,2));
};

~cleanup = {
	s.newBufferAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

~makeNodes = {
	s.bind({ // To have the code block evaluated in the correct order, avoid reverb synth be created before the reverb group is created
		~mainGrp = Group.new;
		~chorusGrp = Group.after(~mainGrp);
		~reverbGrp = Group.after(~chorusGrp);
		~filterGrp = Group.after(~reverbGrp);

		~chorusSynth = Synth.new(
			\chorus,
			[
				\in, ~bus[\chorus],
				\out, ~out,
			],
			~chorusGrp
		);

		~reverbSynth = Synth.new(
			\reverb,
			[
				\amp, 1,
				\predelay, 0.1,
				\revtime, 1.8,
				\lpf, 4500,
				\mix, 0.35,
				\in, ~bus[\reverb],
				\out, ~out,
			],
			~reverbGrp
		);

		~filterSynth = Synth.new(
			\filter,
			[
				\in, ~bus[\filter],
				\filterType, 1,
				\out, ~out,
			],
			~filterGrp
		);
	});
};

~makeEvents = {
	MIDIClient.init;
	MIDIIn.connectAll;

	~notes = Array.newClear(128);
	~bend = 8192;
	~toneAtk = 0.01;
	~toneDecay = 0.3;
	~toneSus = 0.5;
	~toneRel = 1.0;
	~tonePan = 0.0;
	~faderAmp = 1.0;
	// MIDI

	MIDIdef.noteOn(key: \noteOn, func: {
		arg vel, nn, chan, src; // CAUTION THERE IS ORDER
		[vel, nn].postln;
		~notes[nn] = Synth.new(\tone,
			[
				\freq, nn.midicps,
				\amp, vel.linexp(1, 127, 0.01, 0.8),
				\gate, 1, // attention besoin de nouveau midi def pour free les notes
				\bend, ~bend.linlin(0,16383, -2, 2),
				\atk, ~toneAtk,
				\decay, ~toneDecay,
				\sus, ~toneSus,
				\rel, ~toneRel,
				\pan, ~tonePan,
				\amp, ~faderAmp,
				\out, ~bus[\reverb],
			],
			~mainGrp
		);

	});

	MIDIdef.noteOff(key: \noteOff, func: {
		arg vel, nn; // CAUTION THERE IS ORDER
		[vel, nn].postln;
		~notes[nn].set(\gate, 0);
		// ~notes[nn] = nil;
	});

	MIDIdef.bend(\bend, {
		arg val, nn, chan, src;
		[val, nn, src].postln;
		~bend = val;
		~notes.do{arg synth; synth.set(\bend, val.linlin(0,16383, -2, 2))};
	}, chan:0 );

	// R1 - Reverb Depth (mix) (CC91)
	MIDIdef.cc(\cc91, {
		arg val, num, chan, src;
		// [val, num, chan, src].postln;
		~reverbDepth = val.linlin(0, 127, 0, 1);
		~reverbSynth.set(\mix, ~reverbDepth);
	}, 91);

	// R2 - Chorus Depth (mix) (CC93)
	MIDIdef.cc(\cc93, {
		arg val, num, chan, src;
		[val, num, chan, /*src*/].postln;
		~chorusDepth = val.linlin(0, 127, 0, 1);
		~chorusSynth.set(\mix, ~chorusDepth);
	}, 93);

	// R3 - Cutoff Frequence (\cutoffFreq) (CC74)
	MIDIdef.cc(\cc74, {
		arg val, num, chan, src;
		// [val, num, chan, src].postln;
		~cutoffFreq = val.linexp(0, 127, 100, 12000);
		~filterSynth.set(\cutoffFreq, ~cutoffFreq);
	}, 74);

	// R4 - Filter resonance (res) (CC71)
	MIDIdef.cc(\cc71, {
		arg val, num, chan, src;
		// [val, num, chan, src].postln;
		~filterResonance = val.linlin(0, 127, 0, 1);
		~filterSynth.set(\res, ~filterResonance);
	}, 71);

	// R5 - Attack (res) (CC73)
	MIDIdef.cc(\cc73, {
		arg val, num, chan, src;
		// [val, num, chan, src].postln;
		~toneAtk = val.linlin(0, 127, 0.001, 0.05);
		~toneAtk.postln;
	}, 73);

	// R6 - Decay (dec) (CC75)
	MIDIdef.cc(\cc75, {
		arg val, num, chan, src;
		// [val, num, chan, src].postln;
		~toneDecay = val.linlin(0, 127, 0.05, 5);
		~toneDecay.postln;
	}, 75);

	// R7 - Release (rel) (CC72)
	MIDIdef.cc(\cc72, {
		arg val, num, chan, src;
		// [val, num, chan, src].postln;
		~toneRel = val.linlin(0, 127, 0.5, 5);
		~toneRel.postln;
	}, 72);

	// R8 - Pan (pan) (CC10) - NEED FI
	MIDIdef.cc(\cc10, {
		arg val, num, chan, src;
		// [val, num, chan, src].postln;
		~tonePan = val.linlin(0, 127, -1, 1);
		~tonePan.postln;
	}, 10);

	// Fader - Volume mixer (amp) (CC7)
	MIDIdef.cc(\cc7, {
		arg val, num, chan, src;
		// [val, num, chan, src].postln;
		~faderAmp = val.linlin(0, 127, 0, 1);
		~notes.do{arg synth; synth.set(\amp, ~faderAmp)};
		~faderAmp.postln;
	}, 7);
};

//////////////////////////////////////////////////////////////////////////////
// 4. register functions with ServerBoot/Quit/Tree
//////////////////////////////////////////////////////////////////////////////
// ServerBoot // functions evaluated when the server boots
ServerBoot.add(~makeBusses);

// ServerQuit // functions evaluated when the server quits
ServerQuit.add(~cleanup);

//////////////////////////////////////////////////////////////////////////////
// 5. Boot server (take 1-2sec)
//////////////////////////////////////////////////////////////////////////////
(
s.waitForBoot({

	s.sync;
	SynthDef(\filter, {
		arg in, cutoffFreq = 5000, res = 0.5, filterType = 0, amp = 1, out = 0;
		var input, sig;

		input = In.ar(in, 2);
		sig = SelectX.ar(filterType, [
			LPF.ar(input, cutoffFreq, res), // 0 : lpf
			BPF.ar(input, cutoffFreq, res), // 1 : bpf
			HPF.ar(input, cutoffFreq, res)  // 2 : hpf
		]);
		sig = sig * amp;
		Out.ar(out, sig);
	}).add;

	SynthDef(\chorus, {
		arg in, delayTime=0.03, depth=0.01, rate=0.3, numVoices=4, mix=0.5, amp=1, out=0;
		var dry, wet, chorusSig;

		dry = In.ar(in, 2);
		wet = 0;

		numVoices.do {
			var mod, voice;
			mod = SinOsc.kr(rate * Rand(0.9, 1.1), Rand(0, 2 * pi)) * depth;
			voice = DelayC.ar(dry, delayTime + depth, delayTime + mod);
			wet = wet + voice;
		};
		chorusSig = XFade2.ar(dry, wet / numVoices, mix * 2 - 1, amp);
		Out.ar(out, chorusSig);
	}).add;


	SynthDef(\reverb, {
		arg in, predelay=0.08, revtime=1.8,
		lpf=4500, mix=0.15, amp=1, out=0;
		var dry, wet, temp, sig;
		dry = In.ar(in,2);
		temp = In.ar(in,2);
		wet = 0;
		temp = DelayN.ar(temp, 0,2, predelay);
		16.do{
			temp = AllpassN.ar(temp, 0.05, {Rand(0.001,0.05)}!2, revtime);
			temp = LPF.ar(temp, lpf);
			wet = wet + temp;
		};
		sig = XFade2.ar(dry, wet, mix*2-1, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\tone, { // def UGen
		arg freq=440, amp=0.3, gate=0, bend=0, out=0,
		atk=0.01, decay=0.3, sus=0.5, rel=1.0, pan=0.0;
		var sig, env;
		sig = LFTri.ar(freq * bend.midiratio)!2; //convert from semitones to a frequency ratio
		env = EnvGen.kr(
			Env.adsr(
				atk, decay, sus, rel
			),
			gate,
			doneAction:2
		);
		sig = sig * env;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);
	}).add;

	s.sync;
	ServerTree.add(~makeNodes);
	ServerTree.add(~makeEvents);
	s.freeAll;

	s.sync;

	"done".postln;
});
)


)
//////////////////////////////////////////////////////////////////////////////
// 6. anything else requiring a booted server
//////////////////////////////////////////////////////////////////////////////
s.plotTree;
s.meter;

// m = MIDIOut.new(port: 0);
// m.noteOn(chan:0, note: 60, veloc:100);
// m.noteOff(chan:0, note: 60, veloc:100);
//
// (
// Synth.new(\tone,
// 	[
// 		\freq, 400,
// 		\amp, 0.8,
// 		\gate, 1,
// 		\out, ~bus[\reverb],
// 	],
// 	~mainGrp
// );
// )

s.quit;
MIDIClient.disposeClient;