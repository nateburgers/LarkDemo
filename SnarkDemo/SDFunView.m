//
//  SDFunView.m
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import "SDFunView.h"
#import "SDCircle.h"

@implementation SDFunView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _circles = [NSMutableArray array];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (SDCircle *circle in [self circles]) {
        [[circle color] setFill];
        CGFloat size = circle.size.doubleValue;
        CGFloat x = circle.x.doubleValue - (size / 2);
        CGFloat y = circle.y.doubleValue - (size / 2);
        CGRect rect = CGRectMake(x, y, size, size);
        CGContextFillEllipseInRect(context, rect);
    }
}

- (SDCircle *)addCircle
{
    SDCircle *circle = [[SDCircle alloc] init];
    circle.x = @(arc4random() % (NSUInteger)CGRectGetWidth(self.frame));
    circle.y = @(arc4random() % (NSUInteger)CGRectGetHeight(self.frame));
    [[self circles] addObject:circle];
    return circle;
}

- (SDCircle *)anyCircle
{
    NSUInteger index = arc4random() % [[self circles] count];
    return [[self circles] objectAtIndex:index];
}

- (void)update
{
//    @synchronized([self circles]){
        for (SDCircle *circle in [self circles]) {
//            @synchronized(circle){
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    circle.x = @([[circle x] doubleValue] + [[circle dx] doubleValue]);
                    circle.y = @([[circle y] doubleValue] + [[circle dy] doubleValue]);
                    
                    if ([circle.x doubleValue] < 0.f) circle.dx = @(-[circle.dx doubleValue]);
                    if ([circle.y doubleValue] < 0.f) circle.dy = @(-[circle.dy doubleValue]);
                    if ([circle.x doubleValue] > CGRectGetWidth(self.frame)) {
                        circle.dx = @(-[circle.dx doubleValue]);
                    }
                    if ([circle.y doubleValue] > CGRectGetHeight(self.frame)) {
                        circle.dy = @(-[circle.dy doubleValue]);
                    }
                });
//            }
        }
//    }
}
@end
