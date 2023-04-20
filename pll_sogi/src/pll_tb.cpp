#include "pll.hpp"
#include "math.h"
#include <hls_stream.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define ITERATIONS 2000
#define two_pi 6.283185307f

int main()
{
	/* Test signals */
	hls::stream<float> tb_in_Va;
	hls::stream<float> tb_in_Vb;
	hls::stream<float> tb_in_Vc;
	hls::stream<float> tb_out_Ugd;
	hls::stream<float> tb_out_Ugq;
	hls::stream<float> tb_out_Ug0;
	hls::stream<float> tb_in_Ts;
	hls::stream<float> tb_out_theta;
	hls::stream<float> tb_out_freq;



	/* Test inputs*/
	float in_Va;
	float in_Vb;
	float in_Vc;
	float in_Ts = 0.00005;		// fs = 20kHz
	float Ug_angle = 0;			// change to non-zero to see how pll converges
	float Ig_angle = 0;
	float freq_in = two_pi*50;	// fgrid = 50Hz
	float wt = freq_in*in_Ts;

	/* Test outputs */
	float out_Ugd;
	float out_Ugq;
	float out_theta;
	float out_freq;

	/* Create csv file to store simulation data*/
	FILE *inputs, *outputs;
	inputs = fopen ("inputs.csv", "w+");
	outputs = fopen ("outputs.csv", "w+");
//	fprintf(inputs, "%s", "Va,Vb,Vc\n");
//	fprintf(outputs, "%s", "Ugd,Ugq,theta,theta_in,freq,freq_in\n");

	/* Run model */
	for (int i = 0; i < ITERATIONS; i++)
	{
		in_Va = 311*cos(Ug_angle);
		in_Vb = 311*cos(Ug_angle-two_pi/3);
		in_Vc = 311*cos(Ug_angle+two_pi/3);


		tb_in_Va.write(in_Va);
		tb_in_Vb.write(in_Vb);
		tb_in_Vc.write(in_Vc);

		tb_in_Ts.write(in_Ts);

		pll_sogi(tb_in_Va,tb_in_Vb,tb_in_Vc,tb_out_Ugd,tb_out_Ugq,tb_out_Ug0,tb_in_Ts,tb_out_theta,tb_out_freq);


		out_Ugd = tb_out_Ugd.read();
		out_Ugq = tb_out_Ugq.read();
		out_theta = tb_out_theta.read();
		out_freq = tb_out_freq.read();

		fprintf(inputs,"%f,%f,%f,%f,%f,%f %s",in_Va,in_Vb,in_Vc,"\n");
		fprintf(outputs,"%f,%f,%f,%f,%f,%f,%f,%f %s",out_Ugd,out_Ugq,out_theta,Ug_angle,out_freq,freq_in,"\n");

		if(i>400)freq_in = two_pi*55;	// freq step at 0.02s
		wt = freq_in*in_Ts;
		Ug_angle = remainder((Ug_angle+wt),two_pi);
		Ig_angle = remainder((Ig_angle+wt),two_pi);
	}

	fclose(inputs);
	fclose(outputs);

	printf("------ Test Passed ------\n");

	/* End */
	return 0;
}
