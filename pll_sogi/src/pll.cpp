
#include "pll.hpp"
#include <hls_stream.h>
#include <stdint.h>
#include "ap_fixed.h"
#include "hls_math.h"


void abc2dq0(float A, float B, float C, float wt, float& d, float& q, float& zero)
{
#pragma HLS inline

	const ap_fixed<16,2> sqrt3_3 = 0.57733154296875;

	ap_fixed<32,16> A_fix = (ap_fixed<32,16>)A;
	ap_fixed<32,16> B_fix = (ap_fixed<32,16>)B;
	ap_fixed<32,16> C_fix = (ap_fixed<32,16>)C;
	ap_fixed<16,4> wt_fix = (ap_fixed<16,4>)wt;

	ap_fixed<32,16> beta_fix = (B_fix-C_fix)*sqrt3_3;
	ap_fixed<32,16> zero_fix = (A_fix+B_fix+C_fix)/3;
	ap_fixed<32,16> alpha_fix = A_fix-zero_fix;

	ap_fixed<16, 2> cos_wt = hls::cos(wt_fix);
	ap_fixed<16, 2> sin_wt = hls::sin(wt_fix);

	ap_fixed<32,16> d_fix = alpha_fix*cos_wt + beta_fix*sin_wt;
	ap_fixed<32,16> q_fix = -alpha_fix*sin_wt + beta_fix*cos_wt;

	d = (float)d_fix;
	q = (float)q_fix;
	zero = (float)zero_fix;
}

void pll(float Ugq, float Ts, float& theta, float& freq)
{
#pragma HLS inline

	const float theta_max = 6.283185307179586;
	const float theta_min = 0;

	static float pll_accum = 0;
#pragma HLS RESET variable=pll_accum

	float pll_kiTs = pll_ki*Ts;
	pll_accum += pll_kiTs* Ugq;
	float pi_out = pll_kp * Ugq + pll_accum;
	float w = pi_out + w0;

	static float wrapping_accum = 0;
#pragma HLS RESET variable=wrapping_accum

	wrapping_accum += Ts * w;

	if(wrapping_accum > theta_max)
	{
		wrapping_accum -= theta_max;
	}
	else if(wrapping_accum < theta_min)
	{
		wrapping_accum += theta_max;
	}

	theta = wrapping_accum;
	freq = w;
}


void pll_sogi(	hls::stream<float>& in_Va,
			hls::stream<float>& in_Vb,
			hls::stream<float>& in_Vc,
			hls::stream<float>& out_Ugd,
			hls::stream<float>& out_Ugq,
			hls::stream<float>& out_Ug0,
			hls::stream<float>& in_Ts,
			hls::stream<float>& out_theta,
			hls::stream<float>& out_freq)
{
#pragma HLS INTERFACE axis port=in_Va
#pragma HLS INTERFACE axis port=in_Vb
#pragma HLS INTERFACE axis port=in_Vc
#pragma HLS INTERFACE axis port=in_Ts
#pragma HLS INTERFACE axis port=out_Ugd
#pragma HLS INTERFACE axis port=out_Ugq
#pragma HLS INTERFACE axis port=out_Ug0
#pragma HLS INTERFACE axis port=out_theta
#pragma HLS INTERFACE axis port=out_freq
#pragma HLS INTERFACE ap_ctrl_none port=return


		float Va = in_Va.read();
		float Vb = in_Vb.read();
		float Vc = in_Vc.read();
		float Ts = in_Ts.read();

		float Igd,Igq,Ig0,Ugd,Ugq,Ug0,w;
			static float wt;
#pragma HLS RESET variable=wt

		abc2dq0(Va, Vb, Vc, wt, Ugd, Ugq, Ug0);
		pll(Ugq, Ts, wt, w);

		out_Ugd.write(Ugd);
		out_Ugq.write(Ugq);
		out_Ug0.write(Ug0);
		out_theta.write(wt);
		out_freq.write(w);

}
