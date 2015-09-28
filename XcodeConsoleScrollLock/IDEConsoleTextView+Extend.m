//
//  IDEConsoleTextView+Extend.m
//  XcodeConsoleScrollLock
//
//  Created by MuronakaHiroaki on 2015/09/28.
//  Copyright © 2015年 Muronaka Hiroaki. All rights reserved.
//

#import "IDEConsoleTextView+Extend.h"
#import "NSObject+XVimAdditions.h"


@implementation IDEConsoleTextView (Extend)

+(void)xcsl_initialize {
    // override IDEConsoleTextView::_scrollToBottom
    [self xvim_swizzleInstanceMethod:@selector(_scrollToBottom) with:@selector(xcsl_scrollToBottom)];
}

-(void)xcsl_scrollToBottom {
    [self xcsl_scrollToBottom];
}

@end
