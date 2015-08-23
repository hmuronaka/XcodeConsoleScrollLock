//
//  NSView+getViewByClassName.m
//  XcodeConsoleScrollLock
//
//  Created by Muronaka Hiroaki on 2015/08/23.
//  Copyright (c) 2015年 Muronaka Hiroaki. All rights reserved.
//

#import "NSView+getViewByClassName.h"

@implementation NSView (getViewByClassName)


- (NSView *)getViewByClassName:(NSString *)className {
    Class class = NSClassFromString(className);
    for (NSView *subView in self.subviews) {
        if ([subView isKindOfClass:class]) {
            return subView;
        } else {
            NSView *view = [subView getViewByClassName:className];
            if ([view isKindOfClass:class]) {
                return view;
            }
        }
    }
    return nil;
}

-(NSString*)descriptionViews {
    return [self descriptionViewsWithPrefix:@""];
}

-(NSString*)descriptionViewsWithPrefix:(NSString*)prefix {
    
    NSString* desc = [NSString stringWithFormat:@"@%@%@\n",prefix, [self className]];
    prefix = [prefix stringByAppendingString:@"  "];
    for(NSView * subView in self.subviews) {
        desc = [desc stringByAppendingString:[subView descriptionViewsWithPrefix:prefix]];
    }
    return desc;
}


-(NSView*)getParantViewByClassName:(NSString *)className {
    NSView *superView = self.superview;
    while (superView) {
        if ([[superView className] isEqualToString:className]) {
            return superView;
        }
        superView = superView.superview;
    }
    
    return nil;
}

@end
