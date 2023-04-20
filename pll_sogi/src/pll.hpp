#ifndef GRID_SYNC_H_
#define GRID_SYNC_H_

#include <hls_stream.h>
#include <stdint.h>
#include "ap_fixed.h"
#include "hls_math.h"

const float pll_kp = 5;		//PI controller proportional gain kp
const float pll_ki = 2;		//PI controller integral gain ki
const float w0 = 314.1593;	//Nominal frequency 2*pi*50Hz

void abc2dq0(float A, float B, float C, float wt, float& d, float& q, float& zero);

void pll(float Ugq, float Ts, float& theta, float& freq);

void pll_sogi(	hls::stream<float>& in_Va,
		hls::stream<float>& in_Vb,
		hls::stream<float>& in_Vc,
		hls::stream<float>& out_Ugd,
		hls::stream<float>& out_Ugq,
		hls::stream<float>& out_Ug0,
		hls::stream<float>& in_Ts,
		hls::stream<float>& out_theta,
		hls::stream<float>& out_freq);

#endif
