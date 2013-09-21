//
//  SDFunView.h
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SDCircle;
@interface SDFunView : UIView

@property NSMutableArray *circles;
@property UIColor *color;

- (SDCircle *)addCircle;
- (SDCircle *)anyCircle;

- (void)update;

@end
