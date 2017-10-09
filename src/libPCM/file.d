/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.file;

import core.stdc.stdio;
import core.stdc.stdlib;
import std.stdio;
import std.conv;
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
	PCMFile loadPCMFile(immutable char* name){
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
		size_t sampleSize, sampleLength;
		version(x64){
			sampleLength = (file.header.length + file.header.length_h<<32);
			sampleSize = sampleLength * (getWordLength(file.header.codecType)/8);
		}else{
			sampleLength = file.header.length;
			sampleSize = sampleLength * (getWordLength(file.header.codecType)/8);
		}

		file.data = new WaveData(sampleLength, file.header.sampleRate, file.header.codecType, sampleSize, file.header.numOfChannels);

		fread(file.data.data.ptr, sampleSize, 1, inputStream);

		fclose(inputStream);
		return file;
	}
	/**
	 * Loads a *.wav file into the memory.
	 */
	WavFile loadWavFile(immutable char* name){
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
		WavFile file = new WavFile;
		void* buffer;
		fread(&file.riff, file.riff.sizeof, 1, inputStream);
		fread(&file.subchunk1, file.subchunk1.sizeof, 1, inputStream);
		fread(&file.subchunk2, file.subchunk2.sizeof, 1, inputStream);

		uint sampleLength = file.subchunk2.subchunk2Size / file.subchunk1.numOfChannels / 
							(getWordLength(fromWAVAudioFormat(file.subchunk1.audioFormat, file.subchunk1.bitsPerSample)) / 8);
		file.data = new WaveData(sampleLength, to!float(file.subchunk1.sampleRate), fromWAVAudioFormat(file.subchunk1.audioFormat, file.subchunk1.bitsPerSample), 
							file.subchunk2.subchunk2Size, cast(ubyte)file.subchunk1.numOfChannels);
		fread(file.data.data.ptr, file.subchunk2.subchunk2Size,1 , inputStream);
		
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
		fwrite(&(file.riff), WavHeaderMain.sizeof, 1, outputStream);
		fwrite(&(file.subchunk1), WavHeaderSubchunk1.sizeof, 1, outputStream);
		fwrite(&(file.subchunk2), WavHeaderSubchunk2.sizeof, 1, outputStream);
		fwrite(file.data.data.ptr, file.data.data.length, 1, outputStream);
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
		fwrite(file.data.data.ptr, file.data.data.length, 1, outputStream);
		
		fclose(outputStream);
	}