/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.codecs;

import std.stdio;

import core.stdc.math;
import libPCM.utility;
///For IMA and Dialogic ADPCM
package static immutable byte[16] ADPCM_IndexTable = 
			[-1, -1, -1, -1, 2, 4, 6, 8, 
			 -1, -1, -1, -1, 2, 4, 6, 8];	
///For the Yamaha ADPCM A found in YM2610 and probably other chips
package static immutable byte[16] Yamaha_ADPCM_A_IndexTable =
			[-1, -1, -1, -1, 2, 5, 7, 9, 
			 -1, -1, -1, -1, 2, 5, 7, 9];	
///Used rarely, couldn't find more info about this codec
package static immutable byte[16] Yamaha_ADPCM_DiffLookup =
			[1,  3,  5,  7,  9,  11,  13,  15,
			-1, -3, -5, -7, -9, -11, -13, -15];
///Very rare, mostly experimental
///Very low quality
package static immutable byte[4] ADPCM_IndexTable_2Bit = 
			[-1, 2,
			 -1, 2];
///Very rare, mostly experimental
package static immutable byte[8] ADPCM_IndexTable_3Bit = 
			[-1, -1, 2, 4,
			 -1, -1, 2, 4,];
///Very rare, mostly experimental
///Supposedly has better quality sound than 4bit implementations.
package static immutable byte[32] ADPCM_IndexTable_5Bit = 
			[-1, -1, -1, -1, -1, -1, -1, -1, 1, 2, 4, 6, 8, 10, 13, 16
			 -1, -1, -1, -1, -1, -1, -1, -1, 1, 2, 4, 6, 8, 10, 13, 16];
package static immutable byte[2][5] XA_ADPCM_Table =
			[[0,0],
			[60,0],
			[115,-52],
			[98,-55],
			[112,-60]];
///Most OKI and Yamaha chips seems to use this step-table
package static immutable ushort[49] DIALOGIC_ADPCM_StepTable = 
			[16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55,
			60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190,	
			209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598,
			658, 724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552];		
/** 
 * Most common ADPCM steptable
 */
package static immutable ushort[89] IMA_ADPCM_StepTable = 
			[7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 
			19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 
			50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 
			130, 143, 157, 173, 190, 209, 230, 253, 279, 307,
			337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
			876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 
			2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358,
			5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899, 
			15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767];
package static immutable ushort[16] Yamaha_ADPCM_IndexScale =
			[230, 230, 230, 230, 307, 409, 512, 614,
			 230, 230, 230, 230, 307, 409, 512, 614];
package static immutable ubyte[256] MU_Law_EncodeTable =
			[0,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3,
			4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
			5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
			5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
			6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
			6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
			6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
			6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
			7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7];
package static immutable short[256] MU_Law_DecodeTable =
			[-32124,-31100,-30076,-29052,-28028,-27004,-25980,-24956,
			-23932,-22908,-21884,-20860,-19836,-18812,-17788,-16764,
			-15996,-15484,-14972,-14460,-13948,-13436,-12924,-12412,
			-11900,-11388,-10876,-10364, -9852, -9340, -8828, -8316,
			-7932, -7676, -7420, -7164, -6908, -6652, -6396, -6140,
			-5884, -5628, -5372, -5116, -4860, -4604, -4348, -4092,
			-3900, -3772, -3644, -3516, -3388, -3260, -3132, -3004,
			-2876, -2748, -2620, -2492, -2364, -2236, -2108, -1980,
			-1884, -1820, -1756, -1692, -1628, -1564, -1500, -1436,
			-1372, -1308, -1244, -1180, -1116, -1052,  -988,  -924,
			-876,  -844,  -812,  -780,  -748,  -716,  -684,  -652,
			-620,  -588,  -556,  -524,  -492,  -460,  -428,  -396,
			-372,  -356,  -340,  -324,  -308,  -292,  -276,  -260,
			-244,  -228,  -212,  -196,  -180,  -164,  -148,  -132,
			-120,  -112,  -104,   -96,   -88,   -80,   -72,   -64,
			-56,   -48,   -40,   -32,   -24,   -16,    -8,     -1,
			32124, 31100, 30076, 29052, 28028, 27004, 25980, 24956,
			23932, 22908, 21884, 20860, 19836, 18812, 17788, 16764,
			15996, 15484, 14972, 14460, 13948, 13436, 12924, 12412,
			11900, 11388, 10876, 10364,  9852,  9340,  8828,  8316,
			7932,  7676,  7420,  7164,  6908,  6652,  6396,  6140,
			5884,  5628,  5372,  5116,  4860,  4604,  4348,  4092,
			3900,  3772,  3644,  3516,  3388,  3260,  3132,  3004,
			2876,  2748,  2620,  2492,  2364,  2236,  2108,  1980,
			1884,  1820,  1756,  1692,  1628,  1564,  1500,  1436,
			1372,  1308,  1244,  1180,  1116,  1052,   988,   924,
			876,   844,   812,   780,   748,   716,   684,   652,
			620,   588,   556,   524,   492,   460,   428,   396,
			372,   356,   340,   324,   308,   292,   276,   260,
			244,   228,   212,   196,   180,   164,   148,   132,
			120,   112,   104,    96,    88,    80,    72,    64,
			56,    48,    40,    32,    24,    16,     8,     0];
