import std.stdio;
import std.conv;
import std.string;
import std.uni;
import std.path;
//import core.sys.windows.windows;

import libPCM;

void printHelp(){
	writeln("Usable arguments:");
	writeln(
		"--help\n
Displays this message.\n
\n
    --input [PATH] [SPECIFIERS]\n
Specifies the input file.\n
\n
    type [FILETYPE]\n
Specifies the type of the file. If not present it's detected automatically from the file extension. Use 'type custom' for custom specification\n
\n
    sampleRate [FLOAT]\n
Specifies a sample rate.\n
\n
    codec [CODECTYPE]\n
Specifies the codec.\n
\n
    startFrom [UINT]\n
Specifies where the data begins.\n
\n
    length [UINT]\n
Specifies the length of the data.\n
\n
    --output [PATH] [SPECIFIERS]\n
Specifies the output file.\n 
\n
    type [FILETYPE]\n
Specifies the type of the output file. If not present, it'll be the same as the input.\n
\n
    sampleRate [FLOAT]\n
Specifies the output sample rate of the file. If not present, it'll be the same as the input.\n
\n
    codec [CODECTYPE]\n
Specifies the codec for the output file. If not present, it'll be the same as the input.\n
\n
    --resampling [METHOD]\n
Specifies the resampling method.\n
\n
---------------------------------------
        SUPPORTED FILE FORMATS:
pcm, wav
        SUPPORTED CODECS:
8bitsigned, 16bitsigned, 24bitsigned, 32bitsigned, 8bitunsigned, 12bitunsigned, 16bitunsigned, 24bitunsigned, 32bitunsigned, IMA_ADPCM, Dialogic_ADPCM, Compact_ADPCM
		 ");
}

int main(string[] argv)
{
	//LibPCMLoader.loadLibrary();
    writeln("PCM File Converter by Laszlo Szeremi");
	if(argv.length == 1){
		printHelp();
		return 0;
	}	
	int state, secState, resampling;
	size_t lengthIn, offsetIn;
	float samplerateIn, samplerateOut;
	string inputFilename, outputFilename, typeIn, typeOut;
	CodecType cIn, cOut = CodecType.NULL;
	foreach(argument; argv){
		if(state == 0){
			switch(argument){
				case "--input":
					state = 1;
					break;
				case "--output":
					state = 2;
					break;
				case "--help":
					printHelp();
					return 0;
					break;
				case "--resampling":
					state = 3;
					break;
				default:
					switch(secState){
						case 1:
							switch(argument){
								case "type":
									state = 4;
									break;
								case "sampleRate":
									state = 5;
									break;
								case "codec":
									state = 6;
									break;
								case "startFrom":
									state = 7;
									break;
								case "length":
									state = 8;
									break;
								default:
									break;
							}
							break;
						case 2:
							switch(argument){
								case "type":
									state = 9;
									break;
								case "sampleRate":
									state = 10;
									break;
								case "codec":
									state = 11;
									break;
								
								default:
									break;
							}
							break;
						default:
							break;
					}
					break;
			}
		}else{
			switch(state){
				case 1:
					inputFilename = argument;
					secState = 1;
					break;
				case 2:
					outputFilename = argument;
					secState = 2;
					break;
				case 3:
					switch(argument){
						case "linear":
							resampling = 1;
							break;
						case "polynomial":
							resampling = 2;
							break;
						default:
							break;
					}
					break;
				case 4:
					break;
				case 5:
					samplerateIn = to!float(argument);
					break;
				case 6:
					cIn = parseCodecType(argument);
					break;
				case 7:
					offsetIn = to!int(argument);
					break;
				case 8:
					lengthIn = to!int(argument);
					break;
				case 9:
					break;
				case 10:
					samplerateOut = to!float(argument);
					break;
				case 11:
					cOut = parseCodecType(argument);
					break;
				default:
					break;
			}
			state = 0;
		}
	}
	
	if(inputFilename.length && outputFilename.length){
		if(!typeIn.length){
			typeIn = extension(inputFilename);
		}
		
		if(!typeOut.length){
			typeOut = extension(outputFilename);
		}
		WaveData waveIn, waveOut;
		typeIn = toLower(typeIn);
		typeOut = toLower(typeOut);
		switch(typeIn){
			case "wav", ".wav":
				WavFile f = loadWavFile(toStringz(inputFilename));
				waveIn = f.waveData[0];
				break;
			case "pcm", ".pcm":
				PCMFile f = loadPCMFile(toStringz(inputFilename));
				waveIn = f.waveData[0];
				break;
			default:
				writeln("Input type is unspecified or unknown!");
				return 0;
				break;
		}
		cIn = waveIn.codecType;
		if(cOut == CodecType.NULL) cOut = cIn;
		if(samplerateIn == 0) samplerateIn = waveIn.sampleRate;
		if(samplerateOut == 0) samplerateOut = samplerateIn;
		if(cIn == cOut){
			waveOut = waveIn;
		}else{
			
			void[] intermediateWaveData;
			intermediateWaveData.length = waveIn.length * 2;
			switch(cIn){
				/*case CodecType.SIGNED8BIT:
					decodeStream8bitPCMSigned(waveIn.data.ptr, intermediateWaveData.ptr, waveIn.length);
					break;*/
				case CodecType.SIGNED16BIT:
					//intermediateWaveData.length = waveIn.length * 2;
					intermediateWaveData=waveIn.data;
					break;
				case CodecType.UNSIGNED8BIT:
					//intermediateWaveData.length = waveIn.length;
					decodeStream8BitPCMUnsigned(cast(ubyte*)waveIn.data.ptr, cast(short*)intermediateWaveData.ptr, waveIn.length);
					break;
				/*case CodecType.UNSIGNED12BIT:
					decodeStream12bitPCMUnsigned(waveIn.data.ptr, intermediateWaveData.ptr, waveIn.length);
					break;
				case CodecType.UNSIGNED16BIT:
					decodeStream16bitPCMUnsigned(waveIn.data.ptr, intermediateWaveData.ptr, waveIn.length);
					break;*/
				case CodecType.IMA_ADPCM:
					decodeStreamIMAADPCM(cast(ubyte*)waveIn.data.ptr, cast(short*)intermediateWaveData.ptr, waveIn.length);
					break;
				case CodecType.DIALOGIC_ADPCM:
					decodeStreamDialogicADPCM(cast(ubyte*)waveIn.data.ptr, cast(short*)intermediateWaveData.ptr, waveIn.length);
					break;
				/*case CodecType.COMPACT_ADPCM:
					decodeStreamCompactADPCM(waveIn.data.ptr, intermediateWaveData.ptr, waveIn.length);
					break;*/
				default:
					break;
			}
			waveOut = new WaveData(waveIn.length, samplerateOut, cOut, (getWordLength(cOut) * waveIn.length) / 8);
			
			switch(cOut){
				/*case CodecType.SIGNED8BIT:
					encodeStream8BitPCMSigned(intermediateWaveData.ptr, waveOut.data.ptr, waveOut.length);
					break;*/
				case CodecType.SIGNED16BIT:
					waveOut.data = intermediateWaveData;
					break;
				case CodecType.UNSIGNED8BIT:
					encodeStream8BitPCMUnsigned(cast(short*)intermediateWaveData.ptr, cast(ubyte*)waveOut.data.ptr, waveOut.length);
					break;
				/*case CodecType.UNSIGNED12BIT:
					encodeStream12BitPCMUnsigned(intermediateWaveData.ptr, waveOut.data.ptr, waveOut.length);
					break;
				case CodecType.UNSIGNED16BIT:
					encodeStream16BitPCMUnsigned(intermediateWaveData.ptr, waveOut.data.ptr, waveOut.length);
					break;*/
				case CodecType.IMA_ADPCM:
					encodeStreamIMAADPCM(cast(short*)intermediateWaveData.ptr, cast(ubyte*)waveOut.data.ptr, waveOut.length);
					break;
				case CodecType.DIALOGIC_ADPCM:
					encodeStreamDialogicADPCM(cast(short*)intermediateWaveData.ptr, cast(ubyte*)waveOut.data.ptr, waveOut.length);
					break;
				/*case CodecType.COMPACT_ADPCM:
					encodeStreamCompactADPCM(intermediateWaveData.ptr, waveOut.data.ptr, waveOut.length);
					break;*/
				default:
					break;
			}
			
		}
		switch(typeOut){
			case "wav", ".wav":
				writeln("Generating ", outputFilename);
				WavFile f = WavFile();
				f.waveData ~= waveOut;
				int bitsPerSample = getWordLength(cOut);
				writeln(samplerateOut);
				uint samplerate = to!int(samplerateOut);
				f.header = WavHeader(waveOut.data.length, WAVAudioFormat.PCM, 1, to!ushort(bitsPerSample), to!ushort(bitsPerSample), samplerate, samplerate * (bitsPerSample / 8));
				storeWavFile(f, toStringz(outputFilename));
				break;
			case "pcm", ".pcm":
				writeln("Generating ", outputFilename);
				PCMFile f = PCMFile();
				f.waveData ~= waveOut;
				f.header = PCMHeader(waveOut.length, 0, waveOut.codecType, 1, 0, waveOut.sampleRate);
				storePCMFile(f, toStringz(outputFilename));
				break;
			default:
				writeln("Output type is unspecified or unknown!");
				return 0;
				break;
		}
	}
    return 0;
}
CodecType parseCodecType(string s){
	switch(s){
		case "8bitsigned":
			return CodecType.SIGNED8BIT;
		case "16bitsigned":
			return CodecType.SIGNED16BIT;
		case "24bitsigned":
			return CodecType.SIGNED24BIT;
		case "32bitsigned":
			return CodecType.SIGNED32BIT;
		case "8bitunsigned":
			return CodecType.UNSIGNED8BIT;
		case "12bitunsigned":
			return CodecType.UNSIGNED12BIT;
		case "16bitunsigned":
			return CodecType.UNSIGNED16BIT;
		case "24bitunsigned":
			return CodecType.UNSIGNED24BIT;
		case "32bitunsigned":
			return CodecType.UNSIGNED32BIT;
		case "IMA_ADPCM":
			return CodecType.IMA_ADPCM;
		case "Dialogic_ADPCM":
			return CodecType.DIALOGIC_ADPCM;
		case "Compact_ADPCM":
			return CodecType.COMPACT_ADPCM;
		default:
			return CodecType.NULL;	
	}
	//8bitsigned, 16bitsigned, 24bitsigned, 32bitsigned, 8bitunsigned, 12bitunsigned, 16bitunsigned, 24bitunsigned, 32bitunsigned, IMA_ADPCM, Dialogic_ADPCM, Compact_ADPCM
}