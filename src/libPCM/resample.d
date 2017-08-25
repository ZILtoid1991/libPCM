/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.resample;

import libPCM.utility;

@nogc public:
	/**
	 * Resamples a stream using the nearest sample/
	 */
	void resampleNearest(void* input, size_t lengthIn, float rateIn, void* output, size_t lengthOut, float rateOut){
		double delta = rateOut / rateIn, lookup;
		int nextSample;
		for (int i ; i < lengthOut ; i++){
			lookup = i * delta;
			nextSample = doubleToInt(lookup);
			*cast(int*)(output + (i * 4)) = *cast(int*)(input + (nextSample * 4));
		}
	}
	/**
	 * Resamples a stream using the nearest sample/
	 */
	/*void resampleLinear(void* input, size_t lengthIn, float rateIn, void* output, size_t lengthOut, float rateOut){
		double delta = rateOut / rateIn, lookup;
		int nextSample;
		for (int i ; i < lengthOut - 1 ; i++){
			lookup = i * delta;
			nextSample = doubleToInt(lookup);
			*cast(int*)(output + (i * 4)) = *cast(int*)(input + (nextSample * 4));
		}
	}*/
