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
        self.originalMethod = class_getInstanceMethod([IDEConsoleTextView class], @selector(_scrollToBottom));
        self.overrideMethod = class_getInstanceMethod([self class], @selector(ignoreScrollToBottom));
        SEL selector = NSSelectorFromString(@"XCSL_scrollToBottom");
        NSLog(@"%s", method_getTypeEncoding(self.originalMethod));
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
    NSLog(@"XcodeConsoleScrollLock launching!!");
}

-(void)applicationWillTerminate:(NSNotification*)noti {
    NSLog(@"XcodeConsoleScrollLock terminate!!");
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
    [consoleTextView setPostsBoundsChangedNotifications:YES];
    NSClipView* clipView = (NSClipView*)consoleTextView.superview;
    NSScrollView* scrollView = (NSScrollView*)consoleTextView.superview.superview;
    self.clipView = clipView;
    self.clipViewY = self.clipView.bounds.origin.y;
    self.scrollView = scrollView;
    NSLog(@"scrollView=%@", scrollView);
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewWillStartScroll:) name:NSScrollViewWillStartLiveScrollNotification object:scrollView];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollDidScroll:)		name:NSScrollViewDidLiveScrollNotification object:scrollView];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollDidEnd:)		name:NSScrollViewDidEndLiveScrollNotification object:scrollView];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangedBounds:)		name:NSViewBoundsDidChangeNotification object:clipView];
    
    [self addCheckbox];
    
    NSLog(@"consoleTextView=%@", consoleTextView);
}

-(void)addCheckbox {
    NSView* contentView = [[NSApp mainWindow] contentView];
    IDEConsoleTextView* consoleTextView = [self getConsoleTextView];
    contentView = [consoleTextView getParantViewByClassName:@"DVTControllerContentView"];
    NSView* scopeBarView = [contentView getViewByClassName:@"DVTScopeBarView"];
    if( !scopeBarView ) {
        return;
    }
    NSLog(@"scopeBarView");
    
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
        return;
    }
    NSLog(@"button=%@", button);
    
    NSButton* checkButton = [[NSButton alloc] initWithFrame:NSMakeRect(
                                                                       filterButton.frame.origin.x + 150,
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
//        method_exchangeImplementations(self.overrideMethod, self.originalMethod);
    } else if(button.state == NSOnState ) {
        self.lockState = ScrollLockStateLock;
//       method_exchangeImplementations(self.originalMethod, self.overrideMethod);
//        self.clipViewY = self.clipView.bounds.origin.y;
    }
}

-(void)print:(NSScrollView*)scrollView {
//    NSLog(@"lineScroll=%f", scrollView.lineScroll);
//    NSLog(@"verticalLineScroll=%f", scrollView.verticalLineScroll);
//    NSLog(@"pageScroll=%f", scrollView.pageScroll);
//    NSLog(@"verticalPageScroll=%f", scrollView.verticalPageScroll);
//    NSLog(@"scroller=%@", scrollView.verticalScroller);
//    NSLog(@"bounds=%f", self.clipView.bounds.origin.y);
}

-(void)scrollViewWillStartScroll:(NSNotification*)notification {
    NSScrollView* scrollView = (NSScrollView*)notification.object;
    if( scrollView != self.scrollView ) {
        return;
    }
    if(self.lockState == ScrollLockStateLock ) {
        self.lockState = ScrollLockStateTemporaryScrollable;
    }
//    NSLog(@"");
    [self print:scrollView];
}

-(void)scrollDidScroll:(NSNotification*)notification {
    NSScrollView* scrollView = (NSScrollView*)notification.object;
    if( scrollView != self.scrollView ) {
        return;
    }
    if(self.lockState == ScrollLockStateTemporaryScrollable) {
        self.clipViewY = self.clipView.bounds.origin.y;
        self.lockState = ScrollLockStateScrollable;
    }
//    NSLog(@"");
    
    [self print:scrollView];
}

-(void)scrollDidEnd:(NSNotification*)notification {
    NSScrollView* scrollView = (NSScrollView*)notification.object;
    if( scrollView != self.scrollView ) {
        return;
    }
//    if(self.isLocked == ScrollLockStateTemporaryScrollable) {
//        self.clipViewY = self.clipView.bounds.origin.y;
//        self.isLocked = ScrollLockStateScrollable;
//    }
//    NSLog(@"");
    [self print:scrollView];
}

-(void)didChangedBounds:(NSNotification*)notification {
    NSClipView* clipView = notification.object;
    if( clipView != self.clipView ) {
        return;
    }
    
    if( self.lockState == ScrollLockStateLock ) {
        CGRect bounds = clipView.bounds;
        bounds.origin.y = self.clipViewY;
        clipView.bounds = bounds;
//        NSLog(@"bounds=%f", clipView.bounds.origin.y);
    }
}

-(IDEConsoleTextView*)getConsoleTextView {
    
    NSView* contentView = [[NSApp mainWindow] contentView];
    NSLog(@"contentView = %@", [contentView descriptionViews]);
    IDEConsoleTextView* consoleTextView = (IDEConsoleTextView*)[contentView getViewByClassName:@"IDEConsoleTextView"];
    
    if( !consoleTextView ) {
        NSLog(@"IDEConsoleTextView is nil.");
    }
    return consoleTextView;
}

@end