package static immutable ubyte[128] A_Law_EncodeTable = 
			[1,1,2,2,3,3,3,3,
			4,4,4,4,4,4,4,4,
			5,5,5,5,5,5,5,5,
			5,5,5,5,5,5,5,5,
			6,6,6,6,6,6,6,6,
			6,6,6,6,6,6,6,6,
			6,6,6,6,6,6,6,6,
			6,6,6,6,6,6,6,6,
			7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7,
			7,7,7,7,7,7,7,7];
package static immutable short[256] A_Law_DecodeTable = 
			[-5504, -5248, -6016, -5760, -4480, -4224, -4992, -4736,
			-7552, -7296, -8064, -7808, -6528, -6272, -7040, -6784,
			-2752, -2624, -3008, -2880, -2240, -2112, -2496, -2368,
			-3776, -3648, -4032, -3904, -3264, -3136, -3520, -3392,
			-22016,-20992,-24064,-23040,-17920,-16896,-19968,-18944,
			-30208,-29184,-32256,-31232,-26112,-25088,-28160,-27136,
			-11008,-10496,-12032,-11520,-8960, -8448, -9984, -9472,
			-15104,-14592,-16128,-15616,-13056,-12544,-14080,-13568,
			-344,  -328,  -376,  -360,  -280,  -264,  -312,  -296,
			-472,  -456,  -504,  -488,  -408,  -392,  -440,  -424,
			-88,   -72,   -120,  -104,  -24,   -8,    -56,   -40,
			-216,  -200,  -248,  -232,  -152,  -136,  -184,  -168,
			-1376, -1312, -1504, -1440, -1120, -1056, -1248, -1184,
			-1888, -1824, -2016, -1952, -1632, -1568, -1760, -1696,
			-688,  -656,  -752,  -720,  -560,  -528,  -624,  -592,
			-944,  -912,  -1008, -976,  -816,  -784,  -880,  -848,
			5504,  5248,  6016,  5760,  4480,  4224,  4992,  4736,
			7552,  7296,  8064,  7808,  6528,  6272,  7040,  6784,
			2752,  2624,  3008,  2880,  2240,  2112,  2496,  2368,
			3776,  3648,  4032,  3904,  3264,  3136,  3520,  3392,
			22016, 20992, 24064, 23040, 17920, 16896, 19968, 18944,
			30208, 29184, 32256, 31232, 26112, 25088, 28160, 27136,
			11008, 10496, 12032, 11520, 8960,  8448,  9984,  9472,
			15104, 14592, 16128, 15616, 13056, 12544, 14080, 13568,
			344,   328,   376,   360,   280,   264,   312,   296,
			472,   456,   504,   488,   408,   392,   440,   424,
			88,    72,   120,   104,    24,     8,    56,    40,
			216,   200,   248,   232,   152,   136,   184,   168,
			1376,  1312,  1504,  1440,  1120,  1056,  1248,  1184,
			1888,  1824,  2016,  1952,  1632,  1568,  1760,  1696,
			688,   656,   752,   720,   560,   528,   624,   592,
			944,   912,  1008,   976,   816,   784,   880,   848];
/**
 * For easy access of 5bit ADPCM nibbles
 */
align(1) struct ADPCMDataPacket5Bit{
	ubyte word1, word2, word3, word4, word5;	///Sequential words
	/**
	 * Ampersand it with 8 to avoid issues.
	 */
	@nogc ubyte opIndex(size_t index){
		final switch(index){
			case 0:
				return word1>>3;
			case 1:
				return (word1 & 0b0000_0111)<<2 | word2>>6;
			case 2:
				return (word2 & 0b0011_1110)>>1;
			case 3:
				return (word2 & 0b0000_0001)<<5 | word3>>4;
			case 4:
				return (word3 & 0b0000_1111)<<1 | word4>>7;
			case 5:
				return (word4 & 0b0111_1100)>>2;
			case 6:
				return (word4 & 0b0000_0011)<<3 | word5>>5;
			case 7:
				return word5 & 0b0001_1111;
		}
	}
	@nogc ubyte opIndexAssign(size_t index, ubyte val){
		final switch(index){
			case 0:
				word1 &= 0b0000_0111;
				word1 |= val<<3;
				return val;
			case 1:
				word1 &= 0b1111_1000;
				word1 |= val>>2;
				word2 &= 0b0011_1111;
				word2 |= val<<6;
				return val;
			case 2:
				word2 &= 0b1100_0001;
				word2 |= val<<1;
				return val;
			case 3:
				word2 &= 0b1111_1110;
				word2 |= val>>4;
				word3 &= 0b0000_1111;
				word3 |= val<<4;
				return val;
			case 4:
				word3 &= 0b1111_0000;
				word3 |= val>>1;
				word4 &= 0b0111_1111;
				word4 |= val<<4;
				return val;
			case 5:
				word4 &= 0b1000_0011;
				word4 |= val<<2;
				return val;
			case 6:
				word4 &= 0b1111_1100;
				word4 |= val>>3;
				word5 &= 0b0001_1111;
				word5 |= val<<5;
				return val;
			case 7:
				word5 &= 0b1110_0000;
				word5 |= val;
				return val;
			
		}
	}
}
/**
 * For easy access of 3bit ADPCM nibbles
 */
