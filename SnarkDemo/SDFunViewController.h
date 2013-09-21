//
//  SDFunViewController.h
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

@class SDCircle;
@class SDFunView;
@interface SDFunViewController : UIViewController

@property SDFunView *funView;
@property NSMutableSet *circles;
@property UIColor *color;
@property NSNumber *running;

- (SDCircle *)addCircle;
- (SDCircle *)anyCircle;

- (void) start;
- (void) update;

@end
