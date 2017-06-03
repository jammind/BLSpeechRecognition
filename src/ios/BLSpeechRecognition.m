//
//  BLSpeechRecognition.m
//
//  Created by Antony Zhu on 2017/4/18.
//  Copyright © 2017年 Antony Zhu. All rights reserved.
//


#import "BLSpeechRecognition.h"
#import "SpeechManager.h"
#import <Speech/Speech.h>

#define STR_EVENT @"event"
#define STR_CODE @"code"
#define STR_MESSAGE @"message"
#define STR_VOLUME @"volume"
#define STR_RESULTS @"results"
#define STR_PROGRESS @"progress"

@interface BLSpeechRecognition()

@property(nonatomic,strong)SFSpeechRecognizer *bufferRec;
@property(nonatomic,strong)SFSpeechAudioBufferRecognitionRequest *bufferRequest;
@property(nonatomic,strong)SFSpeechRecognitionTask *bufferTask;
@property(nonatomic,strong)AVAudioEngine *bufferEngine;
@property(nonatomic,strong)AVAudioInputNode *buffeInputNode;

@end

@implementation BLSpeechRecognition
- (void)login:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;

    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        // 对结果枚举的判断
        if(status != SFSpeechRecognizerAuthorizationStatusAuthorized){
            //请在plist文件中添加“Privacy - Speech Recognition Usage Description”权限申请，否则无法使用语音听写
            NSLog(@"不给权限直接强退");
//            [@[] objectAtIndex:1];
            [self.commandDelegate runInBackground:^{
                NSDictionary* errorData = [NSDictionary dictionaryWithObject:@"Speech Recognition Usage Description" forKey:@"error"];
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:errorData];
                [result setKeepCallbackAsBool:YES];
                [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
            }];
        }
    }];
    [self.commandDelegate runInBackground:^{
        [[SpeechManager shareManager] start];
    }];
}

#pragma mark - 语音录入
- (void)startListening:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        [self startListeningIMP];
    }];
}

- (void)startListeningIMP {
    
   dispatch_async(dispatch_get_main_queue(), ^{

       self.bufferRec = [[SFSpeechRecognizer alloc]initWithLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
       self.bufferEngine = [[AVAudioEngine alloc]init];
       self.buffeInputNode = [self.bufferEngine inputNode];
       
       if (_bufferTask != nil) {
           [_bufferTask cancel];
           _bufferTask = nil;
       }
       
       // block外的代码也都是准备工作，参数初始设置等
       self.bufferRequest = [[SFSpeechAudioBufferRecognitionRequest alloc]init];
       self.bufferRequest.shouldReportPartialResults = true;
       
       self.bufferTask = [self.bufferRec recognitionTaskWithRequest:self.bufferRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
           
           if (result.final) {
               self.bufferRequest = nil;
               self.bufferTask = nil;
               
               [self startListeningIMP];
           } else {
               NSString *text = [[NSString alloc] init];
               text = result.bestTranscription.formattedString;
               
               [self.commandDelegate runInBackground:^{
                   NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:@"SpeechResults",STR_EVENT,text,STR_RESULTS, nil];
                   CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:info];
                   [result setKeepCallbackAsBool:YES];
                   [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
               }];
           }
           
       }];
       
       // 监听一个标识位并拼接流文件
       AVAudioFormat *format =[self.buffeInputNode outputFormatForBus:0];
       [self.buffeInputNode removeTapOnBus:0];
       [self.buffeInputNode installTapOnBus:0 bufferSize:8192 format:format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
           [self.bufferRequest appendAudioPCMBuffer:buffer];
       }];
       
       // 准备并启动引擎
       [self.bufferEngine prepare];
       NSError *error = nil;
       if (![self.bufferEngine startAndReturnError:&error]) {
           NSLog(@"error: %@",error.userInfo);
       };
   });
}

- (void)stopListening:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        [[SpeechManager shareManager] stop];
        [self.bufferEngine stop];
        [self.buffeInputNode removeTapOnBus:0];
        self.bufferRequest = nil;
        self.bufferTask = nil;
    }];
}

- (void)cancelListening:(CDVInvokedUrlCommand*)command
{
    [[SpeechManager shareManager] stop];
}

@end
