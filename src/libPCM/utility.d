/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.utility;
import core.stdc.string;

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
		memcpy(dest, src, length);
	}
	int signExtend(int val, uint bits){
		int workPad;
		uint shift = cast(uint)int.sizeof - bits;
		*cast(uint*)&workPad = cast(uint)(val<<shift);
		return workPad;
	}