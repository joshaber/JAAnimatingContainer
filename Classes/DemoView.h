//
//  DemoView.h
//  JAListView
//
//  Created by Josh Abernathy on 9/29/10.
//  Copyright 2010 Maybe Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JAListViewItem.h"

@class DemoView;

@interface NSResponder (DemoViewExtensions)
- (void)demoViewWasDeleted:(DemoView *)demoView;
@end


@interface DemoView : JAListViewItem {}

+ (DemoView *)demoView;

- (IBAction)deleteView:(id)sender;

@property (nonatomic, copy) NSString *text;
@property (assign) IBOutlet NSTextField *textField;
@property (assign) IBOutlet NSTextField *shadowTextField;
@property (assign) IBOutlet NSButton *deleteButton;

@end