align(1) struct ADPCMDataPacket3Bit{
	ubyte word1, word2, word3;	///Sequential words
	/**
	 * Ampersand it with 8 to avoid issues.
	 */
	@nogc ubyte opIndex(size_t index){
		final switch(index){
			case 0:
				return word1>>5;
			case 1:
				return (word1 & 0b0001_1100)>>2;
			case 2:
				return (word1 & 0b0000_0011)<<1 | word2>>7;
			case 3:
				return (word2 & 0b0111_0000)>>4;
			case 4:
				return (word2 & 0b0000_1110)>>1;
			case 5:
				return (word2 & 0b0000_0001)<<2 | word3>>6;
			case 6:
				return (word3 & 0b0011_1000)>>3;
			case 7:
				return word3 & 0b0000_0111;
		}
	}
	@nogc ubyte opIndexAssign(size_t index, ubyte val){
		final switch(index){
			case 0:
				word1 &= 0b0001_1111;
				word1 |= val<<5;
				return val;
			case 1:
				word1 &= 0b1110_0011;
				word1 |= val<<2;
				return val;
			case 2:
				word2 &= 0b1111_1100;
				word2 |= val>>1;
				word2 &= 0b0111_1111;
				word2 |= val<<7;
				return val;
			case 3:
				word2 &= 0b1000_1111;
				word2 |= val<<4;
				return val;
			case 4:
				word2 &= 0b1111_0001;
				word2 |= val<<1;
				return val;
			case 5:
				word2 &= 0b1111_1110;
				word2 |= val>>2;
				word3 &= 0b0011_1111;
				word3 |= val<<6;
				return val;
			case 6:
				word3 &= 0b1100_0111;
				word3 |= val<<3;
				return val;
			case 7:
				word3 &= 0b1111_1000;
				word3 |= val;
				return val;
			
		}
	}
}
/**
 * Alias for function pointer for codec interchangeability
 */
alias CommonDecoderFuncPtr = short function(ubyte* inputStream, DecoderWorkpad* workpad);
/**
 * A note on workpads:
 * Dynamic decode functions use 16 bytes of workpad, consisting of 4 32 bit integers, which is the recommended initialization method to avoid misaligned
 * integers. For looping an audio sample, you need to back up the workpad at the start of the loop, monitor the third integer (which is the position), then
 * replace the current workpad's data with the backed up one. This is extremly important with ADPCM as they depend on many local values.
 * Dynamic encode functions use 32 bytes. In these cases, the 3rd and 6th integers need to be set to zero if working on a fixed length buffer.
 * Functions meant to be used on a fixed length buffer coming soon.
 *
 * None of the functions depend on external libraries or functions, and require no garbage collection.
 */
public @nogc struct DecoderWorkpad{
	uint position;	///Data offset in samples
	int stepIndex;	///ADPCM: current position on the steptable of the codec
	int x_nMinusOne;///Previous outputted sample
	int predictor;	///unused
	public @nogc this(uint position, int stepIndex, int x_nMinusOne){
		this.position = position;
		this.stepIndex = stepIndex;
		this.x_nMinusOne = x_nMinusOne;
	}
}
public @nogc struct EncoderWorkpad{
	uint position;	///Data offset in samples
	uint stepSize;	///ADPCM: Size of the next step
	int stepIndex;	///ADPCM: current position on the steptable of the codec
	int d_nMinusOne;///Previous sample for error compensation
	DecoderWorkpad dW;
	public @nogc this(uint position, uint stepSize, int stepIndex, int d_nMinusOne, DecoderWorkpad dW){
		this.position = position;
		this.stepIndex = stepIndex;
		this.stepSize = stepSize;
		this.d_nMinusOne = d_nMinusOne;
		this.dW = dW;
	}
}
/**
 * Dinamically decodes a Mu-Law stream
 */
public @nogc short dynamicDecodeMuLawPCM(ubyte* inputStream, DecoderWorkpad* workpad){
	
	return MU_Law_DecodeTable[inputStream[workpad.position++]];
}
/**
 * Dinamically decodes an A-Law stream
 */
