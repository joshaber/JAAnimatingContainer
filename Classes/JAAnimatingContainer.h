//
//  JAAnimatingContainer.h
//  ManyViewTest
//
//  Created by Josh Abernathy on 2/27/09.
//  Copyright 2009 Maybe Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class JAAnimatingContainer;

@protocol JAAnimatingContainerDelegate <NSObject>
@optional
- (void)animationContainer:(JAAnimatingContainer *)container didFinishAnimation:(CAAnimation *)animation;
@end


@interface JAAnimatingContainer : NSObject {}

+ (JAAnimatingContainer *)containerFromWindow:(NSWindow *)window;
+ (JAAnimatingContainer *)containerFromView:(NSView *)view;
+ (JAAnimatingContainer *)containerWithImage:(CGImageRef)image at:(NSPoint)loc;

- (id)initWithImage:(CGImageRef)image at:(NSPoint)loc;

- (void)swapViewWithContainer;
- (void)swapContainerWithView;

- (void)startAnimation:(CAAnimation *)animation forKey:(NSString *)key;
- (void)startAnimation:(CAAnimation *)animation;

- (void)flyTo:(NSPoint)loc;
- (void)scaleTo:(NSSize)scale;

@property (nonatomic, assign) id<JAAnimatingContainerDelegate> delegate;
@property (nonatomic, retain, readonly) CALayer *animationLayer;
@property (nonatomic, retain, readonly) NSView *view;
@property (nonatomic, copy) void (^didFinishBlock)(JAAnimatingContainer *container, CAAnimation *animation);
@property (nonatomic, readonly) NSWindow *hostWindow;

@end
