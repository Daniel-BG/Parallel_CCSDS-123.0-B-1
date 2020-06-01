# Parallel_CCSDS-123.0-B-1

CCSDS 123.0-B-1 implementation. Contains a constants file to change any and all parameters so that synthesis creates a customizable core. Connecting the core to a higher-level processing flow is not part of this repository. A simple bye interface is offered as a wrapper to facilitate use.

The implementation is compliant with the CCSDS 123.0-B-1 standard (https://public.ccsds.org/Pubs/123x0b1ec1s.pdf). It has since been extended to the 123.0-B-2 version which this repository does not implement.

# Sources for VHDL modules

The STD_FIFO module is free of copyright, you can see the source here

http://www.deathbylogic.com/2013/07/vhdl-standard-fifo/

Two additional external modules are required. The RX and TX modules of the UART protocol. They can be downloaded from the NandLand Website.

https://www.nandland.com/vhdl/modules/module-uart-serial-port-rs232.html

Everything else is self-contained in this repository.