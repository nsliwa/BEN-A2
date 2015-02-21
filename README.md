# BEN-A2
Lab 2 for MSLC
Team B.E.N.:
  Ender Barillas, 
  Bre'shard Busby, 
  Nicole Sliwa


Module A Rubric:
Reads from the microphone
    - Yes
Takes an FFT of the incoming audio stream
    - Yes
Displays the frequency of the two loudest tones within 6Hz accuracy (+-3Hz)
    - Displays frequencies in labels, loudest one first
Please have a way to "lock in" the last frequencies detected on the display
    - Threshold set to 30 decibels: any max frequencies below threshold will not be displayed in view
    - Frequencies don't change until another one is found
Is able to distinguish tones at least 50Hz apart, lasting for 200ms or more
    - Yes
Extra credit: recognize two tones played on a piano 
    - Implementation started: can distinguish A2 to A3, played one at a time


Module B
Reads from the microphone
    - Yes
Plays a settable (via a slider or setter control) inaudible tone to the speakers (15-20kHz)
    - Uses slider on main view
    - Changing slider value (or pressing 'Calibrate') initiates a calibration sequence to fine a baseline fft
Displays the magnitude of the FFT of the microphone data in decibels
    - Displays both magintude of fft and difference between current fft and baseline (2 graphs) - both in decibels
Is able to distinguish when the user is {not gesturing, gestures toward, or gesturing away} 
    - Updates label at top of view to "Stationary" "Toward" and "Away"
    - For "wow" factor: twister spinner controlled by gestures:
        Beginning to gesture toward starts 'windup' counter that determines the angle of spin for the animation. Counter increments while user is gesturing toward and holding steady (but not yet starting to move away) (proportional to (windupCounter % 16) / 16 - because 16 segments on spinner)
        Beginning to gesture away starts 'spin' counter that determines how many times the spin animation repeats (sqrt(spinCount)). Counter increments until user stops gesturing.
        Stopping away gesture triggers spin animation
