//
//  XcodeConsoleScrollLock.h
//  XcodeConsoleScrollLock
//
//  Created by Muronaka Hiroaki on 2015/08/22.
//  Copyright (c) 2015年 Muronaka Hiroaki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XcodeConsoleScrollLock : NSObject

+(void)pluginDidLoad:(NSBundle*)plugin;
+(instancetype)sharedInstance;
@end
