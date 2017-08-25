/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.file;

import core.stdc.stdio;
import core.stdc.stdlib;
import std.stdio;
version(Windows){
	import core.sys.windows.windows;
}else version(Posix){
	import core.stdc.errno;
}

import libPCM.types;
import libPCM.common;
import libPCM.utility;

public:
	/**
	 * Loads a *.pcm file into the memory.
	 */
	PCMFile loadPCMFile(immutable char* name, bool indivStreams = true){
		FILE* inputStream = fopen(name, "rb");
		if(inputStream is null){
			import std.conv;
			version(Windows){
				DWORD errorCode = GetLastError();
			}else version(Posix){
				int errorCode = errno;
			}

			throw new AudioFileException("File access error! Error number: " ~ to!string(errorCode));
		}
		PCMFile file;
		void* buffer;
		char* tagData;
		fread(&file.header, PCMHeader.sizeof, 1, inputStream);
		size_t tagData_l = (file.header.author_l + file.header.comment_l + file.header.copyright_l + file.header.name_l) * 4;
		if(tagData_l){
			tagData = cast(char*)malloc(tagData_l);
			fread(tagData, tagData_l, 1, inputStream);
			file.loadTagData(tagData);
			free(tagData);
		}
		if(indivStreams){
			int wordlength = getWordLength(file.header.codecType);
			size_t sampleSize = (file.header.length * wordlength) / 8;
			sampleSize += (file.header.length * wordlength) % 8 ? 1 : 0;
			//allocate memory for the individual WaveData
			for(int i ; i < file.header.numOfChannels ; i++){
				
				file.waveData ~= new WaveData(file.header.length, file.header.sampleRate, file.header.codecType, sampleSize);
			}
			buffer = malloc(sampleSize * file.header.numOfChannels);
			fread(buffer, sampleSize, file.header.numOfChannels, inputStream);
			size_t bufferOffset;
			switch(wordlength){
				case 16:
					for(size_t i ; i < sampleSize; i++){
						for(int j ; j < file.header.numOfChannels ; j++){
							*cast(ushort*)((file.waveData[j].data.ptr) + i) = *(cast(ushort*)(buffer) + bufferOffset);
							bufferOffset++;
						}
					}
					break;
				case 24, 12:
					for(size_t i ; i < sampleSize; i++){
						for(int j ; j < file.header.numOfChannels ; j++){
							*cast(ubyte*)((file.waveData[j].data.ptr) + i) = *cast(ubyte*)(buffer + bufferOffset);
							bufferOffset++;
							*cast(ubyte*)((file.waveData[j].data.ptr) + i) = *cast(ubyte*)(buffer + bufferOffset);
							bufferOffset++;
							*cast(ubyte*)((file.waveData[j].data.ptr) + i) = *cast(ubyte*)(buffer + bufferOffset);
							bufferOffset++;
						}
					}
					break;
				case 32:
					for(size_t i ; i < sampleSize; i++){
						for(int j ; j < file.header.numOfChannels ; j++){
							*cast(uint*)((file.waveData[j].data.ptr) + i) = *(cast(uint*)(buffer) + bufferOffset);
							bufferOffset++;
						}
					}
					break;
				default:
					for(size_t i ; i < sampleSize; i++){
						for(int j ; j < file.header.numOfChannels ; j++){
							*cast(ubyte*)((file.waveData[j].data.ptr) + i) = *cast(ubyte*)(buffer + bufferOffset);
							bufferOffset++;
						}
					}
					break;
			}
			free(buffer);
		}else{
			int wordlength = getWordLength(file.header.codecType);
			size_t sampleSize = (file.header.length * wordlength) / 8;
			sampleSize += (file.header.length * wordlength) % 8 ? 1 : 0;
			buffer = malloc(sampleSize * file.header.numOfChannels);
			fread(buffer, sampleSize, file.header.numOfChannels, inputStream);
			memCpy(file.startOfData.ptr, buffer, sampleSize * file.header.numOfChannels);
			free(buffer);
		}
		fclose(inputStream);
		return file;
	}
	/**
	 * Loads a *.wav file into the memory.
	 */
	WavFile loadWavFile(immutable char* name, bool indivStreams = true){
		FILE* inputStream = fopen(name, "rb");
		if(inputStream is null){
			import std.conv;
			version(Windows){
				DWORD errorCode = GetLastError();
			}else version(Posix){
				int errorCode = errno;
			}
			throw new AudioFileException("File access error! Error number: " ~ to!string(errorCode));
		}
		WavFile file;
		WavHeader header;
		void* buffer;
		fread(&header, header.sizeof, 1, inputStream);
		file.header = header;
		buffer = malloc(file.header.subchunk2Size);
		fread(buffer, file.header.subchunk2Size, 1, inputStream);
		if(!indivStreams){
			memCpy(file.startOfData.ptr, buffer, file.header.subchunk2Size);
			free(buffer);
			return file;
		}
		file.waveData.length = file.header.numOfChannels;
		if(file.header.numOfChannels == 1){
			CodecType codecType;
			if(file.header.bitsPerSample == 8 && file.header.audioFormat == 1){
				codecType = CodecType.UNSIGNED8BIT;
			}else if(file.header.bitsPerSample == 16 && file.header.audioFormat == 1){
				codecType = CodecType.SIGNED16BIT;
			}
			file.waveData[0] = new WaveData(file.header.subchunk2Size * file.header.bitsPerSample / 8, file.header.sampleRate, codecType, file.header.subchunk2Size);
			memCpy(buffer, file.waveData[0].data.ptr, file.header.subchunk2Size);
		}else if(file.header.numOfChannels == 2){
			CodecType codecType;
			if(file.header.bitsPerSample == 8 && file.header.audioFormat == 1){
				codecType = CodecType.UNSIGNED8BIT;
			}else if(file.header.bitsPerSample == 16 && file.header.audioFormat == 1){
				codecType = CodecType.SIGNED16BIT;
			}
			file.waveData[0] = new WaveData(file.header.subchunk2Size * file.header.bitsPerSample / 16, file.header.sampleRate, codecType, file.header.subchunk2Size);
			file.waveData[1] = new WaveData(file.header.subchunk2Size * file.header.bitsPerSample / 16, file.header.sampleRate, codecType, file.header.subchunk2Size);
			size_t bufferOffset;
			if(file.header.bitsPerSample == 8 && file.header.audioFormat == 1){
				for(size_t i ; i < file.waveData[0].length; i++){
					for(int j ; j < file.header.numOfChannels ; j++){
						*cast(ubyte*)(file.waveData[j].data.ptr + i) = *cast(ubyte*)(buffer + bufferOffset);
						bufferOffset++;
					}
				}
			}else if(file.header.bitsPerSample == 16 && file.header.audioFormat == 1){
				for(size_t i ; i < file.waveData[0].length ; i++){
					for(int j ; j < file.header.numOfChannels ; j++){
						*cast(ushort*)(file.waveData[j].data.ptr + i) = *cast(ushort*)(buffer + bufferOffset);
						bufferOffset++;
					}
				}
			}
		}
		fclose(inputStream);
		free(buffer);
		return file;
	}
	/**
	 * Stores a *.wav file.
	 */
	void storeWavFile(WavFile file, immutable char* name){
		FILE* outputStream = fopen(name, "wb");
		if(outputStream is null){
			import std.conv;
			version(Windows){
				DWORD errorCode = GetLastError();
			}else version(Posix){
				int errorCode = errno;
			}
			throw new AudioFileException("File access error! Error number: " ~ to!string(errorCode));
		}
		fwrite(&(file.header), WavHeader.sizeof, 1, outputStream);
		if(file.startOfData.length){
			fwrite(file.startOfData.ptr, file.startOfData.length, 1, outputStream);
		}else if(file.waveData.length == 1){
			fwrite(file.waveData[0].data.ptr, file.waveData[0].data.length, 1, outputStream);
		}
		fclose(outputStream);
	}
	/**
	 * Stores a *.pcm file.
	 */
	void storePCMFile(PCMFile file, immutable char* name){
		FILE* outputStream = fopen(name, "wb");
		if(outputStream is null){
			import std.conv;
			version(Windows){
				DWORD errorCode = GetLastError();
			}else version(Posix){
				int errorCode = errno;
			}
			throw new AudioFileException("File access error! Error number: " ~ to!string(errorCode));
		}
		fwrite(&(file.header), PCMHeader.sizeof, 1, outputStream);
		if(file.startOfData.length){
			fwrite(file.startOfData.ptr, file.startOfData.length, 1, outputStream);
		}else if(file.waveData.length == 1){
			fwrite(file.waveData[0].data.ptr, file.waveData[0].data.length, 1, outputStream);
		}
		fclose(outputStream);
	}