#include <cstdlib>
#include <stdint.h>
#include <string.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>
#include <hls_stream.h>

#include "config.hpp"

//#define DEBUG

#ifdef DEBUG
	#include <iostream>
#endif // DEBUG


#define OFFSET 2047



void fixed_to_float(hls::stream< my_pkt > &istrm, hls::stream< my_pkt > &ostrm) {
#pragma HLS INTERFACE mode=axis port=istrm
#pragma HLS INTERFACE mode=axis port=ostrm
#pragma HLS interface ap_ctrl_none port=return


	my_pkt ipkt;
	my_pkt opkt;

	// unions for "conversion"
	fpint idata;
	fpint odata;

	#ifdef DEBUG
		std::cout << "In top()..." << std::endl;
		int i = 0;
	#endif // DEBUG

	the_loop: do {
			ipkt = istrm.read();

			idata.ival = ipkt.data;			// get the data as an integer
//			odata.fval = (idata.fval);		// use the floating-point "alias"
			odata.ival = (idata.ival);

			#ifdef DEBUG
				std::cout << "  i = " << i++ << std::endl;
				std::cout << "    idata = " << idata.fval << std::endl;
				std::cout << "    odata = " << odata.fval << std::endl;
			#endif // DEBUG

			opkt.data = odata.ival;	// the packet expects an integer type
			opkt.last = ipkt.last;
			opkt.dest = ipkt.dest;

			ostrm.write(opkt);

		} while (ipkt.last == false);

}
