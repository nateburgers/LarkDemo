//
//  SDCircleView.m
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import "SDCircleView.h"

@implementation SDCircleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGPoint point;
    point.x = CGRectGetWidth(self.frame) / 2;
    point.y = CGRectGetHeight(self.frame) / 2;
    CGFloat size = CGRectGetWidth(self.frame);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 4.0);
    CGContextSetStrokeColorWithColor(context, [[self color] CGColor]);
    CGRect circle = CGRectMake(0, 0, size, size);
    CGContextAddEllipseInRect(context, circle);
    CGContextFillPath(context);
//    CGContextStrokePath(context);
}

@end
