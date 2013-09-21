//
//  SNEval.h
//  Snark
//
//  Created by Nathan Burgers on 9/21/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^SNProcedure)(NSMutableDictionary *env, NSArray *arguments);
typedef SNProcedure (^SNMetaProcedure)(NSMutableDictionary *env, NSArray  *args);

@interface SNEval : NSObject
#pragma mark - Procedures
+ (SNMetaProcedure) lambda;
+ (SNProcedure) define;
+ (SNProcedure) if;
+ (SNProcedure) quote;
+ (SNProcedure) defclass;
#pragma mark - Block Lifting
+ (SNProcedure) liftN:(id (^)(NSArray * xs))block;
+ (SNProcedure) lift1:(id (^)(id a))block;
+ (SNProcedure) lift2:(id (^)(id a, id b))block;
+ (SNProcedure) lift3:(id (^)(id a, id b, id c))block;
#pragma mark - Tools
+ (id) deconstruct:(NSArray *)array withBlock:(id(^)(id head, NSArray *tail))block;
+ (NSArray *)namesOfSymbols:(NSArray *)symbols;
+ (NSMutableDictionary *) mergeDictionary:(NSDictionary *)a withDictionary:(NSDictionary *)b;
+ (NSUInteger) argumentsInSelectorName:(NSString *)selectorName;
#pragma mark - Runtime
+ (id) lookup:(SNSymbol *)symbol in:(NSMutableDictionary *)dictionary;
+ (NSSet *) specialFormSymbols;
+ (NSDictionary *) prelude;
#pragma mark - Evaluation
+ (id) evaluate:(id)expression inContext:(NSMutableDictionary *)context;
+ (id) evaluateArray:(NSArray *)array inContext:(NSMutableDictionary *)context;
+ (id) evaluateEach:(NSArray *)array inContext:(NSMutableDictionary *)context;
+ (id) applySpecialForm:(SNProcedure)f to:(NSArray *)arguments inContext:(NSMutableDictionary *)context;
+ (id) applyDerivedForm:(SNProcedure)f to:(NSArray *)arguments inContext:(NSMutableDictionary *)context;
@end