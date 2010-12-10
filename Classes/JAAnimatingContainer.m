//
//  JAAnimatingContainer.m
//  ManyViewTest
//
//  Created by Josh Abernathy on 2/27/09.
//  Copyright 2009 Maybe Apps. All rights reserved.
//

#import "JAAnimatingContainer.h"

static NSCountedSet *animatingContainers = nil;
static NSWindow *fullScreenWindow = nil;


@interface JAAnimatingContainer ()
- (CAAnimation *)flyAnimationTo:(NSPoint)loc;
- (CAAnimation *)scaleAnimationTo:(NSSize)scale;

@property (nonatomic, retain) NSView *originalSuperview;
@property (nonatomic, retain) NSWindow *originalWindow;
@property (nonatomic, assign) NSRect originalFrame;
@property (nonatomic, retain) CALayer *animationLayer;
@property (nonatomic, retain) NSView *view;
@end


@implementation JAAnimatingContainer

+ (void)initialize {
    if(self == [JAAnimatingContainer class]) {
        NSRect frame = NSZeroRect;
        for(NSScreen *screen in [NSScreen screens]) {
            frame = NSUnionRect(frame, screen.frame);
        }
        
        fullScreenWindow = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        
        [fullScreenWindow setOpaque:NO];
        [fullScreenWindow setMovableByWindowBackground:NO];
        [fullScreenWindow setIgnoresMouseEvents:YES];
        
        fullScreenWindow.hasShadow = NO;
        fullScreenWindow.backgroundColor = [NSColor clearColor];
        
        [fullScreenWindow.contentView setLayer:[CALayer layer]];
        [fullScreenWindow.contentView setWantsLayer:YES];
        
        [fullScreenWindow orderFrontRegardless];
        
        animatingContainers = [NSCountedSet set];
    }
}

- (void)dealloc {
    self.originalSuperview = nil;
    self.originalWindow = nil;
    self.animationLayer = nil;
    self.view = nil;
    self.delegate = nil;
    self.didFinishBlock = nil;
    
    [super dealloc];
}


#pragma mark CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
    BOOL didHandleCompletion = NO;
    if(self.didFinishBlock != nil) {
        didHandleCompletion = YES;
        __block JAAnimatingContainer *safeSelf = self;
        self.didFinishBlock(safeSelf, animation);
    }
    
    if([self.delegate respondsToSelector:@selector(animationContainer:didFinishAnimation:)]) {
        didHandleCompletion = YES;
        [self.delegate animationContainer:self didFinishAnimation:animation];
    }
    
    if(!didHandleCompletion) {
        [self swapContainerWithView];
    }
    
    [animatingContainers removeObject:self];
}


#pragma mark API

+ (JAAnimatingContainer *)containerFromWindow:(NSWindow *)window {
    return [self containerFromView:[[window contentView] superview]];
}

+ (JAAnimatingContainer *)containerFromView:(NSView *)view {
	NSBitmapImageRep *bitmap = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
	[view cacheDisplayInRect:view.bounds toBitmapImageRep:bitmap];
	
	NSPoint location = [view.window convertBaseToScreen:[view convertPoint:view.bounds.origin toView:nil]];
	JAAnimatingContainer *container = [JAAnimatingContainer containerWithImage:bitmap.CGImage at:location];
	container.view = view;
	container.originalWindow = view.window;
    container.originalSuperview = view.superview;
    container.originalFrame = view.frame;
	return container;
}

+ (JAAnimatingContainer *)containerWithImage:(CGImageRef)image at:(NSPoint)loc {
	return [[[JAAnimatingContainer alloc] initWithImage:image at:loc] autorelease];
}

- (id)initWithImage:(CGImageRef)image at:(NSPoint)loc {
    self = [super init];
    if(self == nil) return nil;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    self.animationLayer = [CALayer layer];
	self.animationLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
	
	CGRect rect = NSZeroRect;
	rect.size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
	rect.origin = NSPointToCGPoint([self.hostWindow convertScreenToBase:loc]);
    rect = CGRectIntegral(rect);
	self.animationLayer.frame = rect;
	self.animationLayer.contents = (id) image;
	self.animationLayer.shadowColor = CGColorCreateGenericGray(0.5f, 1.0f);
	self.animationLayer.shadowOffset = CGSizeMake(0, -2);
	self.animationLayer.shadowRadius = 2.0;
	self.animationLayer.shadowOpacity = 0.8f;

	[[self.hostWindow.contentView layer] addSublayer:self.animationLayer];
    [CATransaction commit];
    
    return self;
}

- (void)flyTo:(NSPoint)loc {	
	[self startAnimation:[self flyAnimationTo:loc]];
}

- (void)scaleTo:(NSSize)scale {	
	[self startAnimation:[self scaleAnimationTo:scale]];
}

- (void)startAnimation:(CAAnimation *)animation forKey:(NSString *)key {
    animation.delegate = self;
    [animatingContainers addObject:self];
    
	[self.animationLayer addAnimation:animation forKey:key];
}

- (void)startAnimation:(CAAnimation *)animation {
    CFUUIDRef uuid = (CFUUIDRef) NSMakeCollectable(CFUUIDCreate(NULL));
    NSString *uuidString = NSMakeCollectable(CFUUIDCreateString(NULL, uuid));
    [self startAnimation:animation forKey:uuidString];
}

- (void)swapViewWithContainer {
	if(self.view == nil) return;
	
	NSDisableScreenUpdates();
	[self.view removeFromSuperview];
    [self.hostWindow setLevel:self.originalWindow.level + 1];
    [self.hostWindow display];
	NSEnableScreenUpdates();
}

- (void)swapContainerWithView {
	if(self.view == nil) return;
	
	NSDisableScreenUpdates();
    self.view.frame = self.originalFrame;
	[self.originalSuperview addSubview:self.view];
    [self.originalWindow display];
    [self.animationLayer removeFromSuperlayer];
	NSEnableScreenUpdates();
}

- (CAAnimation *)flyAnimationTo:(NSPoint)loc {
	static const CGFloat DEFAULT_DURATION = 0.7f;
	
	const CFTimeInterval duration = ([self.hostWindow currentEvent].modifierFlags & NSShiftKeyMask) ? 10.0f : DEFAULT_DURATION;
	
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.toValue = [NSValue valueWithPoint:loc];
    animation.duration = duration;
	animation.fillMode = kCAFillModeForwards;
	animation.removedOnCompletion = NO;
	animation.delegate = self;

	return animation;
}

- (CAAnimation *)scaleAnimationTo:(NSSize)scale {
	static const CGFloat DEFAULT_DURATION = 0.7f;
	
	const CFTimeInterval duration = ([self.hostWindow currentEvent].modifierFlags & NSShiftKeyMask) ? 10.0f : DEFAULT_DURATION;
	
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scale.width, scale.height, 1.0f)];
    animation.duration = duration;
	animation.fillMode = kCAFillModeForwards;
	animation.removedOnCompletion = NO;
	animation.delegate = self;

	return animation;
}

- (NSWindow *)hostWindow {
    return fullScreenWindow;
}

@synthesize delegate;
@synthesize originalSuperview;
@synthesize originalWindow;
@synthesize animationLayer;
@synthesize view;
@synthesize originalFrame;
@synthesize didFinishBlock;

@end
