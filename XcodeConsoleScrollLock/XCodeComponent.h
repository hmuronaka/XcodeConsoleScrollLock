//
//  XCodeComponent.h
//  XcodeConsoleScrollLock
//
//  Created by Muronaka Hiroaki on 2015/08/22.
//  Copyright (c) 2015年 Muronaka Hiroaki. All rights reserved.
//

#ifndef XcodeConsoleScrollLock_XCodeComponent_h
#define XcodeConsoleScrollLock_XCodeComponent_h

#import <AppKit/AppKit.h>

@interface IDEViewController

@end

@interface DVTTextView : NSTextView
@end

@interface DVTCompletingTextView : DVTTextView

@end

@interface DVTScrollView : NSScrollView

@end

@interface IDEDebugArea : IDEViewController

@end

@interface IDESplitViewDebugArea : IDEDebugArea

@end

@interface IDEConsoleArea

@property __weak DVTScrollView *consoleScrollView;

@end

@interface IDEDefaultDebugArea : IDESplitViewDebugArea

@property(readonly) IDEConsoleArea *consoleArea;

@end

@interface IDEConsoleTextView : DVTCompletingTextView

-(void)_scrollToBottom;
@end

#endif
