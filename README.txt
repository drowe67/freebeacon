README.txt for FreeDV Beacon (FreeBeacon)
David Rowe, John Nunan, Richard Shaw
Dec 2015

Introduction
------------

FreeDV 1600 beacon.  Listens for FreeDV signals, then transmits a
reply. Places the received signal files on a web server. Requires a
Linux machine with a sound card and RS232-PTT interface to your radio.
Just one sound card is required.  Can run on machines as small as a
Raspberry Pi.

When a "trigger" string is detected in the rx FreeDV text message
(e.g. "hello beacon", or the beacon callsign), the beacon will
transmit a signal report back to you.

It requires a "txfilename" wave file to transmit, e.g. some one saying
"Hi, I am a FreeDV beacon blah blah".  The signal report is encoded
into the transmit text message.  Make the wave file long enough so
that the the signal report is repeated a few times, say 30
seconds. Transmit will stop when the "txfilename" wave file is played
once.

Freebeacon saves the received audio from the radio AND the decoded
audio as wavefiles.  Use "wavefilewritepath" to specify where they are
written.  The file name is a date and time stamp. The length is
limited to 60 seconds. If you set "wavefilewritepath" to a listable
webserver directory the files will be available for download on the
Web.  To avoid filling your file system write a cron job to clean
these files up once a day.

If your input audio device is stereo note we only listen to the left
channel.

If you have a RS232 serial port (specified with "-c") RTS and DTR is
raised on transmit to key your transmitter, and lowered for receive.

If you are using Raspberry Pi you can use one of the GPIOs for PTT
control of your transmitter using the "--rpigpio" option.  You need to
use the BCM GPIO number so "--rpigpio 11" uses pin 23 of the GPIO
connector.

A whole lot of code was lifted from freedv-dev for this program.

TODO
----

  [X] 48 to 8 kHz sample rate conversion
  [X] Port Audio list devices
  [X] command line processing framework
  [X] beacon state machine
  [X] install codec2
  [X] attempt debug sound dongle
      [X] modify for half duplex
      [X] sample rate option
      [X] prog sound dongle debug
  [X] RS232 PTT code
  [X] writing to wave files
  [X] test mode to tx straight away then end, to check levels, debug RS232
  [ ] FreeDV 700 support
  [ ] daemonise
      + change all fprintfs to use log file in daemon mode
  [X] test on laptop
  [X] test on RPi
  [ ] writing text string to a web page (cat, create if doesn't exist)
  [ ] samples from stdin option to work from sdr
  [ ] monitor rx and tx audio on another sound device
  [ ] option to not tx, just log info, for rx only stations
  [ ] Hamlib support for keying different radios
  [ ] basic SM1000 version
      + add mode, state machine
      + has audio interfaces, PTT, so neat solution

Building and Installation
-------------------------

1. sudo apt-get install subversion cmake sox libsamplerate0-dev portaudio19-dev libsndfile1-dev

2. Build and Install codec2-dev:

    svn co http://svn.code.sf.net/p/freetel/code/codec2-dev
    cd codec2-dev
    mkdir build_linux
    cd build_linux
    cmake ../
    make
    sudo make install

    Note: On my Ubuntu 14 and RPi I had to add an extra search path to the
    ld.conf.d directory to match the path the codec2 .so was installed
    in.

    Check it has found libcodec2.so using:

    ldconfig -v | grep codec2

3. Build FreeBeacon:

    svn co http://svn.code.sf.net/p/freetel/code/freebeacon
    cd freebeacon
    mkdir build_linux
    cd build_linux
    cmake ../
    make

4. Testing:

    Plug in your USB sound card and USB RS232 devices.  Use alsamixer
    to adjust levels on your sound card. F6 lets you select sound cards

    Usage:
      ./freebeacon -h

    List sound devices
      ./freebeacon -l

    Example usage:
      ./freebeacon -c /dev/ttyUSB1 --txfilename ~/codec2-dev/wav/vk5qi.wav --dev 4 -v --trigger hello

    Testing your PTT by making it jump straght into tx mode:
      ./freebeacon -c /dev/ttyUSB1 --txfilename ~/codec2-dev/wav/vk5qi.wav --dev 4 -v --trigger hello -t

    Testing sound cards on RPi:

      $ arecord -l

        **** List of CAPTURE Hardware Devices ****
        card 1: Audio [RIGblaster Advantage Audio], device 0: USB Audio [USB Audio]
        Subdevices: 1/1
        Subdevice #0: subdevice #0

      $ arecord -D hw:1,0 -f S16_LE -r 48000 test.wav
      $ aplay test.wav

    Testing:

      As a first step try playing freebeacon_test.wav from another PC
      into the freebeacon machine input, this file has the trigger
      string "hello" in the txt msg.


