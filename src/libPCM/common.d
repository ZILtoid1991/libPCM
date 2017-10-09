/*
 * libPCM by László Szerémi.
 * Copyright under Boost License.
 */

module libPCM.common;

import core.stdc.stdlib;

import libPCM.types;

/**
 * Describes the type of codec used, as well as the bitdepth
 */
public enum CodecType : ushort{
	NULL			=	0,
	UNSIGNED8BIT	=	1,
	UNSIGNED12BIT	=	2,
	UNSIGNED16BIT	=	3,
	UNSIGNED24BIT	=	4,
	UNSIGNED32BIT	=	5,
	SIGNED8BIT		=	6,
	SIGNED12BIT		=	7,
	SIGNED16BIT		=	8,
	SIGNED24BIT		=	9,
	SIGNED32BIT		=	10,
	DIALOGIC_ADPCM	=	32,
	IMA_ADPCM		=	33,
	XA_ADPCM		=	35,
	Yamaha_ADPCMA	=	36,
	MU_LAW			=	64,
	A_LAW_87_6		=	65,
	FLOAT			=	96,
}

/**
 * For *.wav files
 */
public enum WAVAudioFormat : ushort{
	/* WAVE form wFormatTag IDs */
	UNKNOWN		=	0x0000, /* Microsoft Corporation */
	PCM			=	0x0001,
	ADPCM		=	0x0002, /* Microsoft Corporation */
	IEEE_FLOAT	=	0x0003, /* Microsoft Corporation */
	VSELP		=	0x0004, /* Compaq Computer Corp. */
	IBM_CVSD	=	0x0005, /* IBM Corporation */
	ALAW		=	0x0006, /* Microsoft Corporation */
	MULAW		=	0x0007, /* Microsoft Corporation */
	DTS			=	0x0008, /* Microsoft Corporation */
	OKI_ADPCM	=	0x0010, /* OKI */
	DVI_ADPCM	=	0x0011, /* Intel Corporation */
	IMA_ADPCM	=	DVI_ADPCM, /*  Intel Corporation */
	MEDIASPACE_ADPCM	=	0x0012, /* Videologic */
	SIERRA_ADPCM=	0x0013, /* Sierra Semiconductor Corp */
	G723_ADPCM	=	0x0014, /* Antex Electronics Corporation */
	DIGISTD		=	0x0015, /* DSP Solutions, Inc. */
	DIGIFIX		=	0x0016, /* DSP Solutions, Inc. */
	DIALOGIC_OKI_ADPCM	=	0x0017, /* Dialogic Corporation */
	MEDIAVISION_ADPCM	=	0x0018, /* Media Vision, Inc. */
	CU_CODEC	=	0x0019, /* Hewlett-Packard Company */
	YAMAHA_ADPCM=	0x0020, /* Yamaha Corporation of America */
	SONARC		=	0x0021, /* Speech Compression */
	DSPGROUP_TRUESPEECH	=	0x0022, /* DSP Group, Inc */
	ECHOSC1		=	0x0023, /* Echo Speech Corporation */
	AUDIOFILE_AF36		=	0x0024, /* Virtual Music, Inc. */
	APTX		=	0x0025, /* Audio Processing Technology */
	AUDIOFILE_AF10		=	0x0026, /* Virtual Music, Inc. */
	PROSODY_1612=	0x0027, /* Aculab plc */
	LRC			=	0x0028, /* Merging Technologies S.A. */
	DOLBY_AC2	=	0x0030, /* Dolby Laboratories */
	GSM610		=	0x0031, /* Microsoft Corporation */
	MSNAUDIO	=	0x0032, /* Microsoft Corporation */
	ANTEX_ADPCME=	0x0033, /* Antex Electronics Corporation */
	CONTROL_RES_VQLPC	=	0x0034, /* Control Resources Limited */
	DIGIREAL	=	0x0035, /* DSP Solutions, Inc. */
	DIGIADPCM	=	0x0036, /* DSP Solutions, Inc. */
	CONTROL_RES_CR10	=	0x0037, /* Control Resources Limited */
	NMS_VBXADPCM=	0x0038, /* Natural MicroSystems */
	CS_IMAADPCM	=	0x0039, /* Crystal Semiconductor IMA ADPCM */
	ECHOSC3		=	0x003A, /* Echo Speech Corporation */
	ROCKWELL_ADPCM		=	0x003B, /* Rockwell International */
	ROCKWELL_DIGITALK	=	0x003C, /* Rockwell International */
	XEBEC		=	0x003D, /* Xebec Multimedia Solutions Limited */
	G721_ADPCM	=	0x0040, /* Antex Electronics Corporation */
	G728_CELP	=	0x0041, /* Antex Electronics Corporation */
	MSG723		=	0x0042, /* Microsoft Corporation */
	MPEG		=	0x0050, /* Microsoft Corporation */
	RT24		=	0x0052, /* InSoft, Inc. */
	PAC			=	0x0053, /* InSoft, Inc. */
	MPEGLAYER3	=	0x0055, /* ISO/MPEG Layer3 Format Tag */
	LUCENT_G723	=	0x0059, /* Lucent Technologies */
	CIRRUS		=	0x0060, /* Cirrus Logic */
	ESPCM		=	0x0061, /* ESS Technology */
	VOXWARE		=	0x0062, /* Voxware Inc */
	CANOPUS_ATRAC		=	0x0063, /* Canopus, co., Ltd. */
	G726_ADPCM	=	0x0064, /* APICOM */
	G722_ADPCM	=	0x0065, /* APICOM */
	DSAT_DISPLAY=	0x0067, /* Microsoft Corporation */
	VOXWARE_BYTE_ALIGNED=	0x0069, /* Voxware Inc */
	VOXWARE_AC8	=	0x0070, /* Voxware Inc */
	VOXWARE_AC10=	0x0071, /* Voxware Inc */
	VOXWARE_AC16=	0x0072, /* Voxware Inc */
	VOXWARE_AC20=	0x0073, /* Voxware Inc */
	VOXWARE_RT24=	0x0074, /* Voxware Inc */
	VOXWARE_RT29=	0x0075, /* Voxware Inc */
	VOXWARE_RT29HW		=	0x0076, /* Voxware Inc */
	VOXWARE_VR12=	0x0077, /* Voxware Inc */
	VOXWARE_VR18=	0x0078, /* Voxware Inc */
	VOXWARE_TQ40=	0x0079, /* Voxware Inc */
	SOFTSOUND	=	0x0080, /* Softsound, Ltd. */
	VOXWARE_TQ60=	0x0081, /* Voxware Inc */
	MSRT24		=	0x0082, /* Microsoft Corporation */
	G729A		=	0x0083, /* AT&T Labs, Inc. */
	MVI_MVI2	=	0x0084, /* Motion Pixels */
	DF_G726		=	0x0085, /* DataFusion Systems (Pty) (Ltd) */
	DF_GSM610	=	0x0086, /* DataFusion Systems (Pty) (Ltd) */
	ISIAUDIO	=	0x0088, /* Iterated Systems, Inc. */
	ONLIVE		=	0x0089, /* OnLive! Technologies, Inc. */
	SBC24		=	0x0091, /* Siemens Business Communications Sys */
	DOLBY_AC3_SPDIF		=	0x0092, /* Sonic Foundry */
	MEDIASONIC_G723		=	0x0093, /* MediaSonic */
	PROSODY_8KBPS		=	0x0094, /* Aculab plc */
	ZYXEL_ADPCM	=	0x0097, /* ZyXEL Communications, Inc. */
	PHILIPS_LPCBB		=	0x0098, /* Philips Speech Processing */
	PACKED		=	0x0099, /* Studer Professional Audio AG */
	MALDEN_PHONYTALK	=	0x00A0, /* Malden Electronics Ltd. */
	RHETOREX_ADPCM		=	0x0100, /* Rhetorex Inc. */
	IRAT		=	0x0101, /* BeCubed Software Inc. */
	VIVO_G723	=	0x0111, /* Vivo Software */
	VIVO_SIREN	=	0x0112, /* Vivo Software */
	DIGITAL_G723=	0x0123, /* Digital Equipment Corporation */
	SANYO_LD_ADPCM		=	0x0125, /* Sanyo Electric Co., Ltd. */
	SIPROLAB_ACEPLNET	=	0x0130, /* Sipro Lab Telecom Inc. */
	SIPROLAB_ACELP4800	=	0x0131, /* Sipro Lab Telecom Inc. */
	SIPROLAB_ACELP8V3	=	0x0132, /* Sipro Lab Telecom Inc. */
	SIPROLAB_G729		=	0x0133, /* Sipro Lab Telecom Inc. */
	SIPROLAB_G729A		=	0x0134, /* Sipro Lab Telecom Inc. */
	SIPROLAB_KELVIN		=	0x0135, /* Sipro Lab Telecom Inc. */
	G726ADPCM	=	0x0140, /* Dictaphone Corporation */
	QUALCOMM_PUREVOICE	=	0x0150, /* Qualcomm, Inc. */
	QUALCOMM_HALFRATE	=	0x0151, /* Qualcomm, Inc. */
	TUBGSM		=	0x0155, /* Ring Zero Systems, Inc. */
	MSAUDIO1	=	0x0160, /* Microsoft Corporation */
	CREATIVE_ADPCM		=	0x0200, /* Creative Labs, Inc */
	CREATIVE_FASTSPEECH8=	0x0202, /* Creative Labs, Inc */
	CREATIVE_FASTSPEECH10	=	0x0203, /* Creative Labs, Inc */
	UHER_ADPCM	=	0x0210, /* UHER informatic GmbH */
	QUARTERDECK	=	0x0220, /* Quarterdeck Corporation */
	ILINK_VC	=	0x0230, /* I-link Worldwide */
	RAW_SPORT	=	0x0240, /* Aureal Semiconductor */
	IPI_HSX		=	0x0250, /* Interactive Products, Inc. */
	IPI_RPELP	=	0x0251, /* Interactive Products, Inc. */
	CS2			=	0x0260, /* Consistent Software */
	SONY_SCX	=	0x0270, /* Sony Corp. */
	FM_TOWNS_SND=	0x0300, /* Fujitsu Corp. */
	BTV_DIGITAL	=	0x0400, /* Brooktree Corporation */
	QDESIGN_MUSIC		=	0x0450, /* QDesign Corporation */
	VME_VMPCM	=	0x0680, /* AT&T Labs, Inc. */
	TPC			=	0x0681, /* AT&T Labs, Inc. */
	OLIGSM		=	0x1000, /* Ing C. Olivetti & C., S.p.A. */
	OLIADPCM	=	0x1001, /* Ing C. Olivetti & C., S.p.A. */
	OLICELP		=	0x1002, /* Ing C. Olivetti & C., S.p.A. */
	OLISBC		=	0x1003, /* Ing C. Olivetti & C., S.p.A. */
	OLIOPR		=	0x1004, /* Ing C. Olivetti & C., S.p.A. */
	LH_CODEC	=	0x1100, /* Lernout & Hauspie */
	WAVE_FORMAT_NORRIS	=	0x1400, /* Norris Communications, Inc. */
	SOUNDSPACE_MUSICOMPRESS	=	0x1500, /* AT&T Labs, Inc. */
	DVM		=	0x2000, /* FAST Multimedia AG */
}

