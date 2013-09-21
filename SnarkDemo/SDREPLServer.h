//
//  SDREPLServer.h
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDREPLServer : NSObject <NSStreamDelegate>

@property (readonly) NSInputStream *inputStream;
@property (readonly) NSOutputStream *outputStream;

- (void) writeString:(NSString *)string;

@end
