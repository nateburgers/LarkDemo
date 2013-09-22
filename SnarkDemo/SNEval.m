//
//  SNEval.m
//  Snark
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import <objc/runtime.h>
#import "SNExt.h"
#import "SNEval.h"

@implementation SNEval

#pragma mark - Procedures
+ (SNMetaProcedure)lambda
{
    return ^(NSMutableDictionary *env, NSArray *args){
#ifdef DEBUG
        NSParameterAssert([args count] == 2);
        NSParameterAssert([args[0] isKindOfClass:[NSArray class]]);
#endif
        return ^(NSMutableDictionary *lambdaEnv, NSArray *lambdaArgs){
            NSArray *lambdaArgumentSymbols = [self namesOfSymbols:args[0]];
            NSArray *lambdaArgumentValues = [self evaluateEach:lambdaArgs inContext:env];
            NSDictionary *lambdaBindings = [NSDictionary dictionaryWithObjects:lambdaArgumentValues
                                                                       forKeys:lambdaArgumentSymbols];
            NSMutableDictionary *localEnv = [self mergeDictionary:lambdaEnv withDictionary:lambdaBindings];
            return [self evaluate:args[1] inContext:localEnv];
        };
    };
}

+ (SNProcedure)define
{
    return ^(NSMutableDictionary *env, NSArray *args){
#ifdef DEBUG
        NSParameterAssert([args[0] isKindOfClass:[SNSymbol class]]);
#endif
        id value = [self evaluate:args[1] inContext:env];
        [env setObject:value forKey:[args[0] name]];
        return value;
    };
}

+ (SNProcedure)if
{
    return ^(NSMutableDictionary *env, NSArray *args){
#ifdef DEBUG
        NSParameterAssert([args count] == 3);
#endif
        NSNumber *value = [self evaluate:args[0] inContext:env];
        return [value boolValue]
        ? [self evaluate:args[1] inContext:env]
        : [self evaluate:args[2] inContext:env]
        ;
    };
}

+ (SNProcedure)quote
{
    return ^(NSMutableDictionary *env, NSArray *args){
        return args;
    };
}

+ (SNProcedure)defclass
{
    return ^(NSMutableDictionary *env, NSArray *args){
        SNSymbol *classSymbol = [self evaluate:args[0] inContext:env];
        Class superclass = [self evaluate:args[1] inContext:env];
        Class newclass = objc_allocateClassPair(superclass, [[classSymbol name] UTF8String], 0);
        for (NSUInteger i=2; i<[args count]; i++) {
            NSArray *nameValuePair = args[i];
            
//            SNSymbol *name = [self evaluate:nameValuePair[0] inContext:env];
            SNSymbol *name = nameValuePair[0];
            id value = [self evaluate:nameValuePair[1] inContext:env];
            
            if (class_isMetaClass(object_getClass(value))) {
                // it's a class
                Class ivarClass = object_getClass(value);
                class_addIvar(newclass, [[name name] UTF8String], sizeof(ivarClass), rint(log2(sizeof(ivarClass))), @encode(id));
                NSString *capSet = [[name name] stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[[name name] substringToIndex:1] capitalizedString]];
                NSString *setName = [NSString stringWithFormat:@"set%@:", capSet];
                
                Ivar ivar = class_getInstanceVariable(newclass, [[name name] UTF8String]);
                IMP getImp = imp_implementationWithBlock(^(id self){
                    id x = object_getIvar(self, ivar);
                    return x;
                });
                class_addMethod(newclass, NSSelectorFromString([name name]), getImp, [@"@@:v" UTF8String]);
                
                IMP setImp = imp_implementationWithBlock(^(id self, id value){
                    object_setIvar(self, ivar, value);
                    return value;
                });
                class_addMethod(newclass, NSSelectorFromString(setName), setImp, [@"@@:@" UTF8String]);
            } else {
                // it's a block
                IMP lambdaImp = imp_implementationWithBlock(^id(id self, id x){
                    SNProcedure block = value;
                    NSMutableDictionary *newEnv = [env mutableCopy];
                    [newEnv setObject:self forKey:@"self"];
                    return block(newEnv, @[x]);
                });
                // get arg count for the lambda
                NSString *idSig = [NSString stringWithUTF8String:@encode(id)];
                NSUInteger argc = [nameValuePair[1][1] count];
                NSString *args = [@"" stringByPaddingToLength:argc withString:idSig startingAtIndex:0];
                NSString *type = [NSString stringWithFormat:@"@@:%@", args];
                BOOL success = class_addMethod(newclass, NSSelectorFromString([name name]), lambdaImp, [type UTF8String]);
                if (!success) {
                    NSLog(@"oh no!");
                }
            }
//            class_addIvar(newclass, [[nameValuePair[0] name] UTF8String], sizeof(id),
//                          rint(log2(sizeof(id))), @encode(id));
        }
        objc_registerClassPair(newclass);
        return newclass;
    };
}