public CodecType fromWAVAudioFormat(ushort input, ushort bitDepth){
	switch(input){
		case WAVAudioFormat.PCM:
			switch (bitDepth){
				case 8:
					return CodecType.UNSIGNED8BIT;
				case 16:
					return CodecType.SIGNED16BIT;
				default:
					return CodecType.NULL;
			}
		case WAVAudioFormat.OKI_ADPCM:
			return CodecType.DIALOGIC_ADPCM;
		case WAVAudioFormat.IMA_ADPCM:
			return CodecType.IMA_ADPCM;
		case WAVAudioFormat.IEEE_FLOAT:
			return CodecType.FLOAT;
		default:
			return CodecType.NULL;
	}
}

public class AudioFileException : Exception{
	@nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }

    @nogc @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, next);
    }
}


	/**
	 * Returns the word lenght for the given codec type
	 */
public @nogc int getWordLength(CodecType codec){
	switch(codec){
		//case CodecType.A_LAW_87_6, CodecType.MU_LAW, CodecType.SIGNED8BIT, CodecType.UNSIGNED8BIT: return 8;
		//case CodecType.DIALOGIC_ADPCM, CodecType.IMA_ADPCM: return 4;
		case CodecType.SIGNED16BIT, CodecType.UNSIGNED16BIT: return 16;
		case CodecType.SIGNED24BIT, CodecType.UNSIGNED24BIT: return 24;
		case CodecType.SIGNED32BIT, CodecType.UNSIGNED32BIT, CodecType.FLOAT: return 32;
		//case CodecType.COMPACT_ADPCM: return 2;
		case CodecType.XA_ADPCM: return 128 * 8;
		default: return 8;
	}
}
	/**
	 * Completely deallocates the memory for the given PCM data
	 */
	/*void deletePCMFromMemory(PCMFile* file){
		if(file.name){
			free(file.name);
		}
		if(file.startOfData){
			free(file.startOfData);
		}else{
			for(int i ; i < file.header.numOfChannels ; i++){
				free((*file.waveData + i).data);
				free(file.waveData + i);
			}
		}
		free(file);
	}*/