public @nogc short dynamicDecodeALawPCM(ubyte* inputStream, DecoderWorkpad* workpad){
	
	return A_Law_DecodeTable[inputStream[workpad.position++]];
}
/**
 * Dinamically decodes an IMA ADPCM stream.
 */
public @nogc short dynamicDecodeIMAADPCM(ubyte* inputStream, DecoderWorkpad* workpad){
	uint stepSize;
	int d_n;
	ubyte index;
	//get the next index
	if(workpad.position & 1)
		index = inputStream[workpad.position>>1] & 0x0F;
	else
		index = (inputStream[workpad.position>>1])>>4;
	//calculate the next step size
	workpad.stepIndex += ADPCM_IndexTable[index];
	//clamp the index data within the steptable's range
	if(workpad.stepIndex < 0)
		workpad.stepIndex = 0;
	else if(workpad.stepIndex > 88)
		workpad.stepIndex = 88;
	stepSize = IMA_ADPCM_StepTable[workpad.stepIndex];
	d_n = ((stepSize) * (index & 0b0100)>>2) + ((stepSize>>1) * (index & 0b0010)>>1) + ((stepSize>>2) * index & 0b0001) + (stepSize>>3);

	if(index & 0b1000)
		d_n *= -1;
	//adding positive feedback value
	d_n += workpad.x_nMinusOne;

	
	workpad.position++;
	workpad.x_nMinusOne = d_n;
	return cast(short)d_n;
}
/**
 * Dinamically decodes an Dialogic ADPCM stream.
 */
public @nogc short dynamicDecodeDialogicADPCM(ubyte* inputStream, DecoderWorkpad* workpad){
	uint stepSize;
	int d_n;
	ubyte index;
	//get the next index
	if(workpad.position & 1)
		index = inputStream[workpad.position>>1] & 0x0F;
	else
		index = (inputStream[workpad.position>>1])>>4;
	//calculate the next step size
	workpad.stepIndex += ADPCM_IndexTable[index];
	//clamp the index data within the steptable's range
	if(workpad.stepIndex < 0)
		workpad.stepIndex = 0;
	else if(workpad.stepIndex > 48)
		workpad.stepIndex = 48;
	stepSize = DIALOGIC_ADPCM_StepTable[workpad.stepIndex];
	
	d_n = ((stepSize) * (index & 0b0100)>>2) + ((stepSize>>1) * (index & 0b0010)>>1) + ((stepSize>>2) * index & 0b0001) + (stepSize>>3);

	if(index & 0b1000)
		d_n *= -1;
	//adding positive feedback value
	d_n += workpad.x_nMinusOne;

	workpad.position++;
	workpad.x_nMinusOne = d_n;
	return cast(short)d_n;
}
/**
 * Initializes the index at 16 for Dialogic ADPCM codecs.
 */
public @nogc DecoderWorkpad initializeDialogicADPCMDecoderWorkpad(){
	return DecoderWorkpad(0,16,0);
}
/**
 * Dynamically decodes a Yamaha ADPCM A stream. Workpad is 16 bytes long.
 */
public @nogc short dynamicDecodeYamahaADPCMA(ubyte* inputStream, DecoderWorkpad* workpad){
	uint stepSize;
	int d_n;
	ubyte index;
	//get the next index
	if(workpad.position & 1)
		index = inputStream[workpad.position>>1] & 0x0F;
	else
		index = (inputStream[workpad.position>>1])>>4;
	//calculate the next step size
	workpad.stepIndex += Yamaha_ADPCM_A_IndexTable[index];
	//clamp the index data within the steptable's range
	if(workpad.stepIndex < 0)
		workpad.stepIndex = 0;
	else if(workpad.stepIndex > 48)
		workpad.stepIndex = 48;
	stepSize = DIALOGIC_ADPCM_StepTable[workpad.stepIndex];
	
	d_n = ((stepSize) * (index & 0b0100)>>2) + ((stepSize>>1) * (index & 0b0010)>>1) + ((stepSize>>2) * index & 0b0001) + (stepSize>>3);

	if(index & 0b1000)
		d_n *= -1;
	//adding positive feedback value
	d_n += workpad.x_nMinusOne;

	workpad.position++;
	workpad.x_nMinusOne = d_n;
	return cast(short)d_n;
}
/**
 * Appends 8 bit unsigned PCM to 16 bit signed PCM. Workpad is 16 bytes long.
 */
