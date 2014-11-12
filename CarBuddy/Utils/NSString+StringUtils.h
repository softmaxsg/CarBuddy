//
//  NSString+StringUtils.h
//
//  Copyright 2011 Vitaly Chupryk. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
extern NSString * const NSStringEmpty;

@interface NSString (StringUtils)

+ (NSString *)empty;

+ (BOOL)isNullOrEmpty:(NSString *)string;
+ (BOOL)isNullOrWhitespace:(NSString *)string;

- (BOOL)isCaseInsensitiveEqualToString:(NSString *)string;;

@end
#pragma clang diagnostic pop
