//
//  SDRect.h
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDRect : NSObject

@property NSNumber *width;
@property NSNumber *height;
@property NSNumber *x;
@property NSNumber *y;

- (id) initWithX:(NSNumber *)x y:(NSNumber *)y width:(NSNumber *)width height:(NSNumber *)height;

- (CGRect) rect;

@end