public @nogc short dynamicDecode8BitPCMUnsigned(ubyte* inputStream, DecoderWorkpad* workpad){
	int output = inputStream[workpad.position];
	output = output | output<<8;
	output += short.min;

	workpad.position++;
	return cast(short)(output);
}
public @nogc short dynamicDecode12BitPCMUnsigned(ubyte* inputStream, DecoderWorkpad* workpad){
	int output;
	if(workpad.position & 1){
		output = (inputStream[workpad.position])<<8;
		output |= (inputStream[workpad.position + 1])&0xF0;
	}else{
		output = (inputStream[workpad.position])&0x0F;
		output |= inputStream[workpad.position + 1];
		output<<=4;
	}
	output += short.min;
	workpad.position++;
	return cast(short)(output);
}
public @nogc short dynamicDecode12BitPCMSigned(ubyte* inputStream, DecoderWorkpad* workpad){
	int output;
	if(workpad.position & 1){
		output = (inputStream[workpad.position])<<8;
		output |= (inputStream[workpad.position + 1])&0xF0;
	}else{
		output = (inputStream[workpad.position])&0x0F;
		output |= inputStream[workpad.position + 1];
		output<<=4;
	}
	workpad.position++;
	return cast(short)(signExtend(output, 12));
}
/**
 * Workpad for XA ADPCM decoders
 */
public @nogc struct XAADPCMDecoderWorkpad{
	int[8] sample_minusOne;
	int[8] sample_minusTwo;
	//uint inputOffset;
	//uint outputOffset;
}
/**
 * Decodes a single unit of XA ADPCM.
 */
public @nogc void unitDecodeXAADPCM(ubyte* inputStream, short* outputStream, int channels, XAADPCMDecoderWorkpad* workpad, int filter, int shift, int unit){
	int difference, sample, currentCh = unit & (channels - 1);
	
	for(int i ; i < 28 ; i++){
		difference = inputStream[(unit>>1) + (i * 4)];
		difference = unit & 1 ? signExtend(difference>>4, 4) : signExtend(difference, 4);
		sample = (difference << shift) + ((workpad.sample_minusOne[currentCh] * XA_ADPCM_Table[filter][0] + workpad.sample_minusTwo[currentCh] * XA_ADPCM_Table[filter][1]) >> 6);
		if(sample >= short.max)
			sample = short.max;
		else if(sample < short.min)
			sample = short.min;
		workpad.sample_minusTwo[currentCh] = workpad.sample_minusOne[currentCh];
		workpad.sample_minusOne[currentCh] = sample;
		outputStream[(i * channels) + currentCh + (unit * 28)] = cast(short)sample;
	}
}
/**
 * Decodes a whole block of XA ADPCM, which outputs (8-channels)*28 samples for each channel.
 */
public @nogc void blockDecodeXAADPCM(ubyte* inputStream, short* outputStream, int channels, XAADPCMDecoderWorkpad* workpad){
	int shift, filter, f0, f1;
	//inputStream += workpad.inputOffset;
	//outputStream += workpad.outputOffset;
	for(int unit; unit < 8; unit ++){
		//int currentChannel = unit & (channels - 1);
		shift = 12 - (inputStream[4 + unit] & 0x0F);
		filter = (inputStream[4 + unit])>>4;
		if(filter >= XA_ADPCM_Table.length)
			filter = 0;
		unitDecodeXAADPCM(inputStream + 16, outputStream, channels, workpad, filter, shift, unit);
	}
}
/**
 * Dinamically encodes a stream with Mu-Law PCM.
 */
public @nogc void dynamicEncodeMuLawPCM(short* inputStream, ubyte* outputStream, EncoderWorkpad* workpad){
	int sample = inputStream[workpad.position];
	ubyte sign = sample < 0 ? 0b1000_0000 : 0;
	if(!sign)
		sample *= -1;
	sample += 0x84;
	ubyte exponent = MU_Law_EncodeTable[(sample>>7) & 0xFF];
	ubyte mantissa = cast(ubyte)((sample>>(exponent+3))& 0x0F);
	*outputStream = cast(ubyte)(sign | (exponent<<4) | mantissa);
	workpad.position++;
}
/**
 * Dinamically encodes a stream with A-Law PCM.
 */
public @nogc void dynamicEncodeALawPCM(short* inputStream, ubyte* outputStream, EncoderWorkpad* workpad){
	int sample = inputStream[workpad.position];
	ubyte sign = (~sample >> 8) & 0b1000_0000;
	ubyte output;
	if(!sign)
		sample *= -1;
	if(sample >= 256){
		ubyte exponent = A_Law_EncodeTable[(sample>>8) & 0x7F];
		output |= ((sample >> (exponent + 3)) & 0x0F);
		output |= exponent << 4;
	}else{
		output |= cast(ubyte)(sample >> 4);
	}
	*outputStream = output ^ sign ^ 0x55;
	workpad.position++;
}
/**
 * Dinamically encodes a stream with IMA ADPCM. Workpad is 32 bytes long, inputStream and outputStream always points to the first byte.
 */
