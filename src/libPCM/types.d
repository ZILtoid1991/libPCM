/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.types;

import core.stdc.stdlib;
import std.bitmanip;

import libPCM.common;

/**
 * Stores wave data
 */
public class WaveData{
	size_t length;
	CodecType codecType;
	float sampleRate;
	void[] data;
	ubyte channels;
	this(size_t length, float sampleRate, CodecType codecType, void[] data, ubyte channels = 1){
		this.length = length;
		this.sampleRate = sampleRate;
		this.codecType = codecType;
		this.data = data;
		this.channels = channels;
	}
	this(size_t length, float sampleRate, CodecType codecType, size_t dataLength, ubyte channels = 1){
		this.length = length;
		this.sampleRate = sampleRate;
		this.codecType = codecType;
		this.data.length = dataLength * channels;
		this.channels = channels;
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
		WaveData data;
	public @nogc:
		void loadTagData(void* tagData){
			
		}
}
/**
 * *.wav file header DEPRECATED
 */
public @nogc struct WavHeader{
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
 * Split mode Wav Header, first part. Split mode allows loading extra data put between the two subchunks.
 */
public @nogc struct WavHeaderMain{
	public:
		char[4] chunkID;
		uint chunkSize;
		char[4] format;
	public @nogc this(uint chunkSize){
		chunkID = "RIFF";
		format = "WAVE";
		this.chunkSize = chunkSize;
	}
}
/**
 * Split mode Wav Header, Subchunk1.
 */
public @nogc struct WavHeaderSubchunk1{
	public:
		char[4] subchunk1ID;
		uint subchunk1Size;
		ushort audioFormat;
		ushort numOfChannels;
		uint sampleRate;
		uint byteRate;
		ushort blockAlign;
		ushort bitsPerSample;
	public @nogc this(ushort audioFormat, ushort numOfChannels, ushort blockAlign, ushort bitsPerSample, uint sampleRate, uint byteRate, uint subchunk1Size = 16){
		subchunk1ID = "fmt ";
		//subchunk1Size = 16;
		this.subchunk1Size = subchunk1Size;
		this.audioFormat = audioFormat;
		this.numOfChannels = numOfChannels;
		this.blockAlign = blockAlign;
		this.bitsPerSample = bitsPerSample;
		this.sampleRate = sampleRate;
		this.byteRate = byteRate;
	}
}
/**
 * Split mode Wav Header, Subchunk2.
 */
public @nogc struct WavHeaderSubchunk2{
	public:
		char[4] subchunk2ID;
		uint subchunk2Size;
	public @nogc this(uint subchunk2Size){
		subchunk2ID = "data";
		this.subchunk2Size = subchunk2Size;
	}
}
/**	
 * *.wav file container. Currently doesn't support extra data stored between subchunk1 and subchunk2.
 */
public class WavFile{
	public: 
		WavHeaderMain riff;
		WavHeaderSubchunk1 subchunk1;
		WavHeaderSubchunk2 subchunk2;
		WaveData data;
	public this(){
		riff = WavHeaderMain();
		subchunk1 = WavHeaderSubchunk1();
		subchunk2 = WavHeaderSubchunk2();
	}
}
/**
 * XA ADPCM file header. Please note that certain containers can specify sample rates different than the standard,
 * which will break the compatibility.
 */
public @nogc struct XAADPCMHeader{
	public ubyte fileNumber;
	public ubyte channelNumber;
	//public ubyte subMode;
	//public ubyte codingInfo;
	mixin(bitfields!(
			bool, "EOR" , 1,
			bool, "Video", 1,
			bool, "Audio", 1,
			bool, "Data", 1,
			bool, "Trigger", 1,
			bool, "Form", 1,
			bool, "RealTimeSector", 1,
			bool, "EOF", 1,
			uint, "MonoStereo", 2,
			uint, "SampleRate", 2,
			uint, "BitsPerSample", 2,
			bool, "Emphasis", 1,
			bool, "Reserved", 1,
			));
	
	public @nogc this(ubyte fileNumber, ubyte channelNumber){
		
	}
}
public class AIFFHeader{
	public struct Form{
		public char[4] chunkID;
		public uint fileSize;
		public char[4] fileType;
	}
	public struct Comm{
		public char[4] chunkID;
		public uint chunkSize;
		public ushort numOfChannels;
		public ushort numOfFramesL;
		public ushort numOfFramesH;
		public ushort bitsPerSample;
		public real sampleRate;
	}
	public struct Ssnd{
		public char[4] chunkID;
		public uint chunkSize;
		public uint offset;		///Comment Length
		public uint blockSize;
	}
	string comment;
}