#pragma mark - Block Lifting
+ (SNProcedure)liftN:(id (^)(NSArray *))block
{
    return ^(NSMutableDictionary *env, NSArray *args){
        return block(args);
    };
}

+ (SNProcedure)lift1:(id (^)(id))block
{
    return ^(NSMutableDictionary *env, NSArray *args){
        return block(args[0]);
    };
}

+ (SNProcedure)lift2:(id (^)(id, id))block
{
    return ^(NSMutableDictionary *env, NSArray *args){
        return block(args[0], args[1]);
    };
}

+ (SNProcedure)lift3:(id (^)(id, id, id))block
{
    return ^(NSMutableDictionary *env, NSArray *args){
        return block(args[0], args[1], args[2]);
    };
}

#pragma mark - Tools
+ (id)deconstruct:(NSArray *)array withBlock:(id (^)(id, NSArray *))block
{
    id head = [array count] ? array[0] : nil ;
    NSArray *tail = [array count] ? [array subarrayWithRange:NSMakeRange(1, [array count]-1)] : @[] ;
    return block(head, tail);
}

+ (NSArray *)namesOfSymbols:(NSArray *)symbols
{
    NSMutableArray *result = [NSMutableArray array];
    for (SNSymbol *s in symbols) {
        [result addObject:[s name]];
    }
    return result;
}

+ (NSMutableDictionary *)mergeDictionary:(NSDictionary *)a withDictionary:(NSDictionary *)b
{
    NSMutableDictionary *result = [a mutableCopy];
    [result addEntriesFromDictionary:b];
    return result;
}

+ (NSUInteger)argumentsInSelectorName:(NSString *)selectorName
{
    NSUInteger count = 0;
    for (NSUInteger i=0; i<[selectorName length]; i++) {
        if ([selectorName characterAtIndex:i] == ':') {
            count++;
        }
    }
    return count;
}

#pragma mark - Runtime
+ (id)lookup:(SNSymbol *)symbol in:(NSDictionary *)dictionary
{
    if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[[symbol name] characterAtIndex:0]]) {
        return NSClassFromString([symbol name]) ?: symbol;
    } else {
        return [dictionary objectForKey:[symbol name]] ?: symbol;
    }
}

+ (NSSet *)specialFormSymbols
{
    return [NSSet setWithArray:@[@"define",
                                 @"lambda",
                                 @"if",
                                 @"quote",
                                 @"@class"
                                 ]];
}

