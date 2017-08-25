/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.types;

import core.stdc.stdlib;

import libPCM.common;

/**
 * Stores wave data
 */
public class WaveData{
	size_t length;
	CodecType codecType;
	float sampleRate;
	void[] data;
	this(size_t length, float sampleRate, CodecType codecType, void[] data){
		this.length = length;
		this.sampleRate = sampleRate;
		this.codecType = codecType;
		this.data = data;
	}
	this(size_t length, float sampleRate, CodecType codecType, size_t dataLength){
		this.length = length;
		this.sampleRate = sampleRate;
		this.codecType = codecType;
		this.data.length = dataLength;
	}
}
/**
 * Stores *.PCM file header data
 */

public struct PCMHeader{
	public:
		uint length;
		uint length_u;
		CodecType codecType;
		ubyte numOfChannels;
		ubyte aux;				///Stores additional data if needed
		float sampleRate;
		ubyte name_l;			///Actual length = value * 4
		ubyte author_l;			///Actual length = value * 4
		ubyte copyright_l;		///Actual length = value * 4
		ubyte comment_l;		///Actual length = value * 4
	//export char* name, author, copyright, comment;
	//export void* startOfData;		///Data Layout in file: ch1pkg, ch2pkg, ch1pkg, ch2pkg... Null if individual streams used
	//export WaveData** waveData;	///Used for individual streams.
	public this(int length, int length_u, CodecType codecType, ubyte numOfChannels, ubyte aux, float sampleRate){
		this.length = length;
		this.length_u = length_u;
		this.codecType = codecType;
		this.numOfChannels = numOfChannels;
		this.aux = aux;
		this.sampleRate = sampleRate;
	}
}
public struct PCMFile{
	public:
		PCMHeader header;
		char[] name, author, copyright, comment;
		WaveData[] waveData;
		void[] startOfData;
	public @nogc:
		void loadTagData(void* tagData){
			
		}
}
/**
 * *.wav file header
 */
public struct WavHeader{
	public:
		char[4] chunkID;
		uint chunkSize;
		char[4] format;
		char[4] subchunk1ID;
		uint subchunk1Size;
		ushort audioFormat;
		ushort numOfChannels;
		uint sampleRate;
		uint byteRate;
		ushort blockAlign;
		ushort bitsPerSample;
		char[4] subchunk2ID;
		uint subchunk2Size;
	public @nogc:
		this(uint subchunk2Size, ushort audioFormat, ushort numOfChannels, ushort blockAlign, ushort bitsPerSample, uint sampleRate, uint byteRate){
			chunkID = "RIFF";
			format = "WAVE";
			subchunk1ID = "fmt ";
			subchunk2ID = "data";
			subchunk1Size = 16;
			this.subchunk2Size = subchunk2Size;
			this.audioFormat = audioFormat;
			this.numOfChannels = numOfChannels;
			this.blockAlign = blockAlign;
			this.bitsPerSample = bitsPerSample;
			this.sampleRate = sampleRate;
			this.byteRate = byteRate;
		}
}
/**	
 * *.wav file container
 */
public struct WavFile{
	public: 
		WavHeader header;
		WaveData[] waveData;
		void[] startOfData;
	
}