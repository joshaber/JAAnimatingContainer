//
//  DemoAppAppDelegate.h
//  DemoApp
//
//  Created by Josh Abernathy on 11/23/10.
//  Copyright 2010 Maybe Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JAListView.h"
#import "JAObjectListView.h"


@interface DemoAppAppDelegate : NSResponder <NSApplicationDelegate, JAListViewDelegate, JAListViewDataSource> {}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet JAListView *listView;
@property (assign) IBOutlet JAObjectListView *sectionedListView;

@end
