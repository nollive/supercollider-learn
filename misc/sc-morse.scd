/* inspired by  Kraftwerk: Radioactivity (No Nukes 2012, Tokio, Japan)
*/

(
~morseDict = Dictionary.new;
~morseDict.add("A" -> ".-");
~morseDict.add("B" -> "-...");
~morseDict.add("C" -> "-.-.");
~morseDict.add("D" -> "-..");
~morseDict.add("E" -> ".");
~morseDict.add("F" -> "..-.");
~morseDict.add("G" -> "--.");
~morseDict.add("H" -> "....");
~morseDict.add("I" -> "..");
~morseDict.add("J" -> ".---");
~morseDict.add("K" -> "-.-");
~morseDict.add("L" -> ".-..");
~morseDict.add("M" -> "--");
~morseDict.add("N" -> "-.");
~morseDict.add("O" -> "---");
~morseDict.add("P" -> ".--.");
~morseDict.add("Q" -> "--.-");
~morseDict.add("R" -> ".-.");
~morseDict.add("S" -> "...");
~morseDict.add("T" -> "-");
~morseDict.add("U" -> "..-");
~morseDict.add("V" -> "...-");
~morseDict.add("W" -> ".--");
~morseDict.add("X" -> "-..-");
~morseDict.add("Y" -> "-.--");
~morseDict.add("Z" -> "--..");
~morseDict.add("1" -> ".----");
~morseDict.add("2" -> "..---");
~morseDict.add("3" -> "...--");
~morseDict.add("4" -> "....-");
~morseDict.add("5" -> ".....");
~morseDict.add("6" -> "-....");
~morseDict.add("7" -> "--...");
~morseDict.add("8" -> "---..");
~morseDict.add("9" -> "----.");
~morseDict.add("0" -> "-----");
~morseDict.add(" " -> " ");

// ~morseDict.postln;

/* CHARACTER TO MORSE CODE */
~charToMorse = {
	arg char;
    var morseChar;

    char = char.toUpper;
	morseChar = ~morseDict[char];
    morseChar;
};
// ~charToMorse.value("a");


/* STRING TO MORSE CODE */
~textToMorse = {
	arg text="Hello SuperCollider in Morse";
    var morseString = "";

    text.asString.collect {
		arg char;
        var morseChar;

        char = char.toUpper;
		morseChar = ~morseDict[char.asString];
		morseString = morseString ++ morseChar ++ " ";

		// Breaks without it idk why
		char;
    };
	// morseString.postln;
	morseString;
};
)

// Check
~textToMorse.value("check morse")



/* Morse code duration according to BPM */
(
~morseDurations = {
	arg bpm;
    var dotDuration, dashDuration, spaceDuration;
    dotDuration = (60 / bpm) / 4;  // dot time
    dashDuration = dotDuration * 3; // dash time
    spaceDuration = dotDuration * 7; // space time
    [dotDuration, dashDuration, spaceDuration]; // return array with each time
};

/* MORSE SYNTH */
SynthDef(\morseSynth, {
	arg out=0, freq=800, amp=0.5, dur=0.1;
    var env, sig, noise;
	env = EnvGen.kr(Env.perc(0.01, dur), doneAction: 2);
	sig = (Saw.ar(freq) + Pulse.ar(freq, 0.5)) * 0.5;
	noise = WhiteNoise.ar(0.2) * EnvGen.kr(Env.perc(0.01, dur), doneAction: 2);
	sig = (sig + noise) * amp * env;
	Out.ar(out, sig);
}).add;

/* Play morse code */
~playMorse = {
    arg text, bpm=120, out=0;
    var morseCode, durations, currentTime;

    // text to morse and durations according to bpm
    morseCode = ~textToMorse.value(text);
    durations = ~morseDurations.value(bpm);

    // routine used to trigger synth and wait for duration of dot/dash/space
    Routine({

        // for each char in the morseCode string:
		morseCode.do {
			arg char;
			case
			{ char.asString == "." } { // dot
				Synth(\morseSynth, [\out, out, \dur, durations[0]]);
				(durations[0]).wait; // Wait for the duration of the dot
			}
			{ char.asString == "-" } { // dash
				Synth(\morseSynth, [\out, out, \dur, durations[1]]);
				(durations[1]).wait; // wait for dash duration
			}
			{ char.asString == " " } { // space
				(durations[2]).wait; // wait for space duration
			};
		};
	}).play;
};
)

s.boot;
// EXAMPLE
~playMorse.value("HELLO WORLD", 100, 0); // "HELLO WORLD" at 120 bpm to bus 0
~morseCode = ~textToMorse.value("HELLO WORLD");
~durations = ~morseDurations.value(100);

Synth(\morseSynth, [\out, 0, \dur, ~durations[0]]);
Synth(\morseSynth, [\out, 0, \dur, ~durations[1]]);


s.quit;

