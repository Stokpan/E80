1. Open E80.ccf in a text editor and connect the components according to its
   comments

2. Connect your GateMate board to your computer via USB, locate the new
   DirtyJtag device on the Device Manager, and update its driver to the Driver
   folder. The device should now appear under Universal Serial Bus devices
   (not the standard USB adapters).

3. Go to https://github.com/YosysHQ/oss-cad-suite-build/releases and
   download the latest oss-cad-suite release for Windows. Extract it on the
   main toolchain directory so that it contains an oss-cad-suite directory.

4. Run synth.bat. It will go through all the necessary steps, from checking
   requirements to flashing.