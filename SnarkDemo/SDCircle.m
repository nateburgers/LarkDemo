//
//  SDCircle.m
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import "SDCircle.h"

@implementation SDCircle

- (id)init
{
    if (self = [super init]) {
        _color = [UIColor redColor];
        _size = @(arc4random() % 40 + 60);
        _x = @(arc4random() % 300);
        _y = @(arc4random() % 700);
        _dx = @(((NSInteger)(arc4random() % 200) - 100) / 100.f);
        _dy = @(((NSInteger)(arc4random() % 200) - 100) / 100.f);
    }
    return self;
}

@end
