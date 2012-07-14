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
* Ubiquiti Nanostation Loco M5 - [http://www.ubnt.com/nanostationm](http://www.ubnt.com/nanostationm)
* Ubiquiti Nanostation Loco M2 - [http://www.ubnt.com/nanostationm](http://www.ubnt.com/nanostationm)

Adding support for more devices should probably only need to update constants in lib/ubnt/device. However, anecdotes and past comparisons have shown that there may be some "key" strings in the configuration may differ between hardware. More research is warranted. 
