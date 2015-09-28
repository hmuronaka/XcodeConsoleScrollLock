//
//  XcodeConsoleScrollLock.m
//  XcodeConsoleScrollLock
//
//  Created by Muronaka Hiroaki on 2015/08/22.
//  Copyright (c) 2015年 Muronaka Hiroaki. All rights reserved.
//

@import ObjectiveC;
#import <AppKit/AppKit.h>
#import "XcodeConsoleScrollLock.h"
#import "XCodeComponent.h"
#import "NSView+getViewByClassName.h"
#import <objc/runtime.h>
#import "IDEConsoleTextView+Extend.h"

#define NSLog(format, ...) NSLog(@"XcodeConsoleScrollLock:%4d " format, __LINE__, ##__VA_ARGS__)

typedef NS_ENUM(NSInteger, ScrollLockState) {
    ScrollLockStateScrollable,
    ScrollLockStateTemporaryScrollable,
    ScrollLockStateLock
};

@interface XcodeConsoleScrollLock()

@property(nonatomic, assign) ScrollLockState lockState;
@property(nonatomic, assign) Method originalMethod;
@property(nonatomic, assign) Method overrideMethod;

@end

@implementation XcodeConsoleScrollLock

static XcodeConsoleScrollLock* _sharedInstance;

+(void)pluginDidLoad:(NSBundle*)plugin {
    NSLog(@"XcodeConsoleScrollLock test!!!");
    [self sharedInstance];
}

#pragma mark class methods.

+(instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

#pragma mark instance methods.

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lockState = ScrollLockStateScrollable;
        
//        // override IDEConsoleTextView::_scrollToBottom
//        self.originalMethod = class_getInstanceMethod([IDEConsoleTextView class], @selector(_scrollToBottom));
//        self.overrideMethod = class_getInstanceMethod([self class], @selector(ignoreScrollToBottom));
//        SEL selector = NSSelectorFromString(@"XCSL_scrollToBottom");
//        
//        class_addMethod([IDEConsoleTextView class], selector, method_getImplementation(self.originalMethod), method_getTypeEncoding(self.originalMethod));
//        method_exchangeImplementations(self.originalMethod, self.overrideMethod);
        
        [IDEConsoleTextView xcsl_initialize];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(workspaceClosed:)
                                                     name:@"_IDEWorkspaceClosedNotification"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activate:) name:@"IDEControlGroupDidChangeNotificationName" object:nil];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationListener:) name:nil object:nil];

    }
    
    return self;
}

-(void)notificationListener:(NSNotification *)notification {
    // let's filter all the "normal" NSxxx events so that we only
    // really see the Xcode specific events.
    if ([[notification name] length] >= 2 && [[[notification name] substringWithRange:NSMakeRange(0, 2)] isEqualTo:@"NS"])
        return;
    else
        NSLog(@"  Notification: %@", [notification name]);
}

-(void)workspaceClosed:(NSNotification*)notification {
    NSLog(@"workspaceClosed");
    IDEConsoleTextView* textView = [self getConsoleTextView];
    if( !textView ) {
        NSLog(@"textView is nil");
        return;
    }
    
    objc_setAssociatedObject(textView, "LOCK_CHECK_BOX", nil, OBJC_ASSOCIATION_ASSIGN);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)applicationDidFinishLaunching:(NSNotification*)noti {
//    NSLog(@"XcodeConsoleScrollLock launching!!");
}


-(void)ignoreScrollToBottom {
    NSLog(@"A");
    IDEConsoleTextView* textView = (IDEConsoleTextView*)self;
    if( !textView ) {
        return;
    }
    NSLog(@"B");
    NSButton* checkButton = objc_getAssociatedObject(textView, "LOCK_CHECK_BOX");
    if( !checkButton ) {
        return;
    }
    
    NSLog(@"C");
    if( checkButton.state != NSOnState ) {
        [self ignoreScrollToBottom];
//        SEL sel = NSSelectorFromString(@"XCSL_scrollToBottom");
//        NSLog(@"D");
//        [textView performSelector:sel withObject:nil];
    }
    NSLog(@"E");
}

-(void)activate:(NSNotification*)notification {
    
    IDEConsoleTextView* textView = [self getConsoleTextView];
    if( !textView ) {
        return;
    }
    
    NSButton* checkButton = objc_getAssociatedObject(textView, "LOCK_CHECK_BOX");
    if( !checkButton ) {
        [self addCheckbox];
    } else {
        NSLog(@"checkbox already exists");
    }
}

-(void)addCheckbox {
    
    NSView* contentView = [[NSApp mainWindow] contentView];
    IDEConsoleTextView* consoleTextView = [self getConsoleTextView];
    if( !consoleTextView ) {
        return;
    }
    
    contentView = [consoleTextView getParantViewByClassName:@"DVTControllerContentView"];
    if( !contentView ) {
        NSLog(@"contentView is nil");
        return;
    }
    
    NSView* scopeBarView = [contentView getViewByClassName:@"DVTScopeBarView"];
    if( !scopeBarView ) {
        NSLog(@"scopeBarView is nil");
        return;
    }
    
    NSButton *button = nil;
    NSPopUpButton *filterButton = nil;
    for (NSView *subView in scopeBarView.subviews) {
        if (button && filterButton) break;
        if (button == nil && [[subView className] isEqualToString:@"NSButton"]) {
            button = (NSButton *)subView;
        }
        else if (filterButton == nil && [[subView className] isEqualToString:@"NSPopUpButton"]) {
            filterButton = (NSPopUpButton *)subView;
        }
    }
    
    if (!button) {
        NSLog(@"button is nil");
        return;
    }
    
    NSButton* checkButton = [[NSButton alloc] initWithFrame:NSMakeRect(
                                                                       filterButton.frame.origin.x + filterButton.frame.size.width + 30,
                                                                       filterButton.frame.origin.y,
                                                                       50,
                                                                       filterButton.frame.size.height)];
    [checkButton setButtonType:NSSwitchButton];
    [checkButton setTitle:@"Lock"];
    [checkButton setState:NSOffState];
    [checkButton setAction:@selector(checkScrollLockState:)];
    [checkButton setTarget:self];
    [scopeBarView addSubview:checkButton];
    
    objc_setAssociatedObject(consoleTextView, "LOCK_CHECK_BOX", checkButton, OBJC_ASSOCIATION_ASSIGN);
}

-(void)checkScrollLockState:(NSButton*)button {
    
    if( button.state == NSOffState ) {
        self.lockState = ScrollLockStateScrollable;
    } else if(button.state == NSOnState ) {
        self.lockState = ScrollLockStateLock;
    }
}

-(IDEConsoleTextView*)getConsoleTextView {
    
    NSView* contentView = [[NSApp mainWindow] contentView];
    if( !contentView ) {
        NSLog(@"contentView is nil");
        return nil;
    }
    IDEConsoleTextView* consoleTextView = (IDEConsoleTextView*)[contentView getViewByClassName:@"IDEConsoleTextView"];
    
    if( !consoleTextView ) {
        NSLog(@"IDEConsoleTextView is nil.");
    }
    return consoleTextView;
}

@end
