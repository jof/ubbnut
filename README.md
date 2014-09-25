Ubbnut
======

* Ubbnut is a library for programmatically interacting with Ubiquiti networks wireless devices.
* It handles configuration generation, pushing, and pulling.
* There are also some methods for enumerating a LAN segment full of factory fresh hardware, and pushing configuration to it. This is to aid in provisioning.


It should be able to:
---------------------
* Locate APs on a connected broadcast segment
* Pull a config
* Push / apply a config
* generate a configuration into a string
* "parse" a string representing a configuration into a k/v data type
* "compare" configs. Generate a diff of key/value pairs. Some potential libraries could be:
  https://github.com/pvande/differ
  https://github.com/myobie/htmldiff
  http://users.cybercity.dk/~dsl8950/ruby/diff.html

Currently Supported Devices
---------------------------
* Ubiquiti Nanostation Loco {M2, M5} - [http://www.ubnt.com/airmax/nanostationm/](http://www.ubnt.com/airmax/nanostationm/)

Adding support for more devices should probably only need to update constants in lib/ubnt/device. However, anecdotes and past comparisons have shown that there may be some "key" strings in the configuration may differ between hardware. More research is warranted. 


Future plans / TODO / FIXME / HACKING
-------------------------------------

- Ubiquiti-proprietary UDP discovery protocol

There is a Ubiquiti discovery protocol that operates over UDP port 10001. It
sends probes for radio hardware, and gets back responses that describe the
hardware, firmware image, MAC address, etc.

It would be great if this library could send probes and parse their responses.
There is some existing work to craft and fire off a probe packet utilizing the
PacketFu library. See lib/ubnt/locater.rb

- Ubiquiti-proprietary spectral analysis ("AirView",
  spectral{player,server,tool} binaries, TCP/18888 protocol)

There is a Ubiquiti protocol that operates over TCP port 18888, dumping
spectral signal information from a special daemon that operates on the radio
hardware. In conjunction with a Java program on the client side, this displays
a spectragraph showing spectral usage.

It would be great if this library could initiate the special daemon to run on
the radio hardware, connect up to it, query for spectral frame date, and parse
the responsees.

There are some protocol dumps and process list dumps in doc/
