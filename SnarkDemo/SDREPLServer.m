//
//  SDREPLServer.m
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import "SDREPLServer.h"

@interface SDREPLServer ()
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
}
@end

@implementation SDREPLServer

- (id)init
{
    if (self = [super init]) {
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"localhost", 8337, &readStream, &writeStream);
        _inputStream = (__bridge NSInputStream *)readStream;
        _outputStream = (__bridge NSOutputStream *)writeStream;
        [_inputStream setDelegate:self];
        [_outputStream setDelegate:self];
        [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_inputStream open];
        [_outputStream open];
    }
    return self;
}

- (void)writeString:(NSString *)string
{
    [[self outputStream] write:[[string dataUsingEncoding:NSUTF8StringEncoding] bytes] maxLength:[string length]];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (aStream == [self inputStream]) {
        switch (eventCode) {
            case NSStreamEventEndEncountered:
                break;
            case NSStreamEventErrorOccurred:
                break;
            case NSStreamEventHasBytesAvailable:
                break;
            case NSStreamEventHasSpaceAvailable:
                break;
            case NSStreamEventNone:
                break;
            case NSStreamEventOpenCompleted:
                break;
            default:
                break;
        }
    }
}

@end
