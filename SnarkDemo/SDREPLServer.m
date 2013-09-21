//
//  SDREPLServer.m
//  SnarkDemo
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import "SDREPLServer.h"
#import "SNExt.h"
#import "SNEval.h"
#import "sys/socket.h"

@interface SDREPLServer ()
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    NSMutableDictionary *_environment;
}
@end

@implementation SDREPLServer

- (id)init
{
    if (self = [super init]) {
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"127.0.0.1", 13370, &readStream, &writeStream);
        _inputStream = (__bridge NSInputStream *)readStream;
        _outputStream = (__bridge NSOutputStream *)writeStream;
        [_inputStream setDelegate:self];
        [_outputStream setDelegate:self];
        [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_inputStream open];
        [_outputStream open];
        
        _environment = [[SNEval prelude] mutableCopy];
        _stringBuffer = [NSMutableString string];
    }
    return self;
}

- (void)writeString:(NSString *)string
{
    [[self outputStream] write:[[string dataUsingEncoding:NSASCIIStringEncoding] bytes] maxLength:[string length]];
}

- (id)evaluateString:(NSString *)string
{
    NSArray *results = [SNExt symbolicExpression]([SNExt stringToArray:string]);
    SNParseResult *parseResult = [results lastObject]; // more likely to have the string form we want
    return [SNEval evaluate:[parseResult result] inContext:[self environment]];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventEndEncountered:
            NSLog(@"eof");
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"error");
            break;
        case NSStreamEventHasBytesAvailable:
            NSLog(@"%@", aStream);
            if (aStream == [self inputStream]) {
                uint8_t buffer[1024*10];
                int len;
                while ([[self inputStream] hasBytesAvailable]) {
                    len = [[self inputStream] read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        [[self stringBuffer] appendString:[[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding]];
                    }
                }
            }
            NSLog(@"current string: %@", [self stringBuffer]);
            if (![[self stringBuffer] isEqualToString:@""]) {
                [self writeString:[NSString stringWithFormat:@"%@\n", [[self evaluateString:[self stringBuffer]] description]]];
                [[self stringBuffer] deleteCharactersInRange:NSMakeRange(0, [[self stringBuffer] length])];
            }
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

@end
