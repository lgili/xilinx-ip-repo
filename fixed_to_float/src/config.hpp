
#include "ap_int.h"
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_math.h"

typedef ap_axiu<32, 0, 0, 0> trans_pkt;
typedef ap_axis<32, 0, 0, 0> my_pkt;

void fixed_to_float(hls::stream< my_pkt > &istrm, hls::stream< my_pkt > &ostrm) ;

// Expects max bandwidth at 64 beats burst (for 64-bit data)
static constexpr int MAX_BURST_LENGTH = 32;
static constexpr int BUFFER_FACTOR = 32;

// Buffer sizes
static constexpr int DATA_DEPTH = MAX_BURST_LENGTH * BUFFER_FACTOR;
static constexpr int COUNT_DEPTH = BUFFER_FACTOR;

struct data {
	ap_int<32> data_filed;
	ap_int<1> last;
};

// use a union to "convert" between integer and floating-point
union fpint {
	int ival;		// integer alias
	float fval;		// floating-point alias
};

void top(hls::stream< my_pkt > &istrm, hls::stream< my_pkt > &ostrm);
