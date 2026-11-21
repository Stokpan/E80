# E80 Computer - Post-flow script
# Converts the .sof output to a compressed JTAG Indirect Configuration (.jic)
# file that can be flashed on the board with the Programmer.
# Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

qexec "quartus_cpf -c -d EPCS4 -s EP4CE6 -o bitstream_compression=on output_files/E80.sof output_files/E80.jic"