public @nogc void dynamicEncodeIMAADPCM(short* inputStream, ubyte* outputStream, EncoderWorkpad* workpad){
	//int x_nMinusOne = *cast(int*)(workpad + 4);
	//uint position = *cast(uint*)(workpad + 8);
	//uint stepSize = *cast(uint*)(workpad + 12);
	ubyte index;

	int d_n = inputStream[workpad.position] - workpad.d_nMinusOne; //applying negative feedback to x_n
	if(d_n < 0){ 
		d_n *=-1; //get the absolute value of d_n
		index = 0b1000;	//set the sign if d_n is negative
	}
	if(d_n >= workpad.stepSize){
		index |= 0b0100;
		d_n -= workpad.stepSize;
	}
	workpad.stepSize >>= 1;
	if(d_n >= workpad.stepSize){
		index |= 0b0010;
		d_n -= workpad.stepSize;
	}
	workpad.stepSize >>= 1;
	if(d_n >= workpad.stepSize)
		index |= 0b0001;
	
	//calculate next step size
	//int stepIndex = *cast(int*)(workpad);
	workpad.stepIndex += ADPCM_IndexTable[index];
	//clamp the index data within the steptable's range
	if(workpad.stepIndex <= 0)
		workpad.stepIndex = 0;
	else if(workpad.stepIndex > 88)
		workpad.stepIndex = 88;
	workpad.stepSize = IMA_ADPCM_StepTable[workpad.stepIndex];
	//*cast(int*)(workpad) = stepIndex;

	//write the new index into the outputStream
	if(workpad.position & 1)
		*(outputStream) |= index;
	else
		*(outputStream) = cast(ubyte)(index<<4);
	
	//calculate new x_nMinusOne
	workpad.d_nMinusOne = dynamicDecodeIMAADPCM(outputStream, &workpad.dW);

	workpad.position++;
	//*cast(int*)(workpad + 8) = position;
}
/**
 * Dinamically encodes a stream with Dialogic ADPCM. Workpad is 32 bytes long, inputStream and outputStream always points to the first byte.
 */
public @nogc void dynamicEncodeDialogicADPCM(short* inputStream, ubyte* outputStream, EncoderWorkpad* workpad){
	//int x_nMinusOne = *cast(int*)(workpad + 4);
	//uint position = *cast(uint*)(workpad + 8);
	//uint stepSize = *cast(uint*)(workpad + 12);
	ubyte index;

	int d_n = inputStream[workpad.position] - workpad.d_nMinusOne; //applying negative feedback to x_n
	d_n /= 16;
	if(d_n < 0){ 
		d_n *=-1; //get the absolute value of d_n
		index = 0b1000;	//set the sign if d_n is negative
	}
	if(d_n >= workpad.stepSize){
		index |= 0b0100;
		d_n -= workpad.stepSize;
	}
	workpad.stepSize >>= 1;
	if(d_n >= workpad.stepSize){
		index |= 0b0010;
		d_n -= workpad.stepSize;
	}
	workpad.stepSize >>= 1;
	if(d_n >= workpad.stepSize)
		index |= 0b0001;
	
	//calculate next step size
	//int stepIndex = *cast(int*)(workpad);
	workpad.stepIndex += ADPCM_IndexTable[index];
	//clamp the index data within the steptable's range
	if(workpad.stepIndex < 0)
		workpad.stepIndex = 0;
	else if(workpad.stepIndex > 48)
		workpad.stepIndex = 48;
	workpad.stepSize = DIALOGIC_ADPCM_StepTable[workpad.stepIndex];
	//*cast(int*)(workpad) = stepIndex;

	//write the new index into the outputStream
	if(workpad.position & 1)
		*(outputStream) |= index;
	else
		*(outputStream) = cast(ubyte)(index<<4);
	
	//calculate new d_nMinusOne
	workpad.d_nMinusOne = dynamicDecodeDialogicADPCM(outputStream, &workpad.dW);

	workpad.position++;
	//position++;
	//*cast(int*)(workpad + 8) = position;
}
/**
 * Initializes the index at 16 for Dialogic ADPCM codecs.
 */
public @nogc EncoderWorkpad initializeDialogicADPCMEncoderWorkpad(){
	//return [16,0,0,0,16,0,0,0];
	return EncoderWorkpad(0, 0, 16, 0 , initializeDialogicADPCMDecoderWorkpad());
}
/**
 * Dinamically encodes a stream with Yamaha ADPCM A. Workpad is 32 bytes long, inputStream and outputStream always points to the first byte.
 */
