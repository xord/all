# beeps ChangeLog


## [v0.3.9] - 2025-07-06

- Add TextIn class
- Add Signals::full()
- Add Siangls_shift() and Signals_set_capacity()
- Add Signals_create() and Signals_append() for AVAudioPCMBuffer
- Add deepwiki badge


## [v0.3.8] - 2025-05-22

- The oscillator resets the frequency to 0.001 if it is set to 0
- The envelope automatically calls note_off internally when sustain_level is 0


## [v0.3.7] - 2025-05-11

- Add LowPass and HighPass classes
- Add Reverb class
- Add Signals class for ruby extension
- Add Beeps.sample_rate()
- Add Processor.get_signals!() method
- Add Oscillator#gain, Oscillator#offset, and Oscillator#duty
- Add more tests for processors

- Update STK
- Processor has sub inputs
- Reimplement oscillators without STK wave generators
- Oscillator#frequency= can take another processor like low frequency oscillator for frequency modulation
- Oscillator: phase, gain, offset, and duty can also accept a processor as input
- Make process segment size variable based on the frequency of the sub-input
- Sequencer: Call set_updated()

- Refactor: hide Beeps::Frames class

- Fix the issue where the sound player with a streaming source does not stop when the envelope's note_off is called
- Fix crashes


## [v0.3.6] - 2025-04-08

- Update dependencies: xot, rucy


## [v0.3.5] - 2025-03-24

- Add PULL_REQUEST_TEMPLATE.md
- Add CONTRIBUTING.md


## [v0.3.4] - 2025-03-07

- Add Mixer class
- Add Processor#add_input
- Add Processor#on_start
- Add new oscillator type NOISE
- Add new oscillator type SAMPLES, and add Oscillator#samples=
- Add Oscillator#phase/phase=
- Add 'openal' to msys2_mingw_dependencies

- Processor.new can take inputs
- Processor#<< returns self
- Square and sawtooth oscillators discard the first some amount of samples
- Oscillator::set_type() takes over the phase value
- Noise oscillator can take frequency parameter
- Gain#initialize can take param for gain
- Envelop's default attack, decay, and release time are changed from 0.01 to 0.005
- Envelop#initialize can take attack, decay, sustain, and release params
- The attack and release can be canceled by passing 0 to the attack_time and release_time of the Envelope

- Temporarily delete Processor#<< to review specifications


## [v0.3.3] - 2025-01-23

- Update dependencies


## [v0.3.2] - 2025-01-14

- Update workflow files
- Set minumum version for runtime dependency


## [v0.3.1] - 2025-01-13

- Add Sequencer class
- Add 'triangle' type to Oscillator
- Add LICENSE file
- Rename: ADSR -> Envelope


## [v0.3] - 2024-07-06

- Support Windows


## [v0.2.1] - 2024-07-05

- Do not delete OpenAL objects after calling OpenAL_fin()
- Do not redefine fin!() methods, they are no longer needed
- Skip 'test_play_end_then_stop' on GitHub Actions
- Update workflows for test
- Update to actions/checkout@v4
- Fix 'github_actions?'


## [v0.2] - 2024-03-14

- Change the super class for exception class from RuntimeError to StandardError


## [v0.1.46] - 2024-02-07

- Fix compile warnings


## [v0.1.45] - 2024-01-08

- Update dependencies


## [v0.1.44] - 2023-12-09

- Trigger github actions on all pull_request


## [v0.1.43] - 2023-11-09

- Use Gemfile to install gems for development instead of add_development_dependency in gemspec


## [v0.1.42] - 2023-10-25

- Add '#include <assert.h>' to Fix compile errors


## [v0.1.41] - 2023-06-27

- Add SoundPlayer#state()
- Delete SoundPlayer#is_playing(), is_paused(), and is_stopped()
- NONE -> TYPE_NONE


## [v0.1.40] - 2023-05-29

- Update dependencies


## [v0.1.39] - 2023-05-29

- Update dependencies


## [v0.1.38] - 2023-05-27

- required_ruby_version >= 3.0.0
- Add spec.license


## [v0.1.37] - 2023-05-18

- Update dependencies


## [v0.1.36] - 2023-05-08

- Update dependencies


## [v0.1.35] - 2023-04-30

- Place the save() method next to load()


## [v0.1.34] - 2023-04-25

- Clear mic streams on exit
- Fix compile errors on assert lines


## [v0.1.33] - 2023-04-22

- Stream playback is now supported.
- Pause, resume, and stop after playback, as well as methods to check the status of the playback.
- Support for saving and loading sound files
- Added Oscillator, MicIn, Gain, ADSR, TimeStretch, PitchShift, and Analyser classes.


## [v0.1.32] - 2023-03-01

- Fix bugs


## [v0.1.31] - 2023-02-27

- Add ChangeLog.md file
- Add test.yml, tag.yaml, and release.yml
- Requires ruby 2.7.0 or later


## [v0.1.30] - 2023-02-09

- Fix conflicting beeps's Init_exception() and others Init_exception()
- Refactoring
