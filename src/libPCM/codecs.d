/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.codecs;

import std.stdio;

import core.stdc.math;
import libPCM.utility;

package static immutable byte[16] ADPCM_IndexTable = 
			[-1, -1, -1, -1, 2, 4, 6, 8, 
			 -1, -1, -1, -1, 2, 4, 6, 8];	///For IMA and Dialogic ADPCM
package static immutable byte[16] Yamaha_ADPCM_A_IndexTable =
			[-1, -1, -1, -1, 2, 5, 7, 9, 
			 -1, -1, -1, -1, 2, 5, 7, 9];	///For the Yamaha ADPCM A found in YM2610 and probably other chips
package static immutable byte[16] Yamaha_ADPCM_DiffLookup =
			[1,  3,  5,  7,  9,  11,  13,  15,
			-1, -3, -5, -7, -9, -11, -13, -15];
package static immutable byte[4] ADPCM_IndexTable_2Bit = 
			[-1, 2,
			 -1, 2];
package static immutable byte[8] ADPCM_IndexTable_3Bit = 
			[-1, -1, 2, 4,
			 -1, -1, 2, 4,];
package static immutable byte[32] ADPCM_IndexTable_5Bit = 
			[-1, -1, -1, -1, -1, -1, -1, -1, 1, 2, 4, 6, 8, 10, 13, 16
			 -1, -1, -1, -1, -1, -1, -1, -1, 1, 2, 4, 6, 8, 10, 13, 16];
package static immutable byte[2][5] XA_ADPCM_Table =
			[[0,0],
			[60,0],
			[115,-52],
			[98,-55],
			[112,-60]];
package static immutable ushort[49] DIALOGIC_ADPCM_StepTable = 
			[16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55,
			60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190,	
			209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598,
			658, 724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552];		///Most OKI and Yamaha chips seems to use this step-table
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


/*
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
	uint position;
	int stepIndex;
	int x_nMinusOne;
	int predictor;
	public @nogc this(uint position, int stepIndex, int x_nMinusOne){
		this.position = position;
		this.stepIndex = stepIndex;
		this.x_nMinusOne = x_nMinusOne;
	}
}
public @nogc struct EncoderWorkpad{
	uint position;
	uint stepSize;
	int stepIndex;
	int d_nMinusOne;
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
 * Dinamically decodes an IMA ADPCM stream.
 */
public @nogc short dynamicDecodeIMAADPCM(ubyte* inputStream, DecoderWorkpad* workpad){
	uint stepSize;
	int d_n;
	ubyte index;
	//get the next index
	if(workpad.position & 1)
		index = *(inputStream) & 0x0F;
	else
		index = (*(inputStream))>>4;
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
		index = *(inputStream) & 0x0F;
	else
		index = (*(inputStream))>>4;
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
 * Dynamically decodes a Yamaha ADPCM A stream. Workpad is 16 bytes long, inputStream always points to the first byte.
 */
public @nogc short dynamicDecodeYamahaADPCMA(ubyte* inputStream, DecoderWorkpad* workpad){
	uint stepSize;
	int d_n;
	ubyte index;
	//get the next index
	if(workpad.position & 1)
		index = *(inputStream) & 0x0F;
	else
		index = (*(inputStream))>>4;
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
 * Appends 8 bit unsigned PCM to 16 bit signed PCM. Workpad is 16 bytes long, inputStream always points to the first byte.
 */
public @nogc short dynamicDecode8BitPCMUnsigned(ubyte* inputStream, DecoderWorkpad* workpad){
	int output = *(inputStream + workpad.position);
	output += byte.min;
	output *= 256;

	workpad.position++;
	return cast(short)(output);
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
 * Dinamically encodes a stream with IMA ADPCM. Workpad is 32 bytes long, inputStream and outputStream always points to the first byte.
 */
public @nogc void dynamicEncodeIMAADPCM(short* inputStream, ubyte* outputStream, EncoderWorkpad* workpad){
	//int x_nMinusOne = *cast(int*)(workpad + 4);
	//uint position = *cast(uint*)(workpad + 8);
	//uint stepSize = *cast(uint*)(workpad + 12);
	ubyte index;

	int d_n = *(inputStream) - workpad.d_nMinusOne; //applying negative feedback to x_n
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

	int d_n = *(inputStream) - workpad.d_nMinusOne; //applying negative feedback to x_n
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

	int d_n = *(inputStream) - workpad.d_nMinusOne; //applying negative feedback to x_n
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
public @nogc void decodeStreamIMAADPCM(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = DecoderWorkpad();
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecodeIMAADPCM(inputStream + (i>>1), &workpad);
		//writeln(inputStream,',',outputStream,',',workpad.position,',',workpad.predictor,',',workpad.stepIndex,',',workpad.x_nMinusOne);
		
		}
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStreamDialogicADPCM(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = initializeDialogicADPCMDecoderWorkpad();
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecodeDialogicADPCM(inputStream + (i>>1), &workpad);
		
		}
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStreamYamahaADPCMA(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = initializeDialogicADPCMDecoderWorkpad;
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecodeYamahaADPCMA(inputStream + (i>>1), &workpad);
		}
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStream8BitPCMUnsigned(ubyte* inputStream, short* outputStream, uint length){
	DecoderWorkpad workpad = DecoderWorkpad();
	for(uint i ; i < length ; i++){
		*(outputStream + i) = dynamicDecode8BitPCMUnsigned(inputStream + i, &workpad);
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
		inputStream++;
		outputStream += i&1;
		}
	
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStreamYamahaADPCMA(short* inputStream, ubyte* outputStream, uint length){
	EncoderWorkpad workpad = initializeDialogicADPCMEncoderWorkpad();
	for(uint i ; i < length ; i++){
		dynamicEncodeYamahaADPCMA(inputStream, outputStream, &workpad);
		inputStream++;
		outputStream += i&1;
		}
	
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStream8BitPCMUnsigned(short* inputStream, ubyte* outputStream, uint length){
	EncoderWorkpad workpad = EncoderWorkpad();
	for(uint i ; i < length ; i++){
		dynamicEncode8BitPCMUnsigned(inputStream, outputStream, &workpad);
		inputStream++;
		outputStream++;
		}
}
/**
 * Encodes a stream of XA ADPCM automatically with multi-channel support
 */
public @nogc void encodeStreamXAADPCM(short* inputStream, ubyte* outputStream, uint length, int channels){
	XAADPCMEncoderWorkpad workpad = XAADPCMEncoderWorkpad();
	uint blockLength = length / channels;
	for(uint i ; i < blockLength ; i++){
		blockEncodeXAADPCM(inputStream,outputStream,channels,&workpad,true);
		//workpad.blockIncrement();
		workpad.vl = workpad.sample_MinusOne;
		outputStream += 16 + (28 * 8);
		inputStream += 28 * 8;
	}
}