//
//  SNExt.m
//  Snark
//
//  Created by Nathan Burgers on 9/20/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import "SNExt.h"

#define LAZY_PARSER(block) ^(NSArray *sequence){ return (block)(sequence); }

#pragma mark - Parse Results
@implementation SNParseResult
+ (instancetype)result:(id)result andRemainder:(NSArray *)remainder
{
    return [[self alloc] initWithResult:result andRemainder:remainder];
}
- (id)initWithResult:(id)result andRemainder:(NSArray *)remainder
{
    if (self = [super init]) {
        _result = result;
        _remainder = remainder;
    }
    return self;
}
- (NSString *)description
{
    return [NSString stringWithFormat:@"{result: %@, remainder: %@}", self.result, self.remainder];
}
@end

@implementation SNSymbol
+ (instancetype)symbolWithName:(NSString *)name
{
    return [[self alloc] initWithName:name];
}
- (id)initWithName:(NSString *)name
{
    if (self = [super init]) {
        _name = name;
    }
    return self;
}
- (NSString *)description
{
    return [[self name] description];
}
@end

#pragma mark - Parser Combinators
@implementation SNExt
#pragma mark - Data Structuring
+ (NSArray *)stringToArray:(NSString *)string
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSUInteger i=0; i<[string length]; i++) {
        [result addObject:[string substringWithRange:NSMakeRange(i, 1)]];
    }
    return result;
}
// I'm sorry about this one:
+ (id)reStringify:(NSArray *)array
{
    if ([array[0] isKindOfClass:[NSString class]]) {
        NSMutableString *string = [NSMutableString string];
        for (NSString *substring in array) {
            [string appendString:substring];
        }
        return string;
    } else {
        NSMutableArray *result = [NSMutableArray array];
        for (id element in array) {
            if ([element isKindOfClass:[NSArray class]]) {
                [result addObject:[self reStringify:element]];
            } else {
                [result addObject:element];
            }
        }
        return result;
    }
}
+ (id)destruct:(NSArray *)array withBlock:(id (^)(id, NSArray *))block
{
    id head = [array count] ? array[0] : nil ;
    NSArray *tail = [array count] ? [array subarrayWithRange:NSMakeRange(1, [array count]-1)] : @[];
    return block(head, tail);
}
+ (NSArray *(^)(id))wrap
{
    return ^(id x){
        return @[x];
    };
}
+ (NSArray *(^)(NSArray *))cons
{
    return ^(NSArray *headAndTail){
#ifdef DEBUG
        NSParameterAssert([headAndTail count] == 2);
        NSParameterAssert([headAndTail[1] isKindOfClass:[NSArray class]]);
#endif
        return [[NSArray arrayWithObject:headAndTail[0]] arrayByAddingObjectsFromArray:headAndTail[1]];
    };
}
+ (id)fold:(NSArray *)array withBlock:(ConcatenateBlock)block
{
    return [self destruct:array withBlock:^id(id head, NSArray *tail) {
        id result = head;
        for (id element in tail) {
            result = block(result, element);
        }
        return result;
    }];
}
#pragma mark - Monad Implementation
+ (ParserCombinator)unit:(id)unit
{
    return ^(NSArray *sequence){
        return @[[SNParseResult result:unit andRemainder:sequence]];
    };
}
+ (ParserCombinator)zero
{
    return ^(NSArray *sequence){
        return @[];
    };
}
+ (ParserCombinator)bind:(ParserCombinator)f with:(ParserGenerator)g
{
    return ^(NSArray *sequence){
        NSMutableArray *results = [NSMutableArray array];
        NSArray *resultsOfF = f(sequence);
        for (SNParseResult *result in resultsOfF) {
            [results addObjectsFromArray:g(result.result)(result.remainder)];
        }
        return results;
    };
}
+ (ParserCombinator) item
{
    return ^(NSArray *sequence){
        return [self destruct:sequence withBlock:^id(id head, NSArray *tail) {
            return head == nil
            ? [self zero](sequence)
            : [self unit:head](tail)
            ;
        }];
    };
}
+ (ParserCombinator)parse:(ParserCombinator)f using:(TransformBlock)t
{
    return [self bind:f with:^ParserCombinator(id previousResult) {
        return [self unit:t(previousResult)];
    }];
}
#pragma mark - Parser Generators
+ (ParserCombinator)or:(ParserCombinator)f with:(ParserCombinator)g
{
    return ^(NSArray *sequence){
        return [f(sequence) arrayByAddingObjectsFromArray:g(sequence)];
    };
}
+ (ParserCombinator)or:(NSArray *)combinators
{
    return [self fold:combinators withBlock:^id (ParserCombinator f, ParserCombinator g) {
        return [self or:f with:g];
    }];
}
+ (ParserCombinator)and:(ParserCombinator)f with:(ParserCombinator)g
{
    return [self bind:f with:^ParserCombinator(id resultOfF) {
        return [self bind:g with:^ParserCombinator(id resultOfG) {
            return [self unit:@[resultOfF, resultOfG]];
        }];
    }];
}
+ (ParserCombinator)and:(NSArray *)combinators
{
    return [self destruct:combinators withBlock:^id(ParserCombinator head, NSArray *tail) {
        if ([tail count]) {
            return [self and:head with:[self and:tail]];
        } else {
            return [self parse:head using:[self wrap]];
        }
    }];
}
+ (ParserCombinator)many:(ParserCombinator)f
{
    return LAZY_PARSER([self or:[self parse:f using:[self wrap]]
                           with:[self parse:[self and:f
                                                 with:[self many:f]]
                                      using:[self cons]]]);
}
+ (ParserCombinator)use:(ParserCombinator)f ignore:(ParserCombinator)g
{
    return [self bind:f with:^ParserCombinator(id resultOfF) {
        return [self bind:g with:^ParserCombinator(id resultOfG) {
            return [self unit:resultOfF];
        }];
    }];
}
+ (ParserCombinator)use:(ParserCombinator)f ignoreAny:(ParserCombinator)g
{
    return [self or:f with:[self use:f ignore:g]];
}
+ (ParserCombinator)ignore:(ParserCombinator)f use:(ParserCombinator)g
{
    return [self bind:f with:^ParserCombinator(id resultOfF) {
        return [self bind:g with:^ParserCombinator(id resultOfG) {
            return [self unit:resultOfG];
        }];
    }];
}
+ (ParserCombinator)ignoreAny:(ParserCombinator)f use:(ParserCombinator)g
{
    return [self or:g with:[self ignore:f use:g]];
}
+ (ParserCombinator)sat:(BOOL (^)(id))predicate
{
    return [self bind:[self item] with:^ParserCombinator(id previousResult) {
        return predicate(previousResult) ? [self unit:previousResult] : [self zero] ;
    }];
}
#pragma mark - Higher Order Generators
+ (ParserCombinator)separate:(ParserCombinator)f by:(ParserCombinator)g
{
    return [self parse:[self and:f with:[self many:[self ignore:g use:f]]]
                 using:[self cons]];
}
+ (ParserCombinator)character:(unichar)character
{
    return [self sat:^BOOL(NSString *element) {
#ifdef DEBUG
        NSParameterAssert([element isKindOfClass:[NSString class]]);
        NSParameterAssert([element length] == 1);
#endif
        return [element characterAtIndex:0] == character;
    }];
}
+ (ParserCombinator)characterInSet:(NSCharacterSet *)set
{
    return [self sat:^BOOL(NSString *element) {
#ifdef DEBUG
        NSParameterAssert([element isKindOfClass:[NSString class]]);
        NSParameterAssert([element length] == 1);
#endif
        return [set characterIsMember:[element characterAtIndex:0]];
    }];
}
#pragma mark - Parsers
+ (ParserCombinator)anychar
{
    return [self item];
}
+ (ParserCombinator)letter
{
    return [self characterInSet:[NSCharacterSet letterCharacterSet]];
}
+ (ParserCombinator)digit
{
    return [self characterInSet:[NSCharacterSet decimalDigitCharacterSet]];
}
+ (ParserCombinator)dot
{
    return [self character:'.'];
}
+ (ParserCombinator)quote
{
    return [self character:'\"'];
}
+ (ParserCombinator)whitespace
{
    return [self many:[self characterInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}
#pragma mark - Multi Character Parsers
+ (ParserCombinator)word
{
    return [self many:[self letter]];
}
+ (ParserCombinator)identifier
{
    return [self many:[self or:@[[self characterInSet:[NSCharacterSet characterSetWithCharactersInString:@"!@#$%^&*<>?-_+=\\|;:'"]],
                                 [self letter]]]];
}
+ (ParserCombinator)integer
{
    return [self many:[self digit]];
}
+ (ParserCombinator)decimal
{
    return [self and:[self integer] with:[self ignore:[self dot] use:[self integer]]];
}
+ (ParserCombinator)string
{
    return [self ignore:[self quote]
                    use:[self use:[self many:[self anychar]]
                           ignore:[self quote]]];
}
+ (ParserCombinator)surround:(ParserCombinator)f with:(ParserCombinator)g and:(ParserCombinator)h
{
    return [self ignore:[self use:g
                        ignoreAny:[self whitespace]]
                    use:[self use:[self or:@[[self parse:f
                                                   using:[self wrap]],
                                             [self separate:f
                                                         by:[self whitespace]]]]
                           ignore:[self ignoreAny:[self whitespace]
                                              use:h]]];
}
#pragma mark - Built In Grammars
+ (ParserCombinator)symbolicExpression

{
    return ^(NSArray *sequence){
        return [self or:@[[self parse:[self identifier] using:[self constructSymbol]],
                          [self parse:[self integer] using:[self constructInteger]],
                          [self parse:[self decimal] using:[self constructNumber]],
                          [self parse:[self string] using:[self constructString]],
                          [self surround:[self symbolicExpression]
                                    with:[self character:'(']
                                     and:[self character:')']],
                          [self parse:[self surround:[self symbolicExpression]
                                                with:[self character:'[']
                                                 and:[self character:']']]
                                using:[self constructMessageSend]]]](sequence);
        
    };
}
#pragma mark - Constructors
+ (SNSymbol *(^)(NSArray *))constructSymbol
{
    return ^(NSArray *sequence){
        return [SNSymbol symbolWithName:[self constructString](sequence)];
    };
}
+ (NSNumber *(^)(NSArray *))constructInteger
{
    return ^(NSArray *sequence){
        return [NSDecimalNumber decimalNumberWithString:[self reStringify:sequence]];
    };
}
+ (NSNumber *(^)(NSArray *))constructNumber
{
    return ^(NSArray *sequence){
        NSString *decimalString = [[self reStringify:sequence] componentsJoinedByString:@"."];
        return [NSDecimalNumber decimalNumberWithString:decimalString];
    };
}
+ (NSString *(^)(NSArray *))constructString
{
    return ^(NSArray *sequence){
        return (NSString *)[self reStringify:sequence];
    };
}
+ (NSArray *(^)(NSArray *))constructMessageSend
{
    return ^(NSArray *sequence){
        NSArray *fixed = [self reStringify:sequence];
        id object = fixed[0];
        NSMutableString *message = [NSMutableString string];
        NSMutableArray *arguments = [NSMutableArray array];
        for (NSUInteger i=1; i<[fixed count]; i++) {
            if (i % 2 == 0) {
                [arguments addObject:fixed[i]];
            } else {
                [message appendString:[fixed[i] name]];
            }
        }
        NSArray *result = [@[[SNSymbol symbolWithName:@"@"], object, [SNSymbol symbolWithName:message]] arrayByAddingObjectsFromArray:arguments];
        return result;
    };
}
@end