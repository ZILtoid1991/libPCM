/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.utility;

@nogc package:
	/**
	 * Converts a floating point value to integer
	 */
	int floatToInt(float input){
		int result;
		asm @nogc{
			fld		input;
			frndint	;
			fist	result;
		}
		return result;
	}
	/**
	 * Converts a floating point value to integer
	 */
	int doubleToInt(double input){
		int result;
		asm @nogc{
			fld		input;
			frndint	;
			fist	result;
		}
		return result;
	}
	/**
	 * Copies a part of memory.
	 */
	void memCpy(void* src, void* dest, size_t length){
		if(!length) return;
		asm @nogc{
			mov		ECX, length;
			mov		ESI, src;
			mov		EDI, dest;

			cmp		ECX, 16;
			jl		copy1byte;

		copy16byte:
			movups	XMM0, [ESI];
			movups	[EDI], XMM0;
			add		ESI, 16;
			add		EDI, 16;
			sub		ECX, 16;
			cmp		ECX, 16;
			jge		copy16byte;
			cmp		ECX, 0;
			jz		endOfAlgorithm;

		copy1byte:
			mov		AL, [ESI];
			mov		[EDI], AL;
			inc		ESI;
			inc		EDI;
			dec		ECX;
			cmp		ECX, 0;
			jnz		copy1byte;
		endOfAlgorithm:
			;
		}
	}
	int signExtend(int val, uint bits){
		int workPad;
		uint shift = int.sizeof - bits;
		*cast(uint*)&workPad = cast(uint)(val<<shift);
		return workPad;
	}