//
//  XcodeConsoleScrollLock.m
//  XcodeConsoleScrollLock
//
//  Created by Muronaka Hiroaki on 2015/08/22.
//  Copyright (c) 2015年 Muronaka Hiroaki. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "XcodeConsoleScrollLock.h"
#import "XCodeComponent.h"
#import "NSView+getViewByClassName.h"
#import <objc/runtime.h>

#define NSLog(format, ...) NSLog(@"XcodeConsoleScrollLock:%4d " format, __LINE__, ##__VA_ARGS__)

@interface XcodeConsoleScrollLock()

@property(nonatomic, weak) NSScrollView* scrollView;
@property(nonatomic, weak) NSClipView* clipView;
@property(nonatomic, assign) CGFloat clipViewY;

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
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

-(void)activate:(NSNotification*)notification {
    IDEConsoleTextView* consoleTextView = [self getConsoleTextView];
    [consoleTextView setPostsBoundsChangedNotifications:YES];
    NSClipView* clipView = (NSClipView*)consoleTextView.superview;
    NSScrollView* scrollView = (NSScrollView*)consoleTextView.superview.superview;
    self.clipView = clipView;
    self.clipViewY = self.clipView.bounds.origin.y;
    self.scrollView = scrollView;
    NSLog(@"scrollView=%@", scrollView);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewWillStartScroll:) name:NSScrollViewWillStartLiveScrollNotification object:scrollView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollDidScroll:)		name:NSScrollViewDidLiveScrollNotification object:scrollView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollDidEnd:)		name:NSScrollViewDidEndLiveScrollNotification object:scrollView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangedBounds:)		name:NSViewBoundsDidChangeNotification object:clipView];
    
    NSLog(@"consoleTextView=%@", consoleTextView);
}

-(void)print:(NSScrollView*)scrollView {
    NSLog(@"lineScroll=%f", scrollView.lineScroll);
    NSLog(@"verticalLineScroll=%f", scrollView.verticalLineScroll);
    NSLog(@"pageScroll=%f", scrollView.pageScroll);
    NSLog(@"verticalPageScroll=%f", scrollView.verticalPageScroll);
    NSLog(@"scroller=%@", scrollView.verticalScroller);
    NSLog(@"bounds=%f", self.clipView.bounds.origin.y);
}

-(void)scrollViewWillStartScroll:(NSNotification*)notification {
    NSScrollView* scrollView = (NSScrollView*)notification.object;
    if( scrollView != self.scrollView ) {
        return;
    }
    self.clipViewY = self.clipView.bounds.origin.y;
    NSLog(@"");
    [self print:scrollView];
}

-(void)scrollDidScroll:(NSNotification*)notification {
    NSScrollView* scrollView = (NSScrollView*)notification.object;
    if( scrollView != self.scrollView ) {
        return;
    }
    NSLog(@"");
    [self print:scrollView];
}

-(void)scrollDidEnd:(NSNotification*)notification {
    NSScrollView* scrollView = (NSScrollView*)notification.object;
    if( scrollView != self.scrollView ) {
        return;
    }
    NSLog(@"");
    [self print:scrollView];
}

-(void)didChangedBounds:(NSNotification*)notification {
    NSClipView* clipView = notification.object;
    if( clipView != self.clipView ) {
        return;
    }
    CGRect bounds = clipView.bounds;
    bounds.origin.y = self.clipViewY;
    clipView.bounds = bounds;
    NSLog(@"bounds=%f", clipView.bounds.origin.y);
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
