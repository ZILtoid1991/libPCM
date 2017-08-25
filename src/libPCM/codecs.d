/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.codecs;

//import std.stdio;

package static immutable byte[16] ADPCM_IndexTable = 
			[-1, -1, -1, -1, 2, 4, 6, 8, 
			-1, -1, -1, -1, 2, 4, 6, 8];
package static immutable byte[4] ADPCM_IndexTable_2Bit = 
			[-1, 2,
			-1, 2];
package static immutable ushort[49] DIALOGIC_ADPCM_StepTable = [16,17,19,21,23,25,28,31,34,37,41,45,50,55,
			60,66,73,80,88,97,107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,598,658,724,796,876,963,1060,1166,1282,1411,1552];
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
/*package static immutable int[27] CompactADPCM_StepTable = 
			[4, 5, 5, 6, 6, 7, 8, 8, 9, 10, 11, 12, 13, 15, 16, 18,
			20, 22, 24, 26, 29, 32, 35, 38, 42, 46, 51];*/

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
/**
 * Dinamically decodes an IMA ADPCM stream. Workpad is 16 bytes long, inputStream always points to the first byte.
 */
public @nogc short dynamicDecodeIMAADPCM(ubyte* inputStream, void* workpad){
	int stepIndex = *cast(int*)(workpad);
	int x_nMinusOne = *cast(int*)(workpad + 4);
	uint position = *cast(uint*)(workpad + 8);
	uint stepSize;
	int d_n;
	ubyte index;
	//get the next index
	if(position & 1)
		index = *(inputStream + (position>>1)) & 0x0F;
	else
		index = (*(inputStream + (position>>1)))>>4;
	//calculate the next step size
	stepIndex += ADPCM_IndexTable[index];
	//clamp the index data within the steptable's range
	if(stepIndex < 0)
		stepIndex = 0;
	else if(stepIndex > 88)
		stepIndex = 88;
	stepSize = IMA_ADPCM_StepTable[stepIndex];
	
	//d_n = ((stepSize) * (index & 0b0100)>>2) + ((stepSize/2) * (index & 0b0010)>>1) + ((stepSize/4) * index & 0b0001) + (stepSize/8);
	d_n = ((stepSize) * (index & 0b0100)>>2) + ((stepSize>>1) * (index & 0b0010)>>1) + ((stepSize>>2) * index & 0b0001) + (stepSize>>4);

	if(index & 0b1000)
		d_n *= -1;
	//adding positive feedback value
	d_n += x_nMinusOne;

	position++;
	*cast(int*)(workpad + 8) = position;
	*cast(int*)(workpad) = stepIndex;
	*cast(int*)(workpad + 4) = d_n;
	return cast(short)d_n;
}
/**
 * Dinamically decodes an Dialogic ADPCM stream. Workpad is 16 bytes long, inputStream always points to the first byte.
 */
public @nogc short dynamicDecodeDialogicADPCM(ubyte* inputStream, void* workpad){
	int stepIndex = *cast(int*)(workpad);
	int x_nMinusOne = *cast(int*)(workpad + 4);
	uint position = *cast(uint*)(workpad + 8);
	uint stepSize;
	int d_n;
	ubyte index;
	//get the next index
	if(position & 1)
		index = *(inputStream + (position>>1)) & 0x0F;
	else
		index = (*(inputStream + (position>>1)))>>4;
	//calculate the next step size
	stepIndex += ADPCM_IndexTable[index];
	//clamp the index data within the steptable's range
	if(stepIndex < 0)
		stepIndex = 0;
	else if(stepIndex > 48)
		stepIndex = 48;
	stepSize = DIALOGIC_ADPCM_StepTable[stepIndex];
	
	d_n = ((stepSize) * (index & 0b0100)>>2) + ((stepSize>>1) * (index & 0b0010)>>1) + ((stepSize>>2) * index & 0b0001) + (stepSize>>4);

	if(index & 0b1000)
		d_n *= -1;
	//adding positive feedback value
	d_n += x_nMinusOne;

	position++;
	*cast(int*)(workpad + 8) = position;
	*cast(int*)(workpad) = stepIndex;
	*cast(int*)(workpad + 4) = d_n;
	return cast(short)(d_n * 16);
}
/**
 * Initializes the index at 16 for Dialogic ADPCM codecs.
 */
public @nogc uint[4] initializeDialogicADPCMDecoderWorkpad(){
	return [16,0,0,0];
}
/**
 * Appends 8 bit unsigned PCM to 16 bit signed PCM. Workpad is 16 bytes long, inputStream always points to the first byte.
 */
public @nogc short dynamicDecode8BitPCMUnsigned(ubyte* inputStream, void* workpad){
	uint* position = cast(uint*)(workpad + 8);
	int output = *(inputStream + *position);
	output += byte.min;
	output *= 256;

	(*position)++;
	return cast(short)(output);
}
/**
 * Dinamically encodes a stream with IMA ADPCM. Workpad is 32 bytes long, inputStream and outputStream always points to the first byte.
 */