public @nogc void dynamicEncodeYamahaADPCMA(short* inputStream, ubyte* outputStream, EncoderWorkpad* workpad){
	//int x_nMinusOne = *cast(int*)(workpad + 4);
	//uint position = *cast(uint*)(workpad + 8);
	//uint stepSize = *cast(uint*)(workpad + 12);
	ubyte index;

	int d_n = inputStream[workpad.position] - workpad.d_nMinusOne; //applying negative feedback to x_n
	d_n /= 16;
	if(d_n < 0){ 
		d_n *=-1; //get the absolute value of d_n
		index = 0b1000;	//set the sign if d_n is negative
	}
	if(d_n >= workpad.stepSize){
		index |= 0b0100;
		d_n -= workpad.stepSize;
	}
	workpad.stepSize >>= 1;
	if(d_n >= workpad.stepSize){
		index |= 0b0010;
		d_n -= workpad.stepSize;
	}
	workpad.stepSize >>= 1;
	if(d_n >= workpad.stepSize)
		index |= 0b0001;
	
	//calculate next step size
	//int stepIndex = *cast(int*)(workpad);
	workpad.stepIndex += Yamaha_ADPCM_A_IndexTable[index];
	//clamp the index data within the steptable's range
	if(workpad.stepIndex < 0)
		workpad.stepIndex = 0;
	else if(workpad.stepIndex > 48)
		workpad.stepIndex = 48;
	workpad.stepSize = DIALOGIC_ADPCM_StepTable[workpad.stepIndex];
	//*cast(int*)(workpad) = stepIndex;

	//write the new index into the outputStream
	if(workpad.position & 1)
		*(outputStream) |= index;
	else
		*(outputStream) = cast(ubyte)(index<<4);
	
	//calculate new x_nMinusOne
	workpad.d_nMinusOne = dynamicDecodeYamahaADPCMA(outputStream, &workpad.dW);

	workpad.position++;
	//*cast(int*)(workpad + 8) = position;
}
/**
 * Keeper values fo XAADPCM encoding.
 */
public @nogc struct XAADPCMEncoderWorkpad{
	int[2][8] sample_MinusOne;
	int[2][8] vl;
	/*uint inputOffset, outputOffset;
	public @nogc void blockIncrement(){
		outputOffset += 16 + (28 * 4);
		inputOffset += (28 * 8);
	}*/
}
/**
 * Encodes a unit of XA ADPCM
 */
public @nogc double encodeXAADPCM(int unit, XAADPCMEncoderWorkpad* workpad, byte[2] inputCoEff, 
							short* inputStream, ubyte* outputStream, int iostep, int channels, bool vl = false){
	int curc = (unit & (channels - 1)) + ((unit >> (channels-1) ) * 28 * channels);
	short* ip = inputStream + curc, itop = ip + (channels * 28);
	ubyte* op;
	int ox = unit;
	int d, v; // v0 = workpad.sample_MinusOne[0], v1 = workpad.sample_MinusTwo[1];
	double d2 = 0;
	int step = 1 << (12 - iostep);
	op = outputStream;
	for(; ip < itop; ip += channels){
		int vlin = (workpad.sample_MinusOne[unit][0] * inputCoEff[0] + workpad.sample_MinusOne[unit][1] * inputCoEff[1]) >> 6, dp, c;
		d = *ip - vlin;
		dp = d + (step << 3) + (step >> 1);
		if(dp > 0){
			c = dp / step;
			if(c > 15)
				c = 15;
		}
		c -= 8;
		dp = c * step;
		c &= 0x0F;
		v = vlin + dp;
		if(v >= short.max)
			v = short.max;
		else if(v < short.min)
			v = short.min;
		workpad.sample_MinusOne[unit][1] = workpad.sample_MinusOne[unit][0];
		workpad.sample_MinusOne[unit][0] = v;

		d = *ip - workpad.sample_MinusOne[unit][0];
		d2 += d * d;

		if(op){
			op[ox >> 1] |= (ox & 1) ? (c << 4) : c;
			ox += 8;
		}
	}
	if(vl){
		d = workpad.sample_MinusOne[unit][0] - workpad.vl[unit][0];
		d2 += d*d;
		d = workpad.sample_MinusOne[unit][1] - workpad.vl[unit][1];
		d2 += d*d;
		d2 /= 30;
	}else{
		d2 /= 28;
	}
	return sqrt(d2);
}
/**
 * Encodes a block of 16 bit PCM stream into XA ADPCM.
 */
public @nogc void blockEncodeXAADPCM(short* inputStream, ubyte* outputStream, int channels, XAADPCMEncoderWorkpad* workpad, bool vl = false){
	int s, smin, k, kmin, unit, c;
	double dmin;
	/*inputStream += workpad.inputOffset;
	outputStream += workpad.outputOffset;*/
	for(; unit < 8 ; unit++){
		c = unit & (channels - 1);
		//set work values to zero
		dmin = 0;
		kmin = 0;
		smin = 0;
		for(s = 0 ; s < 13 ; s++){
			for(k = 0 ; k < 4 ; k++){
				double d = encodeXAADPCM(unit, workpad, XA_ADPCM_Table[k], inputStream + (c << 2), null, s, channels, vl);
				if((!s && !k) || d < dmin){
					dmin = d;
					kmin = k;
					smin = s;
				}
			}
		}
		outputStream[4+unit] = cast(ubyte)(smin | (kmin<<4));
		encodeXAADPCM(unit, workpad, XA_ADPCM_Table[kmin], inputStream, outputStream + 16, smin, channels);
	}
	*cast(int*)outputStream = (cast(int*)outputStream)[1];
	(cast(int*)outputStream)[3] = (cast(int*)outputStream)[2];
	//workpad.outputOffset += 16 + (28 * 4);
	//workpad.inputOffset += (28 * 8);
}
/**
 * Dinamically encodes 16 bit stream into 8 bit. Workpad is 32 bytes long, inputStream and outputStream always points to the first byte.
 */