/**
 * Separates audio streams from a joint stream.
 */
public @nogc void separateAudioChannels(void* input, void*[8] output, uint lenght, int channels, int wordLength = 16){
	switch(wordLength){
		case 16:
			ushort* input0 = cast(ushort*)input;
			ushort*[8] output0 = cast(ushort*[8])output;
			for(uint i ; i < lenght ; i++){
				for(int j ; j < channels ; j++){
					output0[j][i] = input0[(i * channels) + j];
				}
			}
			break;
		case 8:
			ubyte* input0 = cast(ubyte*)input;
			ubyte*[8] output0 = cast(ubyte*[8])output;
			for(uint i ; i < lenght ; i++){
				for(int j ; j < channels ; j++){
					output0[j][i] = input0[(i * channels) + j];
				}
			}
			break;
		case 32:
			uint* input0 = cast(uint*)input;
			uint*[8] output0 = cast(uint*[8])output;
			for(uint i ; i < lenght ; i++){
				for(int j ; j < channels ; j++){
					output0[j][i] = input0[(i * channels) + j];
				}
			}
			break;
		default:
			if(!(wordLength % 8)){
				ubyte* input0 = cast(ubyte*)input;
				ubyte*[8] output0 = cast(ubyte*[8])output;
				for(uint i ; i < lenght ; i++){
					for(int j ; j < channels ; j++){
						for(int k ; k < wordLength / 8 ; k++){
							output0[j][i+k] = input0[(i * channels) + j + k];
						}
					}
				}
			}
			break;
	}
}
/**
 * Joints multiple audio channels into a single one.
 */
