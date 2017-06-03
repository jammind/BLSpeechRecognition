//
//  BLSpeechRecognition.h
//
//  Created by Antony Zhu on 2017/4/18.
//  Copyright © 2017年 Antony Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Cordova/CDV.h>

@interface BLSpeechRecognition : CDVPlugin {
    
}
@property (nonatomic, strong) NSString* callbackId;


- (void)startListening:(CDVInvokedUrlCommand*)command;
- (void)stopListening:(CDVInvokedUrlCommand*)command;
- (void)cancelListening:(CDVInvokedUrlCommand*)command;

@end
