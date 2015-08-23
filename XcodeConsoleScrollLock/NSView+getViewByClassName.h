//
//  NSView+getViewByClassName.h
//  XcodeConsoleScrollLock
//
//  Created by Muronaka Hiroaki on 2015/08/23.
//  Copyright (c) 2015年 Muronaka Hiroaki. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (getViewByClassName)

- (NSView *)getViewByClassName:(NSString *)className;
-(NSString*)descriptionViews;

@end
