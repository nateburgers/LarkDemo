//
//  SNExt.h
//  Snark
//
//  Created by Nathan Burgers on 9/20/13.
//  Copyright (c) 2013 Nathan Burgers. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEBUG 1

@protocol Sequence <NSObject>
- (id) head;
- (id) tail;
@end

typedef NSArray *(^ParserCombinator)(NSArray *sequence);
typedef ParserCombinator (^ParserGenerator)(id previousResult);
typedef id (^TransformBlock)(id x);
typedef id (^ConcatenateBlock)(id x, id y);

@interface SNParseResult : NSObject
@property (readonly) id result;
@property (readonly) NSArray *remainder;
+ (instancetype) result:(id)result andRemainder:(NSArray *)remainder;
- (id) initWithResult:(id)result andRemainder:(NSArray *)remainder;
@end

@interface SNSymbol : NSObject
@property (readonly) NSString *name;
+ (instancetype) symbolWithName:(NSString *)name;
- (id) initWithName:(NSString *)name;
@end

@interface SNExt : NSObject
#pragma mark - Data Structuring And Utilities
+ (NSArray *)stringToArray:(NSString *)string;
+ (id)reStringify:(NSArray *)array;
+ (id) destruct:(NSArray *)array withBlock:(id(^)(id head, NSArray *tail))block;
+ (NSArray *(^)(id)) wrap;
+ (NSArray *(^)(NSArray *)) cons;
+ (id) fold:(NSArray *)array withBlock:(ConcatenateBlock)block;
#pragma mark - Monad Implementation
+ (ParserCombinator) unit:(id)unit;
+ (ParserCombinator) zero;
+ (ParserCombinator) bind:(ParserCombinator)f with:(ParserGenerator)g;
+ (ParserCombinator) item;
+ (ParserCombinator) parse:(ParserCombinator)f using:(TransformBlock)t;
#pragma mark - Parser Generators
+ (ParserCombinator) or:(ParserCombinator)f with:(ParserCombinator)g;
+ (ParserCombinator) or:(NSArray *)combinators;
+ (ParserCombinator) and:(ParserCombinator)f with:(ParserCombinator)g;
+ (ParserCombinator) and:(NSArray *)combinators;
+ (ParserCombinator) many:(ParserCombinator)f;
+ (ParserCombinator) use:(ParserCombinator)f ignore:(ParserCombinator)g;
+ (ParserCombinator) use:(ParserCombinator)f ignoreAny:(ParserCombinator)g;
+ (ParserCombinator) ignore:(ParserCombinator)f use:(ParserCombinator)g;
+ (ParserCombinator) ignoreAny:(ParserCombinator)f use:(ParserCombinator)g;
+ (ParserCombinator) sat:(BOOL(^)(id element))predicate;
#pragma mark - Higher Order Generators
+ (ParserCombinator) separate:(ParserCombinator)f by:(ParserCombinator)g;
+ (ParserCombinator) character:(unichar)character;
+ (ParserCombinator) characterInSet:(NSCharacterSet *)set;
#pragma mark - Parsers
+ (ParserCombinator) anychar;
+ (ParserCombinator) letter;
+ (ParserCombinator) digit;
+ (ParserCombinator) dot;
+ (ParserCombinator) quote;
+ (ParserCombinator) whitespace;
#pragma mark - Multi Character Parsers
+ (ParserCombinator) word;
+ (ParserCombinator) identifier;
+ (ParserCombinator) integer;
+ (ParserCombinator) decimal;
+ (ParserCombinator) string;
#pragma mark - Built In Grammars
+ (ParserCombinator) surround:(ParserCombinator)f with:(ParserCombinator)g and:(ParserCombinator)h;
+ (ParserCombinator) symbolicExpression;
#pragma mark - Constructors
+ (SNSymbol *(^)(NSArray *))constructSymbol;
+ (NSNumber *(^)(NSArray *))constructInteger;
+ (NSNumber *(^)(NSArray *))constructNumber;
+ (NSString *(^)(NSArray *))constructString;
+ (NSArray *(^)(NSArray *))constructMessageSend;
@end
