//
//  DemoAppAppDelegate.m
//  DemoApp
//
//  Created by Josh Abernathy on 11/23/10.
//  Copyright 2010 Maybe Apps, LLC. All rights reserved.
//

#import "DemoAppAppDelegate.h"
#import "DemoView.h"
#import "DemoSectionView.h"
#import "JAAnimatingContainer.h"

@interface DemoAppAppDelegate ()
@property (nonatomic, retain) NSMutableArray *listViews;
@property (nonatomic, retain) JAAnimatingContainer *container;
@end


@implementation DemoAppAppDelegate


#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.listView.backgroundColor = [NSColor darkGrayColor];
    [self.listView.scrollView.documentView scrollPoint:NSZeroPoint];
    self.listView.conditionallyUseLayerBacking = YES;
    
    static const NSUInteger numberOfSections = 10;
    for(NSUInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
        DemoSectionView *view = [DemoSectionView demoSectionView];
        view.text = [NSString stringWithFormat:@"Section %lu", (unsigned long) sectionIndex + 1];
        [self.sectionedListView addListViewItem:view forHeaderForSection:sectionIndex];
        
        static const NSUInteger numberOfViewsPerSection = 15;
        for(NSUInteger viewIndex = 0; viewIndex < numberOfViewsPerSection; viewIndex++) {
            DemoView *view = [DemoView demoView];
            view.text = [NSString stringWithFormat:@"Section %lu, Row %lu", (unsigned long) sectionIndex + 1, (unsigned long) viewIndex + 1];
            [self.sectionedListView addListViewItem:view inSection:sectionIndex atIndex:viewIndex];
        }
    }
    
    [self.sectionedListView reloadData];
    [self.sectionedListView.scrollView.documentView scrollPoint:NSZeroPoint];
    self.sectionedListView.conditionallyUseLayerBacking = YES;
        
    NSResponder *previousNextResponder = [self.window nextResponder];
    [self.window setNextResponder:self];
    [self setNextResponder:previousNextResponder];
    
    [self.window makeKeyAndOrderFront:nil];
}


#pragma mark JAListViewDelegate

- (void)listView:(JAListView *)list willSelectView:(JAListViewItem *)view {
    NSLog(@"will select");
    
    if(list == self.sectionedListView) {
        if([(JASectionedListView *) list isViewSectionHeaderView:view]) {
            return;
        }
    }
    
    DemoView *demoView = (DemoView *) view;
    demoView.selected = YES;
}

- (void)listView:(JAListView *)list didSelectView:(JAListViewItem *)view {
    NSLog(@"did select");
    
    if(list == self.sectionedListView) {
        if([(JASectionedListView *) list isViewSectionHeaderView:view]) {
            return;
        }
    }
    
    DemoView *demoView = (DemoView *) view;
    demoView.selected = YES;
    
    JAAnimatingContainer *newContainer = [JAAnimatingContainer containerFromView:demoView];
    [newContainer swapViewWithContainer];
    newContainer.didFinishBlock = ^(JAAnimatingContainer *container, CAAnimation *animation) {
        DemoView *demoView = (DemoView *) container.view;
        demoView.ignoreInListViewLayout = NO;
        [container swapContainerWithView];
    };
    
    CGFloat duration = ([self.window currentEvent].modifierFlags & NSShiftKeyMask) ? 10.0f : 0.7f;
	
    CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    rotateAnimation.toValue = [NSNumber numberWithFloat:360 * M_PI / 180.0f];
    rotateAnimation.duration = duration;
    
    CABasicAnimation *zoomAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    zoomAnimation.toValue = [NSValue valueWithPoint:NSMakePoint(1.4f, 1.4f)];
    zoomAnimation.speed = 2.0f;
    zoomAnimation.autoreverses = YES;
    
    CAAnimationGroup *animations = [[[CAAnimationGroup alloc] init] autorelease];
    animations.animations = [NSArray arrayWithObjects:rotateAnimation, zoomAnimation, nil];
    animations.duration = duration;
    [newContainer startAnimation:animations];
    
    demoView.ignoreInListViewLayout = YES;
}

- (void)listView:(JAListView *)list didUnSelectView:(JAListViewItem *)view {
    NSLog(@"did un-select");
    
    if(list == self.sectionedListView) {
        if([(JASectionedListView *) list isViewSectionHeaderView:view]) {
            return;
        }
    }
    
    DemoView *demoView = (DemoView *) view;
    demoView.selected = NO;
}


#pragma mark JAListViewDataSource

- (NSUInteger)numberOfItemsInListView:(JAListView *)listView {
    return self.listViews.count;
}

- (JAListViewItem *)listView:(JAListView *)listView viewAtIndex:(NSUInteger)index {
    return [self.listViews objectAtIndex:index];
}


#pragma mark API

@synthesize window;
@synthesize listView;
@synthesize container;
@synthesize listViews;
@synthesize sectionedListView;

- (void)demoViewWasDeleted:(DemoView *)demoView {
    JAAnimatingContainer *newContainer = [JAAnimatingContainer containerFromView:demoView];
    [newContainer swapViewWithContainer];
    newContainer.didFinishBlock = ^(JAAnimatingContainer *c, CAAnimation *animation) {
        [c.view setHidden:YES];
        [c swapContainerWithView];
        [self.sectionedListView removeListViewItem:demoView];
        [demoView.listView reloadDataAnimated:YES];
    };
    
    demoView.ignoreInListViewLayout = YES;
    
    CGFloat duration = ([self.window currentEvent].modifierFlags & NSShiftKeyMask) ? 10.0f : 0.7f;
	
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(CATransform3DMakeTranslation(0.0f, -1000.0f, 0.0f), 40.0f * 180 / M_PI, 0.0f, 0.0f, 1.0f)];
    animation.duration = duration;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    
    [newContainer startAnimation:animation];
}

- (NSMutableArray *)listViews {
    static const NSUInteger numberOfRows = 500;
    
    if(listViews == nil) {
        self.listViews = [NSMutableArray arrayWithCapacity:numberOfRows];
        
        for(NSUInteger row = 0; row < numberOfRows; row++) {
            DemoView *view = [DemoView demoView];
            view.text = [NSString stringWithFormat:@"Row %d", row + 1];
            [self.listViews addObject:view];
        }
    }
    
    return listViews;
}

@end