+ (NSDictionary *)prelude
{
    return @{@"lambda": [self lambda],
             @"define": [self define],
             @"if": [self if],
             @"quote": [self quote],
             @"@class": [self defclass],
#pragma mark - Constants
             @"yes": @(YES),
             @"no": @(NO),
#pragma mark - Library Forms
             @"do": [self liftN:^id(NSArray *forms) {
                 return [forms lastObject];
             }],
             
             @"@": [self liftN:^id(NSArray *xs) {
#ifdef DEBUG
                 NSParameterAssert([xs count] >= 2);
#endif
                 id object = xs[0];
                 NSString *selectorName = [xs[1] name];
                 SEL selector = NSSelectorFromString(selectorName);
                 NSUInteger nargs = [self argumentsInSelectorName:selectorName];

                 NSMethodSignature *sig = [object methodSignatureForSelector:selector];
                 if (![object respondsToSelector:selector]) {
                     NSString *reason = [NSString stringWithFormat:@"%@ does not respond to %@", object, selectorName];
                     @throw [NSException exceptionWithName:@"LARKException" reason:reason userInfo:nil];
                 }
                 NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
                 [invocation setTarget:object];
                 [invocation setSelector:selector];
                 for (NSUInteger i=0; i<nargs; i++) {
                     id prop = xs[i+2];
                     [invocation setArgument:&prop atIndex:i+2];
                 }
                 [invocation retainArguments];
                 [invocation invoke];
                 if ([sig methodReturnLength] == 0) {
                     return nil;
                 } else {
                     CFTypeRef result;
                     [invocation getReturnValue:&result];
                     CFRetain(result);
                     return (__bridge_transfer id)result;
                 }
             }],
             
#pragma mark - Operators
             @"+": [self lift2:^id(NSNumber *a, NSNumber *b) {
                 return @([a doubleValue] + [b doubleValue]);
             }],
             
             @"-": [self lift2:^id(NSNumber *a, NSNumber *b) {
                 return @([a doubleValue] - [b doubleValue]);
             }],
             
             @"*": [self lift2:^id(NSNumber *a, NSNumber *b) {
                 return @([a doubleValue] * [b doubleValue]);
             }],
             
             @"/": [self lift2:^id(NSNumber *a, NSNumber *b) {
                 return @([a doubleValue] / [b doubleValue]);
             }],
             
             @"=": [self lift2:^id(id a, id b) {
                 return @([a isKindOfClass:[NSString class]] ? [(NSString *)a isEqualToString:b]
                 : [a isKindOfClass:[NSNumber class]] ? [(NSNumber *)a isEqualToNumber:b]
                 : [a isEqual:b]);
             }],
             
             @">": [self lift2:^id(id a, id b) {
                 return @([a compare:b] > 0);
             }],
             
             @"<": [self lift2:^id(id a, id b) {
                 return @([a compare:b] < 0);
             }]
             };
}

+ (id)evaluate:(id)expression inContext:(NSMutableDictionary *)context
{
    return [expression isKindOfClass:[NSString class]] ? expression
    : [expression isKindOfClass:[SNSymbol class]] ? [self lookup:expression in:context]
    : [expression isKindOfClass:[NSArray class]] ? [self evaluateArray:expression inContext:context]
    : expression
    ;
}

+ (id)evaluateArray:(NSArray *)array inContext:(NSMutableDictionary *)context
{
    return [self deconstruct:array withBlock:^id(SNSymbol *head, NSArray *arguments) {
#ifdef DEBUG
//        NSParameterAssert([head isKindOfClass:[SNSymbol class]]);
#endif
        SNProcedure proc = [self evaluate:head inContext:context];
        return [head isKindOfClass:[SNSymbol class]] && [[self specialFormSymbols] containsObject:[head name]]
        ? [self applySpecialForm:proc to:arguments inContext:context]
        : [self applyDerivedForm:proc to:arguments inContext:context]
        ;
    }];
}

+ (id)evaluateEach:(NSArray *)array inContext:(NSMutableDictionary *)context
{
    NSMutableArray *result = [NSMutableArray array];
    for (id element in array) {
        id value = [self evaluate:element inContext:context] ?: [NSNull null];
        [result addObject:value];
    }
    return result;
}

+ (id)applySpecialForm:(SNProcedure)f to:(NSArray *)arguments inContext:(NSMutableDictionary *)context
{
    return f(context, arguments);
}

+ (id)applyDerivedForm:(SNProcedure)f to:(NSArray *)arguments inContext:(NSMutableDictionary *)context
{
    return f(context, [self evaluateEach:arguments inContext:context]);
}

@end
