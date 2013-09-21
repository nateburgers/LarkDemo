//
//  SDAppDelegate.h
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SDREPLServer;
@class SDFunViewController;
@interface SDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property SDREPLServer *repl;
@property SDFunViewController *viewController;

- (void) loadScripts;

@end