public @nogc void dynamicEncodeIMAADPCM(short* inputStream, ubyte* outputStream, void* workpad){
	int x_nMinusOne = *cast(int*)(workpad + 4);
	uint position = *cast(uint*)(workpad + 8);
	uint stepSize = *cast(uint*)(workpad + 12);
	ubyte index;

	int d_n = *(inputStream + position) - x_nMinusOne; //applying negative feedback to x_n
	if(d_n < 0){ 
		d_n *=-1; //get the absolute value of d_n
		index = 0b1000;	//set the sign if d_n is negative
	}
	if(d_n >= stepSize){
		index |= 0b0100;
		d_n -= stepSize;
	}
	stepSize >>= 1;
	if(d_n >= stepSize){
		index |= 0b0010;
		d_n -= stepSize;
	}
	stepSize >>= 1;
	if(d_n >= stepSize)
		index |= 0b0001;
	
	//calculate next step size
	int stepIndex = *cast(int*)(workpad);
	stepIndex += ADPCM_IndexTable[index];
	//clamp the index data within the steptable's range
	if(stepIndex < 0)
		stepIndex = 0;
	else if(stepIndex > 88)
		stepIndex = 88;
	*cast(int*)(workpad + 12) = IMA_ADPCM_StepTable[stepIndex];
	*cast(int*)(workpad) = stepIndex;

	//write the new index into the outputStream
	if(position & 1)
		*(outputStream + (position>>1)) |= index;
	else
		*(outputStream + (position>>1)) = cast(ubyte)(index<<4);
	
	//calculate new x_nMinusOne
	*cast(int*)(workpad + 4) = dynamicDecodeIMAADPCM(outputStream, workpad+16);

	position++;
	*cast(int*)(workpad + 8) = position;
}
/**
 * Dinamically encodes a stream with Dialogic ADPCM. Workpad is 32 bytes long, inputStream and outputStream always points to the first byte.
 */
public @nogc void dynamicEncodeDialogicADPCM(short* inputStream, ubyte* outputStream, void* workpad){
	int x_nMinusOne = *cast(int*)(workpad + 4);
	uint position = *cast(uint*)(workpad + 8);
	uint stepSize = *cast(uint*)(workpad + 12);
	ubyte index;

	int d_n = *(inputStream + position) - x_nMinusOne; //applying negative feedback to x_n
	d_n /= 16;
	if(d_n < 0){ 
		d_n *=-1; //get the absolute value of d_n
		index = 0b1000;	//set the sign if d_n is negative
	}
	if(d_n >= stepSize){
		index |= 0b0100;
		d_n -= stepSize;
	}
	stepSize >>= 1;
	if(d_n >= stepSize){
		index |= 0b0010;
		d_n -= stepSize;
	}
	stepSize >>= 1;
	if(d_n >= stepSize)
		index |= 0b0001;
	
	//calculate next step size
	int stepIndex = *cast(int*)(workpad);
	stepIndex += ADPCM_IndexTable[index];
	//clamp the index data within the steptable's range
	if(stepIndex < 0)
		stepIndex = 0;
	else if(stepIndex > 48)
		stepIndex = 48;
	*cast(int*)(workpad + 12) = DIALOGIC_ADPCM_StepTable[stepIndex];
	*cast(int*)(workpad) = stepIndex;

	//write the new index into the outputStream
	if(position & 1)
		*(outputStream + (position>>1)) |= index;
	else
		*(outputStream + (position>>1)) = cast(ubyte)(index<<4);
	
	//calculate new x_nMinusOne
	*cast(int*)(workpad + 4) = dynamicDecodeDialogicADPCM(outputStream, workpad+16);

	position++;
	*cast(int*)(workpad + 8) = position;
}
/**
 * Initializes the index at 16 for Dialogic ADPCM codecs.
 */
public @nogc uint[8] initializeDialogicADPCMEncoderWorkpad(){
	return [16,0,0,0,16,0,0,0];
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
	uint[4] workpad;
	for(uint i ; i < length ; i++)
		*(outputStream + i) = dynamicDecodeIMAADPCM(inputStream, workpad.ptr);
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStreamDialogicADPCM(ubyte* inputStream, short* outputStream, uint length){
	uint[4] workpad = initializeDialogicADPCMDecoderWorkpad;
	for(uint i ; i < length ; i++)
		*(outputStream + i) = dynamicDecodeDialogicADPCM(inputStream, workpad.ptr);
}
/**
 * Decodes a preexisting stream automatically.
 */
public @nogc void decodeStream8BitPCMUnsigned(ubyte* inputStream, short* outputStream, uint length){
	uint[4] workpad;
	for(uint i ; i < length ; i++)
		*(outputStream + i) = dynamicDecode8BitPCMUnsigned(inputStream, workpad.ptr);
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStreamIMAADPCM(short* inputStream, ubyte* outputStream, uint length){
	uint[8] workpad;
	for(uint i ; i < length ; i++)
		dynamicEncodeIMAADPCM(inputStream, outputStream, workpad.ptr);
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStreamDialogicADPCM(short* inputStream, ubyte* outputStream, uint length){
	uint[8] workpad = initializeDialogicADPCMEncoderWorkpad;
	for(uint i ; i < length ; i++)
		dynamicEncodeDialogicADPCM(inputStream, outputStream, workpad.ptr);
		//writeln(workpad);
	
}
/**
 * Encodes a preexisting stream automatically.
 */
public @nogc void encodeStream8BitPCMUnsigned(short* inputStream, ubyte* outputStream, uint length){
	uint[8] workpad;
	for(uint i ; i < length ; i++)
		dynamicEncode8BitPCMUnsigned(inputStream, outputStream, workpad.ptr);
}