//
//  SpeechManager.h
//  BLSpeechRecognition
//
//  Created by Antony.Zhu on 2017/4/18.
//  Copyright © 2017年 Sankuai. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SPEECH_RECOGNITION_MSG  @"SPEECH_RECOGNITION_MSG"

@interface SpeechManager : NSObject

+ (instancetype)shareManager;

- (void)start;
- (void)stop;

@end
