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

#define NSLog(format, ...) NSLog(@"XcodeConsoleScrollLock:%4d " format, __LINE__, ##__VA_ARGS__)

typedef NS_ENUM(NSInteger, ScrollLockState) {
    ScrollLockStateScrollable,
    ScrollLockStateTemporaryScrollable,
    ScrollLockStateLock
};

@interface XcodeConsoleScrollLock()

@property(nonatomic, weak) NSScrollView* scrollView;
@property(nonatomic, assign) ScrollLockState lockState;
@property(nonatomic, weak) NSClipView* clipView;
@property(nonatomic, assign) CGFloat clipViewY;
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
        
        // override IDEConsoleTextView::_scrollToBottom
        self.originalMethod = class_getInstanceMethod([IDEConsoleTextView class], @selector(_scrollToBottom));
        self.overrideMethod = class_getInstanceMethod([self class], @selector(ignoreScrollToBottom));
        SEL selector = NSSelectorFromString(@"XCSL_scrollToBottom");
        
        class_addMethod([IDEConsoleTextView class], selector, method_getImplementation(self.originalMethod), method_getTypeEncoding(self.originalMethod));
        method_exchangeImplementations(self.originalMethod, self.overrideMethod);
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activate:) name:@"IDEControlGroupDidChangeNotificationName" object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)applicationDidFinishLaunching:(NSNotification*)noti {
//    NSLog(@"XcodeConsoleScrollLock launching!!");
}

-(void)applicationWillTerminate:(NSNotification*)noti {
//    NSLog(@"XcodeConsoleScrollLock terminate!!");
    objc_setAssociatedObject([self getConsoleTextView], "LOCK_CHECK_BOX", nil, OBJC_ASSOCIATION_ASSIGN);
}

-(void)ignoreScrollToBottom {
    IDEConsoleTextView* textView = (IDEConsoleTextView*)self;
    NSButton* checkButton = objc_getAssociatedObject(textView, "LOCK_CHECK_BOX");
    
    if( checkButton.state != NSOnState ) {
        SEL sel = NSSelectorFromString(@"XCSL_scrollToBottom");
        [[[XcodeConsoleScrollLock sharedInstance] getConsoleTextView] performSelector:sel withObject:nil];
    }
}

-(void)activate:(NSNotification*)notification {
    IDEConsoleTextView* consoleTextView = [self getConsoleTextView];
    
    NSClipView* clipView = (NSClipView*)consoleTextView.superview;
    NSScrollView* scrollView = (NSScrollView*)consoleTextView.superview.superview;
    self.clipView = clipView;
    self.clipViewY = self.clipView.bounds.origin.y;
    self.scrollView = scrollView;
    
    [self addCheckbox];
}

-(void)addCheckbox {
    
    NSView* contentView = [[NSApp mainWindow] contentView];
    IDEConsoleTextView* consoleTextView = [self getConsoleTextView];
    contentView = [consoleTextView getParantViewByClassName:@"DVTControllerContentView"];
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
    IDEConsoleTextView* consoleTextView = (IDEConsoleTextView*)[contentView getViewByClassName:@"IDEConsoleTextView"];
    
    if( !consoleTextView ) {
        NSLog(@"IDEConsoleTextView is nil.");
    }
    return consoleTextView;
}

@end
