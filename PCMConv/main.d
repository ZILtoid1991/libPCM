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
8bitsigned, 16bitsigned, 24bitsigned, 32bitsigned, 8bitunsigned, 12bitunsigned, 16bitunsigned, 24bitunsigned, 32bitunsigned, IMA_ADPCM, Dialogic_ADPCM, Compact_ADPCM, XA_ADPCM
		 ");
}

int main(string[] argv){
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
								case "channels":
									state = 12;
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
		int channels;
		typeIn = toLower(typeIn);
		typeOut = toLower(typeOut);
		switch(typeIn){
			case "wav", ".wav":
				WavFile f = loadWavFile(toStringz(inputFilename));
				waveIn = f.data;
				channels = f.subchunk1.numOfChannels;
				writeln("Length in header:",f.subchunk2.subchunk2Size);
				writeln("Length of data:",waveIn.data.length);
				writeln("Number of channels:",f.subchunk1.numOfChannels);
				break;
			case "pcm", ".pcm":
				PCMFile f = loadPCMFile(toStringz(inputFilename));
				waveIn = f.data;
				channels = f.header.numOfChannels;
				writeln("Length in header:",f.header.length);
				writeln("Length of data:",waveIn.data.length);
				writeln("Number of channels:",f.header.numOfChannels);
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
			//writeln(waveIn.data);
			short[][8] intermediateWaveData, intermediateWaveData0;
			if(waveIn.channels == 1 || cIn == CodecType.XA_ADPCM){
				intermediateWaveData[0].length = waveIn.length * waveIn.channels;
				switch(cIn){
					case CodecType.SIGNED16BIT:
						//intermediateWaveData.length = waveIn.length * 2;
						intermediateWaveData[0]=cast(short[])waveIn.data;
						break;
					case CodecType.UNSIGNED8BIT:
						//intermediateWaveData.length = waveIn.length;
						decodeStream8BitPCMUnsigned(cast(ubyte*)waveIn.data.ptr, cast(short*)intermediateWaveData[0].ptr, waveIn.length);
						break;
					case CodecType.IMA_ADPCM:
						decodeStreamIMAADPCM(cast(ubyte*)waveIn.data.ptr, cast(short*)intermediateWaveData[0].ptr, waveIn.length);
						break;
					case CodecType.DIALOGIC_ADPCM:
						decodeStreamDialogicADPCM(cast(ubyte*)waveIn.data.ptr, cast(short*)intermediateWaveData[0].ptr, waveIn.length);
						break;
					case CodecType.XA_ADPCM:
						decodeStreamXAADPCM(cast(ubyte*)waveIn.data.ptr, cast(short*)intermediateWaveData[0].ptr, waveIn.length, waveIn.channels);
						break;
					default:
						break;
			}
			}else{
				for(int i ; i < waveIn.channels ; i++){
					intermediateWaveData[i].length = waveIn.length * (16 / 8);
					intermediateWaveData0[i].length = waveIn.length * (getWordLength(cIn) / 8);
				}
				separateAudioChannels(waveIn.data.ptr, [intermediateWaveData0[0].ptr,intermediateWaveData0[1].ptr,intermediateWaveData0[2].ptr,intermediateWaveData0[3].ptr,
										intermediateWaveData0[4].ptr,intermediateWaveData0[5].ptr,intermediateWaveData0[6].ptr,intermediateWaveData0[7].ptr], waveIn.length, 
										waveIn.channels, getWordLength(cIn));
				for(int i ; i < waveIn.channels ; i++){
					switch(cIn){
						case CodecType.SIGNED16BIT:
							//intermediateWaveData.length = waveIn.length * 2;
							intermediateWaveData=intermediateWaveData0;
							break;
						case CodecType.UNSIGNED8BIT:
							//intermediateWaveData.length = waveIn.length;
							decodeStream8BitPCMUnsigned(cast(ubyte*)intermediateWaveData0[i].ptr, cast(short*)intermediateWaveData[i].ptr, waveIn.length);
							break;
						case CodecType.IMA_ADPCM:
							decodeStreamIMAADPCM(cast(ubyte*)intermediateWaveData0[i].ptr, cast(short*)intermediateWaveData[i].ptr, waveIn.length);
							break;
						case CodecType.DIALOGIC_ADPCM:
							decodeStreamDialogicADPCM(cast(ubyte*)intermediateWaveData0[i].ptr, cast(short*)intermediateWaveData[i].ptr, waveIn.length);
							break;
						default:
							break;
					}
				}
			}
			if(cOut == CodecType.XA_ADPCM){
				size_t samplesize = waveIn.length / 2 + waveIn.length / 4;//((waveIn.length / 28) * 16) + 1024;
				waveOut = new WaveData(waveIn.length, samplerateOut, cOut, samplesize, cast(ubyte)channels);
			}else{
				waveOut = new WaveData(waveIn.length, samplerateOut, cOut, (getWordLength(cOut) * waveIn.length) / 8, cast(ubyte)channels);
			}
			if(waveIn.channels == 1 || cOut == CodecType.XA_ADPCM){
				switch(cOut){
					case CodecType.SIGNED16BIT:
						waveOut.data = intermediateWaveData[0];
						break;
					case CodecType.UNSIGNED8BIT:
						encodeStream8BitPCMUnsigned(cast(short*)intermediateWaveData[0].ptr, cast(ubyte*)waveOut.data.ptr, waveOut.length);
						break;
					case CodecType.IMA_ADPCM:
						encodeStreamIMAADPCM(cast(short*)intermediateWaveData[0].ptr, cast(ubyte*)waveOut.data.ptr, waveOut.length);
						break;
					case CodecType.DIALOGIC_ADPCM:
						encodeStreamDialogicADPCM(cast(short*)intermediateWaveData[0].ptr, cast(ubyte*)waveOut.data.ptr, waveOut.length);
						break;
					case CodecType.XA_ADPCM:
						intermediateWaveData[0].length += 1024;
						encodeStreamXAADPCM(cast(short*)intermediateWaveData[0].ptr, cast(ubyte*)waveOut.data.ptr, waveOut.length, waveOut.channels);
						
						break;
					default:
						break;
				}
			}else{
				for(int i ; i < waveIn.channels ; i++){
						
						intermediateWaveData0[i].length = waveIn.length * (getWordLength(cOut) / 8);
				}
				for(int i ; i < waveIn.channels ; i++){
					
					switch(cOut){
						case CodecType.SIGNED16BIT:
							intermediateWaveData0 = intermediateWaveData;
							break;
						case CodecType.UNSIGNED8BIT:
							encodeStream8BitPCMUnsigned(cast(short*)intermediateWaveData[i].ptr, cast(ubyte*)intermediateWaveData0[i].ptr, waveOut.length);
							break;
						case CodecType.IMA_ADPCM:
							encodeStreamIMAADPCM(cast(short*)intermediateWaveData[i].ptr, cast(ubyte*)intermediateWaveData0[i].ptr, waveOut.length);
							break;
						case CodecType.DIALOGIC_ADPCM:
							encodeStreamDialogicADPCM(cast(short*)intermediateWaveData[i].ptr, cast(ubyte*)intermediateWaveData0[i].ptr, waveOut.length);
							break;
						default:
							break;
					}
				}
				joinAudioChannels([intermediateWaveData0[0].ptr,intermediateWaveData0[1].ptr,intermediateWaveData0[2].ptr,intermediateWaveData0[3].ptr,
										intermediateWaveData0[4].ptr,intermediateWaveData0[5].ptr,intermediateWaveData0[6].ptr,intermediateWaveData0[7].ptr],
										waveOut.data.ptr, waveOut.length, channels, getWordLength(cOut));
				
			}
			
		}
		switch(typeOut){
			case "wav", ".wav":
				writeln("Generating ", outputFilename);
				WavFile f = new WavFile();
				f.data = waveOut;
				int bitsPerSample = getWordLength(cOut);
				writeln(samplerateOut);
				uint samplerate = to!int(samplerateOut);
				//f.header = WavHeader(waveOut.data.length, WAVAudioFormat.PCM, cast(ubyte)channels, to!ushort(bitsPerSample), to!ushort(bitsPerSample), samplerate, samplerate * (bitsPerSample / 8));
				f.subchunk1 = WavHeaderSubchunk1(WAVAudioFormat.PCM, cast(ushort)channels, to!ushort(bitsPerSample), to!ushort(bitsPerSample), samplerate, samplerate * (bitsPerSample / 8));
				f.subchunk2 = WavHeaderSubchunk2(f.data.data.length);
				f.riff = WavHeaderMain(f.subchunk1.subchunk1Size + f.subchunk2.subchunk2Size + 20);
				storeWavFile(f, toStringz(outputFilename));
				break;
			case "pcm", ".pcm":
				writeln("Generating ", outputFilename);
				PCMFile f = PCMFile();
				f.data = waveOut;
				f.header = PCMHeader(waveOut.length, 0, waveOut.codecType, cast(ubyte)channels, 0, waveOut.sampleRate);
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
		case "Yamaha_ADPCMA":
			return CodecType.Yamaha_ADPCMA;
		case "XA_ADPCM":
			return CodecType.XA_ADPCM;
		default:
			return CodecType.NULL;	
	}
	//8bitsigned, 16bitsigned, 24bitsigned, 32bitsigned, 8bitunsigned, 12bitunsigned, 16bitunsigned, 24bitunsigned, 32bitunsigned, IMA_ADPCM, Dialogic_ADPCM, Compact_ADPCM
}