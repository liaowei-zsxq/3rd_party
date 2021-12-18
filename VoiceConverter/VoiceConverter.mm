//
//  VoiceConverter.mm
//  Jeans
//
//  Created by Jeans Huang on 12-7-22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "VoiceConverter.h"

@implementation VoiceConverter

/**
 *  转换wav到amr
 *
 *  @param aWavPath  wav文件路径
 *  @param aSavePath amr保存路径
 *
 *  @return 0失败 1成功
 */
+ (int)EncodeWavToAmr:(NSString *)aWavPath amrSavePath:(NSString *)aSavePath sampleRateType:(Sample_Rate)sampleRateType {
    if (sampleRateType == Sample_Rate_8000) {
        int result = EncodeNarrowBandWAVEFileToAMRFile([aWavPath cStringUsingEncoding:NSUTF8StringEncoding], [aSavePath cStringUsingEncoding:NSUTF8StringEncoding], 1, 16);
        return result;
    } else {
        int result = [LYHAMRConverter wavToAmr:aWavPath amrSavePath:aSavePath];
        return result;
    }
}

/**
 *  转换amr到wav
 *
 *  @param aAmrPath  amr文件路径
 *  @param aSavePath wav保存路径
 *
 *  @return 0失败 1成功
 */
+ (int)DecodeAmrToWav:(NSString *)aAmrPath wavSavePath:(NSString *)aSavePath sampleRateType:(Sample_Rate)sampleRateType {
    if (sampleRateType == Sample_Rate_8000) {
        return DecodeNarrowBandAMRFileToWAVEFile([aAmrPath cStringUsingEncoding:NSUTF8StringEncoding], [aSavePath cStringUsingEncoding:NSUTF8StringEncoding]);
    } else {
        return [LYHAMRConverter amrToWav:aAmrPath wavSavePath:aSavePath];
    }
}

+ (int)EncodeWavToMp3:(NSString *)aWavPath mp3SavePath:(NSString *)aSavePath {
    int result = 0;

    @try {
        size_t read = 0, write = 0;

        FILE *pcm = fopen([aWavPath cStringUsingEncoding:NSASCIIStringEncoding], "rb");    //source
        fseek(pcm, 4 * 1024, SEEK_CUR);                                                    //skip file header
        FILE *mp3 = fopen([aSavePath cStringUsingEncoding:NSASCIIStringEncoding], "wb+");  //output

        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE * 2];
        unsigned char mp3_buffer[MP3_SIZE];

        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 44100.0);
        lame_set_VBR(lame, vbr_default);

        id3tag_init(lame);
        id3tag_add_v2(lame);
        id3tag_v2_only(lame);

        id3tag_set_artist(lame, "zsxq");
        id3tag_set_album(lame, "zsxq q&a");
        id3tag_set_comment(lame, "Encoded by zsxq for iOS");

        lame_init_params(lame);

        do {
            read = fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
            if (read == 0) {
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            } else {
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, (int)read, mp3_buffer, MP3_SIZE);
            }

            fwrite(mp3_buffer, write, 1, mp3);

        } while (read != 0);

        lame_mp3_tags_fid(lame, mp3);
        lame_close(lame);

        fflush(mp3);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        result = -1;
    }
    @finally {
        return result;
    }
}

//获取录音设置
+ (NSDictionary *)GetAudioRecorderSettingDictWithSampleRateType:(Sample_Rate)sampleRateType {
    CGFloat sampleRateValue = 16000.0;
    if (sampleRateType == Sample_Rate_8000) {
        sampleRateValue = 8000.0;
    }
    if (sampleRateType == Sample_Rate_16000) {
        sampleRateValue = 16000.0;
    }
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                            [NSNumber numberWithFloat:sampleRateValue], AVSampleRateKey,  //采样率
                                                            [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                                            [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,  //采样位数 默认 16
                                                            [NSNumber numberWithInt:1], AVNumberOfChannelsKey,    //通道的数目
                                                            nil];

    return recordSetting;
}

+ (BOOL)isAmrFile:(NSString *)path sampleRateType:(Sample_Rate *)sampleRateType {
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path] options:NSDataReadingMapped error:&error];

    if (error) {
        return NO;
    }

    if (data.length > 9 && strncasecmp("#!AMR-WB\n", (const char *)data.bytes, 9) == 0) {
        if (sampleRateType != NULL) {
            *sampleRateType = Sample_Rate_16000;
        }

        return YES;
    }

    if (data.length > 6 && strncasecmp("#!AMR\n", (const char *)data.bytes, 6) == 0) {
        if (sampleRateType != NULL) {
            *sampleRateType = Sample_Rate_8000;
        }

        return YES;
    }

    return NO;
}

+ (BOOL)isMp3File:(NSString *)path {
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path] options:NSDataReadingMapped error:&error];

    if (error) {
        return NO;
    }

    if (data.length > 3 && strncasecmp("ID3", (const char *)data.bytes, 3) == 0) {
        return YES;
    }

    if (data.length > 3 && strncasecmp("\xFF\xFB\x90", (const char *)data.bytes, 3) == 0) {
        return YES;
    }

    return NO;
}

@end
