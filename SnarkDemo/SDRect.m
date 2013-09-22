//
//  SDRect.m
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import "SDRect.h"

@implementation SDRect

- (id)initWithX:(NSNumber *)x y:(NSNumber *)y width:(NSNumber *)width height:(NSNumber *)height
{
    if (self = [super init]) {
        _x = x;
        _y = y;
        _width = width;
        _height = height;
    }
    return self;
}

- (CGRect)rect
{
    return CGRectMake(self.x.doubleValue, self.y.doubleValue,
                      self.width.doubleValue, self.height.doubleValue);
}

@end