public @nogc void joinAudioChannels(void*[8] input, void* output, uint lenght, int channels, int wordLength = 16){
	switch(wordLength){
		case 16:
			ushort* output0 = cast(ushort*)output; 
			ushort*[8] input0 = cast(ushort*[8])input;
			for(uint i ; i < lenght ; i++){
				for(int j ; j < channels ; j++){
					output0[(i * channels) + j] = input0[j][i];
				}
			}
			break;
		case 8:
			ubyte* output0 = cast(ubyte*)output; 
			ubyte*[8] input0 = cast(ubyte*[8])input;
			for(uint i ; i < lenght ; i++){
				for(int j ; j < channels ; j++){
					output0[(i * channels) + j] = input0[j][i];
				}
			}
			break;
		case 32:
			uint* output0 = cast(uint*)output;
			uint*[8] input0 = cast(uint*[8])input;
			for(uint i ; i < lenght ; i++){
				for(int j ; j < channels ; j++){
					output0[(i * channels) + j] = input0[j][i];
				}
			}
			break;
		default:
			if(!(wordLength % 8)){
				ubyte* output0 = cast(ubyte*)output; 
				ubyte*[8] input0 = cast(ubyte*[8])input;
				for(uint i ; i < lenght ; i++){
					for(int j ; j < channels ; j++){
						for(int k ; k < wordLength / 8 ; k++){
							output0[(i * channels) + j + k] = input0[j][i+k];
						}
					}
				}
			}
			break;
	}
}