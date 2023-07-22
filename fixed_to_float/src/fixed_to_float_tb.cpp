

#include "config.hpp"
#include <cmath>
#include <iostream>

using namespace std;
int main() {
	const int len1 = 8;		// length of 1st packet
		const int len2 = 16;	// length of 2nd packet

		float ivec1[len1];		// input and output vectors for 1st packet
		float ovec1[len1];

		float ivec2[len2];		// input and output vectors for 2nd packet
		float ovec2[len2];

		float idata = 1.0f;		// test data

		hls::stream< my_pkt > istrm;
		hls::stream< my_pkt > ostrm;

		fpint t;	// for int<->float conversion

		my_pkt ipkt;
		my_pkt opkt;

		cout << "1st run..." << endl;
		cout << endl;

		// generate inputs and reference data
		for (auto i = 0; i < len1; i++) {

			ivec1[i] = idata;			// initialize input vector
			ovec1[i] = sqrt(idata);		// calculate reference output

			t.fval = idata;				// prepare for "conversion"
			ipkt.data = t.ival;			// pass bit-pattern *as-is*

			// manage tlast
			if (i == (len1 - 1)) ipkt.last = true;
			else ipkt.last = false;

			istrm.write(ipkt);			// write data to stream

			idata += 1.0f;
		}

		// run DUT
		fixed_to_float(istrm, ostrm);

		// check DUT results
		for (auto i = 0; i < len1; i++) {
			cout << "ivec1[" << i << "] = " << ivec1[i] << endl;
			cout << "  ovec1[" << i << "] = " << ovec1[i] << endl;

			opkt = ostrm.read();
			t.ival = opkt.data;

			cout << "  opkt.data = " << t.fval << endl;

			float err = abs(ovec1[i] - t.fval)/ovec1[i];
			cout << "  err = " << err << endl;
			cout << endl;

			if (err != 0.0) return (1);
		}

		cout << endl;
		cout << "2nd run..." << endl;
		cout << endl;

		// 2nd run
		for (auto i = 0; i < len2; i++) {

			ivec2[i] = idata;			// initialize input vector
			ovec2[i] = sqrt(idata);		// calculate reference output

			t.fval = idata;				// prepare for "conversion"
			ipkt.data = t.ival;			// pass bit-pattern *as-is*

			// manage tlast
			if (i == (len2 - 1)) ipkt.last = true;
			else ipkt.last = false;

			istrm.write(ipkt);			// write data to stream

			idata += 1.0f;
		}

		// run DUT
		fixed_to_float(istrm, ostrm);

		// check DUT results
		for (auto i = 0; i < len2; i++) {
			cout << "ivec2[" << i << "] = " << ivec2[i] << endl;
			cout << "  ovec2[" << i << "] = " << ovec2[i] << endl;

			opkt = ostrm.read();
			t.ival = opkt.data;

			cout << "  opkt.data = " << t.fval << endl;

			float err = abs(ovec2[i] - t.fval)/ovec2[i];
			cout << "  err = " << err << endl;
			cout << endl;

			if (err != 0.0) return (1);
		}

		cout << endl;

		return (0);
}