public @nogc void dynamicEncode8BitPCMUnsigned(short* inputStream, ubyte* outputStream, void* workpad){
	uint position = *cast(uint*)(workpad + 8);
	int outputValue = *(inputStream + position);
	outputValue += short.max;
	outputValue /= 256;
	*(outputStream + position) = cast(ubyte)outputValue;
	position++;
	*cast(uint*)(workpad + 8) = position;
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStreamMuLawPCM(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = DecoderWorkpad();
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecodeMuLawPCM(inputStream, &workpad);	
	}
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStreamALawPCM(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = DecoderWorkpad();
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecodeALawPCM(inputStream, &workpad);	
	}
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStreamIMAADPCM(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = DecoderWorkpad();
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecodeIMAADPCM(inputStream, &workpad);	
	}
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStreamDialogicADPCM(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = initializeDialogicADPCMDecoderWorkpad();
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecodeDialogicADPCM(inputStream, &workpad);
	}
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStreamYamahaADPCMA(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = initializeDialogicADPCMDecoderWorkpad;
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecodeYamahaADPCMA(inputStream, &workpad);
		}
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStream8BitPCMUnsigned(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = DecoderWorkpad();
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecode8BitPCMUnsigned(inputStream, &workpad);
		}
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStreamXAADPCM(ubyte* inputStream, short* outputStream, uint length, int channels){
	XAADPCMDecoderWorkpad workpad = XAADPCMDecoderWorkpad();
	for(uint i ; i < length ; i+= 28 * 8){
		blockDecodeXAADPCM(inputStream, outputStream, channels, &workpad);
		inputStream += 16 + (28 * 8);
		outputStream += 28 * 8;
	}
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStreamIMAADPCM(short* inputStream, ubyte* outputStream, uint length){
	EncoderWorkpad workpad = EncoderWorkpad();
	for(uint i ; i < length ; i++){
		dynamicEncodeIMAADPCM(inputStream, outputStream, &workpad);
		//writeln(*inputStream,',',*outputStream,',',workpad.position,',',workpad.d_nMinusOne,',',workpad.stepIndex,',',workpad.stepSize,',',workpad.dW.position,',',workpad.dW.predictor,',',workpad.dW.x_nMinusOne,',',workpad.dW.stepIndex);
		inputStream++;
		outputStream += i&1;
		}
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStreamDialogicADPCM(short* inputStream, ubyte* outputStream, uint length){
	EncoderWorkpad workpad = initializeDialogicADPCMEncoderWorkpad();
	for(uint i ; i < length ; i++){
		dynamicEncodeDialogicADPCM(inputStream, outputStream, &workpad);
		//inputStream++;
		//outputStream += i&1;
		}
	
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStreamYamahaADPCMA(short* inputStream, ubyte* outputStream, uint length){
	EncoderWorkpad workpad = initializeDialogicADPCMEncoderWorkpad();
	for(uint i ; i < length ; i++){
		dynamicEncodeYamahaADPCMA(inputStream, outputStream, &workpad);
		//inputStream++;
		//outputStream += i&1;
		}
	
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStream8BitPCMUnsigned(short* inputStream, ubyte* outputStream, uint length){
	EncoderWorkpad workpad = EncoderWorkpad();
	for(uint i ; i < length ; i++){
		dynamicEncode8BitPCMUnsigned(inputStream, outputStream, &workpad);
		//inputStream++;
		//outputStream++;
		}
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStreamMuLawPCM(short* inputStream, ubyte* outputStream, uint length){
	EncoderWorkpad workpad = EncoderWorkpad();
	for(uint i ; i < length ; i++){
		dynamicEncodeMuLawPCM(inputStream, outputStream, &workpad);
		//inputStream++;
		//outputStream++;
		}
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStreamALawPCM(short* inputStream, ubyte* outputStream, uint length){
	EncoderWorkpad workpad = EncoderWorkpad();
	for(uint i ; i < length ; i++){
		dynamicEncodeALawPCM(inputStream, outputStream, &workpad);
		//inputStream++;
		//outputStream++;
		}
}
/**
 * Encodes a stream of XA ADPCM automatically with multi-channel support
 */
public @nogc void encodeStreamXAADPCM(short* inputStream, ubyte* outputStream, uint length, int channels){
	XAADPCMEncoderWorkpad workpad = XAADPCMEncoderWorkpad();
	uint blockLength = length / channels;
	for(uint i ; i < blockLength ; i += 28 * 8){
		blockEncodeXAADPCM(inputStream,outputStream,channels,&workpad,true);
		//workpad.blockIncrement();
		workpad.vl = workpad.sample_MinusOne;
		outputStream += 16 + (28 * 8);
		inputStream += 28 * 8;
	}
}